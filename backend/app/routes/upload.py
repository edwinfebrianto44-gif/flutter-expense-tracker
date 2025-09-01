"""
File upload endpoints
"""

from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session
from typing import List, Optional
import os
from pathlib import Path

from app.core.deps import get_db, get_current_user
from app.core.file_storage import file_upload_service
from app.crud.transaction import transaction_crud
from app.models.user import User
from app.core.response import success_response, error_response
from app.core.config import get_settings

settings = get_settings()
router = APIRouter()


@router.post("/transactions/{transaction_id}/upload")
async def upload_transaction_receipt(
    transaction_id: int,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Upload receipt/proof for a transaction
    
    - **transaction_id**: ID of the transaction
    - **file**: Image file (PNG, JPG, JPEG, GIF, WEBP)
    - **Returns**: Upload details with file URL and thumbnail URL
    """
    
    # Get transaction and verify ownership
    transaction = transaction_crud.get_by_id(db, transaction_id)
    if not transaction:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=error_response("Transaction not found")
        )
    
    # Check if user owns this transaction or is admin
    if transaction.user_id != current_user.id and current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=error_response("Not authorized to upload files for this transaction")
        )
    
    try:
        # Upload file
        upload_result = await file_upload_service.upload_transaction_receipt(
            file, current_user.id, transaction_id
        )
        
        # Update transaction with attachment info
        transaction_data = {
            "attachment_url": upload_result["file_url"],
            "attachment_filename": upload_result["original_filename"],
            "attachment_size": upload_result["file_size"]
        }
        
        updated_transaction = transaction_crud.update(
            db, 
            db_obj=transaction, 
            obj_in=transaction_data
        )
        
        return success_response(
            message="File uploaded successfully",
            data={
                "transaction_id": transaction_id,
                "file_url": upload_result["file_url"],
                "thumbnail_url": upload_result.get("thumbnail_url"),
                "filename": upload_result["filename"],
                "original_filename": upload_result["original_filename"],
                "file_size": upload_result["file_size"],
                "content_type": upload_result["content_type"]
            }
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=error_response(f"Upload failed: {str(e)}")
        )


@router.delete("/transactions/{transaction_id}/upload")
async def delete_transaction_receipt(
    transaction_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Delete receipt/proof for a transaction
    
    - **transaction_id**: ID of the transaction
    - **Returns**: Deletion status
    """
    
    # Get transaction and verify ownership
    transaction = transaction_crud.get_by_id(db, transaction_id)
    if not transaction:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=error_response("Transaction not found")
        )
    
    # Check if user owns this transaction or is admin
    if transaction.user_id != current_user.id and current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=error_response("Not authorized to delete files for this transaction")
        )
    
    # Check if transaction has an attachment
    if not transaction.attachment_url:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=error_response("Transaction has no attachment")
        )
    
    try:
        # Extract filename from URL or use stored filename
        filename = None
        if transaction.attachment_filename:
            filename = transaction.attachment_filename
        elif transaction.attachment_url:
            # Extract filename from URL
            url_path = transaction.attachment_url.split('/')[-1]
            filename = url_path
        
        if filename:
            # Delete file from storage
            deleted = await file_upload_service.delete_transaction_receipt(
                filename, current_user.id
            )
            
            if deleted:
                # Update transaction to remove attachment info
                transaction_data = {
                    "attachment_url": None,
                    "attachment_filename": None,
                    "attachment_size": None
                }
                
                transaction_crud.update(
                    db, 
                    db_obj=transaction, 
                    obj_in=transaction_data
                )
                
                return success_response(
                    message="File deleted successfully",
                    data={"transaction_id": transaction_id}
                )
            else:
                return error_response("Failed to delete file from storage")
        else:
            return error_response("Could not determine filename to delete")
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=error_response(f"Delete failed: {str(e)}")
        )


@router.get("/storage/{subfolder}/{filename}")
async def serve_uploaded_file(
    subfolder: str,
    filename: str,
    current_user: User = Depends(get_current_user)
):
    """
    Serve uploaded files (for local storage only)
    
    - **subfolder**: Subfolder name (transactions, thumbnails)
    - **filename**: Filename to serve
    - **Returns**: File content
    """
    
    # Only works with local storage
    if settings.storage_type != "local":
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=error_response("File serving not available for this storage type")
        )
    
    # Validate subfolder
    allowed_subfolders = ["transactions", "thumbnails"]
    if subfolder not in allowed_subfolders:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=error_response("Invalid subfolder")
        )
    
    # Construct file path
    file_path = Path(settings.upload_dir) / subfolder / filename
    
    # Check if file exists
    if not file_path.exists() or not file_path.is_file():
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=error_response("File not found")
        )
    
    # Security check: ensure file is within upload directory
    try:
        file_path.resolve().relative_to(Path(settings.upload_dir).resolve())
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=error_response("Access denied")
        )
    
    # For additional security, you might want to check if the user has access to this file
    # This would require storing file ownership in the database
    
    # Determine media type
    media_type = "application/octet-stream"
    if filename.lower().endswith(('.jpg', '.jpeg')):
        media_type = "image/jpeg"
    elif filename.lower().endswith('.png'):
        media_type = "image/png"
    elif filename.lower().endswith('.gif'):
        media_type = "image/gif"
    elif filename.lower().endswith('.webp'):
        media_type = "image/webp"
    
    return FileResponse(
        path=file_path,
        media_type=media_type,
        filename=filename
    )


@router.get("/transactions/{transaction_id}/attachment")
async def get_transaction_attachment_info(
    transaction_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get attachment information for a transaction
    
    - **transaction_id**: ID of the transaction
    - **Returns**: Attachment details
    """
    
    # Get transaction and verify ownership
    transaction = transaction_crud.get_by_id(db, transaction_id)
    if not transaction:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=error_response("Transaction not found")
        )
    
    # Check if user owns this transaction or is admin
    if transaction.user_id != current_user.id and current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=error_response("Not authorized to view this transaction")
        )
    
    # Return attachment info
    attachment_data = {
        "transaction_id": transaction_id,
        "has_attachment": bool(transaction.attachment_url),
        "attachment_url": transaction.attachment_url,
        "attachment_filename": transaction.attachment_filename,
        "attachment_size": transaction.attachment_size,
    }
    
    # Generate thumbnail URL for local storage
    if (transaction.attachment_url and 
        settings.storage_type == "local" and 
        transaction.attachment_filename):
        
        thumbnail_filename = f"thumb_{transaction.attachment_filename}"
        thumbnail_path = Path(settings.upload_dir) / "thumbnails" / thumbnail_filename
        
        if thumbnail_path.exists():
            attachment_data["thumbnail_url"] = f"{settings.base_url}/storage/thumbnails/{thumbnail_filename}"
    
    return success_response(
        message="Attachment info retrieved",
        data=attachment_data
    )


@router.post("/upload/test")
async def test_upload(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user)
):
    """
    Test file upload functionality
    
    - **file**: Test file to upload
    - **Returns**: Upload test results
    """
    
    try:
        # Test validation
        validation_result = file_upload_service.validator.validate_file(file)
        
        if not validation_result['valid']:
            return {
                "test": "validation",
                "success": False,
                "errors": validation_result['errors'],
                "file_info": {
                    "filename": file.filename,
                    "content_type": file.content_type,
                    "size": file.size
                }
            }
        
        # Test upload (but don't save to transaction)
        upload_result = await file_upload_service.upload_transaction_receipt(
            file, current_user.id, 999999  # Use dummy transaction ID
        )
        
        return {
            "test": "upload",
            "success": upload_result["success"],
            "upload_result": upload_result,
            "validation_result": validation_result
        }
        
    except Exception as e:
        return {
            "test": "upload",
            "success": False,
            "error": str(e),
            "file_info": {
                "filename": file.filename,
                "content_type": file.content_type,
                "size": file.size
            }
        }
