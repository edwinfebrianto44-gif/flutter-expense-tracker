"""
File upload and storage management
"""

import os
import uuid
import aiofiles
from typing import Optional, Dict, Any, List
from pathlib import Path
from PIL import Image, ImageOps
import boto3
from botocore.exceptions import ClientError, NoCredentialsError
from fastapi import UploadFile, HTTPException, status
import logging
from datetime import datetime

from app.core.config import get_settings

settings = get_settings()
logger = logging.getLogger(__name__)


class StorageConfig:
    """Storage configuration management"""
    
    def __init__(self):
        self.storage_type = getattr(settings, 'STORAGE_TYPE', 'local')  # 'local' or 's3'
        self.max_file_size = getattr(settings, 'MAX_FILE_SIZE', 5 * 1024 * 1024)  # 5MB
        self.allowed_extensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp']
        self.allowed_mime_types = [
            'image/jpeg', 'image/jpg', 'image/png', 
            'image/gif', 'image/webp'
        ]
        
        # Local storage settings
        self.upload_dir = Path(getattr(settings, 'UPLOAD_DIR', 'storage/uploads'))
        self.base_url = getattr(settings, 'BASE_URL', 'http://localhost:8000')
        
        # S3 settings
        self.s3_bucket = getattr(settings, 'S3_BUCKET_NAME', '')
        self.s3_region = getattr(settings, 'S3_REGION', 'us-east-1')
        self.s3_access_key = getattr(settings, 'S3_ACCESS_KEY_ID', '')
        self.s3_secret_key = getattr(settings, 'S3_SECRET_ACCESS_KEY', '')
        self.s3_endpoint = getattr(settings, 'S3_ENDPOINT_URL', None)  # For S3-compatible services
        
        # Image processing settings
        self.create_thumbnails = getattr(settings, 'CREATE_THUMBNAILS', True)
        self.thumbnail_size = (300, 300)
        self.compress_images = getattr(settings, 'COMPRESS_IMAGES', True)
        self.image_quality = getattr(settings, 'IMAGE_QUALITY', 85)


class FileValidator:
    """File validation utilities"""
    
    def __init__(self, config: StorageConfig):
        self.config = config
    
    def validate_file(self, file: UploadFile) -> Dict[str, Any]:
        """Validate uploaded file"""
        errors = []
        
        # Check file size
        if file.size and file.size > self.config.max_file_size:
            errors.append(f"File size {file.size} exceeds maximum allowed size {self.config.max_file_size}")
        
        # Check file extension
        file_ext = Path(file.filename).suffix.lower()
        if file_ext not in self.config.allowed_extensions:
            errors.append(f"File extension {file_ext} not allowed. Allowed: {', '.join(self.config.allowed_extensions)}")
        
        # Check MIME type
        if file.content_type not in self.config.allowed_mime_types:
            errors.append(f"Content type {file.content_type} not allowed. Allowed: {', '.join(self.config.allowed_mime_types)}")
        
        # Basic filename validation
        if not file.filename or file.filename.strip() == '':
            errors.append("Filename cannot be empty")
        
        # Check for potentially dangerous filenames
        dangerous_chars = ['..', '/', '\\', '<', '>', ':', '"', '|', '?', '*']
        if any(char in file.filename for char in dangerous_chars):
            errors.append("Filename contains invalid characters")
        
        return {
            'valid': len(errors) == 0,
            'errors': errors,
            'file_ext': file_ext,
            'size': file.size,
            'content_type': file.content_type
        }


class ImageProcessor:
    """Image processing utilities"""
    
    def __init__(self, config: StorageConfig):
        self.config = config
    
    async def process_image(self, file_path: Path, original_filename: str) -> Dict[str, Any]:
        """Process uploaded image (resize, compress, create thumbnail)"""
        try:
            # Open and process image
            with Image.open(file_path) as img:
                # Auto-rotate based on EXIF data
                img = ImageOps.exif_transpose(img)
                
                # Convert to RGB if necessary (for JPEG compatibility)
                if img.mode in ('RGBA', 'LA', 'P'):
                    background = Image.new('RGB', img.size, (255, 255, 255))
                    if img.mode == 'P':
                        img = img.convert('RGBA')
                    background.paste(img, mask=img.split()[-1] if img.mode == 'RGBA' else None)
                    img = background
                
                # Create thumbnail if enabled
                thumbnail_path = None
                if self.config.create_thumbnails:
                    thumbnail_path = file_path.parent / f"thumb_{file_path.name}"
                    thumbnail = img.copy()
                    thumbnail.thumbnail(self.config.thumbnail_size, Image.Resampling.LANCZOS)
                    
                    # Save thumbnail
                    if self.config.compress_images:
                        thumbnail.save(
                            thumbnail_path, 
                            format='JPEG', 
                            quality=self.config.image_quality,
                            optimize=True
                        )
                    else:
                        thumbnail.save(thumbnail_path, format='JPEG')
                
                # Compress main image if enabled
                if self.config.compress_images:
                    img.save(
                        file_path, 
                        format='JPEG', 
                        quality=self.config.image_quality,
                        optimize=True
                    )
                
                return {
                    'processed': True,
                    'thumbnail_path': thumbnail_path,
                    'original_size': img.size,
                    'thumbnail_size': self.config.thumbnail_size if thumbnail_path else None
                }
                
        except Exception as e:
            logger.error(f"Error processing image {file_path}: {e}")
            return {
                'processed': False,
                'error': str(e)
            }


class LocalStorage:
    """Local file storage implementation"""
    
    def __init__(self, config: StorageConfig):
        self.config = config
        self.upload_dir = config.upload_dir
        self.base_url = config.base_url
        
        # Create upload directory if it doesn't exist
        self.upload_dir.mkdir(parents=True, exist_ok=True)
        
        # Create subdirectories
        (self.upload_dir / 'transactions').mkdir(exist_ok=True)
        (self.upload_dir / 'thumbnails').mkdir(exist_ok=True)
    
    def generate_filename(self, original_filename: str, user_id: int) -> str:
        """Generate unique filename"""
        file_ext = Path(original_filename).suffix.lower()
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        unique_id = str(uuid.uuid4())[:8]
        return f"user_{user_id}_{timestamp}_{unique_id}{file_ext}"
    
    async def save_file(self, file: UploadFile, user_id: int, subfolder: str = 'transactions') -> Dict[str, Any]:
        """Save file to local storage"""
        try:
            # Generate unique filename
            filename = self.generate_filename(file.filename, user_id)
            file_path = self.upload_dir / subfolder / filename
            
            # Ensure directory exists
            file_path.parent.mkdir(parents=True, exist_ok=True)
            
            # Save file
            async with aiofiles.open(file_path, 'wb') as f:
                content = await file.read()
                await f.write(content)
            
            # Get file size
            file_size = file_path.stat().st_size
            
            # Generate URL
            file_url = f"{self.base_url}/storage/{subfolder}/{filename}"
            
            return {
                'success': True,
                'filename': filename,
                'file_path': str(file_path),
                'file_url': file_url,
                'file_size': file_size,
                'original_filename': file.filename
            }
            
        except Exception as e:
            logger.error(f"Error saving file to local storage: {e}")
            return {
                'success': False,
                'error': str(e)
            }
    
    async def delete_file(self, filename: str, subfolder: str = 'transactions') -> bool:
        """Delete file from local storage"""
        try:
            file_path = self.upload_dir / subfolder / filename
            if file_path.exists():
                file_path.unlink()
                
                # Also delete thumbnail if exists
                thumbnail_path = self.upload_dir / 'thumbnails' / f"thumb_{filename}"
                if thumbnail_path.exists():
                    thumbnail_path.unlink()
                
                return True
            return False
            
        except Exception as e:
            logger.error(f"Error deleting file from local storage: {e}")
            return False
    
    def get_file_url(self, filename: str, subfolder: str = 'transactions') -> str:
        """Get file URL"""
        return f"{self.base_url}/storage/{subfolder}/{filename}"


class S3Storage:
    """S3-compatible storage implementation"""
    
    def __init__(self, config: StorageConfig):
        self.config = config
        self.bucket_name = config.s3_bucket
        
        # Initialize S3 client
        try:
            self.s3_client = boto3.client(
                's3',
                region_name=config.s3_region,
                aws_access_key_id=config.s3_access_key,
                aws_secret_access_key=config.s3_secret_key,
                endpoint_url=config.s3_endpoint
            )
            
            # Test connection
            self.s3_client.head_bucket(Bucket=self.bucket_name)
            self.available = True
            
        except (ClientError, NoCredentialsError) as e:
            logger.error(f"S3 storage not available: {e}")
            self.available = False
    
    def generate_key(self, original_filename: str, user_id: int, subfolder: str = 'transactions') -> str:
        """Generate S3 object key"""
        file_ext = Path(original_filename).suffix.lower()
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        unique_id = str(uuid.uuid4())[:8]
        filename = f"user_{user_id}_{timestamp}_{unique_id}{file_ext}"
        return f"{subfolder}/{filename}"
    
    async def save_file(self, file: UploadFile, user_id: int, subfolder: str = 'transactions') -> Dict[str, Any]:
        """Save file to S3"""
        if not self.available:
            return {'success': False, 'error': 'S3 storage not available'}
        
        try:
            # Generate object key
            object_key = self.generate_key(file.filename, user_id, subfolder)
            
            # Read file content
            content = await file.read()
            
            # Upload to S3
            self.s3_client.put_object(
                Bucket=self.bucket_name,
                Key=object_key,
                Body=content,
                ContentType=file.content_type,
                Metadata={
                    'original-filename': file.filename,
                    'user-id': str(user_id),
                    'uploaded-at': datetime.now().isoformat()
                }
            )
            
            # Generate URL
            file_url = f"https://{self.bucket_name}.s3.{self.config.s3_region}.amazonaws.com/{object_key}"
            if self.config.s3_endpoint:
                file_url = f"{self.config.s3_endpoint}/{self.bucket_name}/{object_key}"
            
            return {
                'success': True,
                'filename': Path(object_key).name,
                'object_key': object_key,
                'file_url': file_url,
                'file_size': len(content),
                'original_filename': file.filename
            }
            
        except Exception as e:
            logger.error(f"Error saving file to S3: {e}")
            return {
                'success': False,
                'error': str(e)
            }
    
    async def delete_file(self, object_key: str) -> bool:
        """Delete file from S3"""
        if not self.available:
            return False
        
        try:
            self.s3_client.delete_object(Bucket=self.bucket_name, Key=object_key)
            return True
            
        except Exception as e:
            logger.error(f"Error deleting file from S3: {e}")
            return False


class FileUploadService:
    """Main file upload service"""
    
    def __init__(self):
        self.config = StorageConfig()
        self.validator = FileValidator(self.config)
        self.image_processor = ImageProcessor(self.config)
        
        # Initialize storage backend
        if self.config.storage_type == 's3':
            self.storage = S3Storage(self.config)
        else:
            self.storage = LocalStorage(self.config)
    
    async def upload_transaction_receipt(self, file: UploadFile, user_id: int, transaction_id: int) -> Dict[str, Any]:
        """Upload transaction receipt/proof"""
        
        # Validate file
        validation_result = self.validator.validate_file(file)
        if not validation_result['valid']:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail={
                    'success': False,
                    'message': 'File validation failed',
                    'errors': validation_result['errors']
                }
            )
        
        try:
            # Save file
            save_result = await self.storage.save_file(file, user_id, 'transactions')
            
            if not save_result['success']:
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail={
                        'success': False,
                        'message': 'Failed to save file',
                        'error': save_result.get('error', 'Unknown error')
                    }
                )
            
            # Process image if it's a local file and image processing is enabled
            thumbnail_url = None
            if (isinstance(self.storage, LocalStorage) and 
                validation_result['content_type'].startswith('image/')):
                
                file_path = Path(save_result['file_path'])
                process_result = await self.image_processor.process_image(
                    file_path, save_result['original_filename']
                )
                
                if process_result.get('thumbnail_path'):
                    thumbnail_filename = Path(process_result['thumbnail_path']).name
                    thumbnail_url = f"{self.config.base_url}/storage/thumbnails/{thumbnail_filename}"
            
            return {
                'success': True,
                'file_url': save_result['file_url'],
                'thumbnail_url': thumbnail_url,
                'filename': save_result['filename'],
                'original_filename': save_result['original_filename'],
                'file_size': save_result['file_size'],
                'content_type': file.content_type
            }
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error uploading transaction receipt: {e}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail={
                    'success': False,
                    'message': 'Upload failed',
                    'error': str(e)
                }
            )
    
    async def delete_transaction_receipt(self, filename: str, user_id: int) -> bool:
        """Delete transaction receipt"""
        try:
            if isinstance(self.storage, S3Storage):
                # For S3, we need the full object key
                object_key = f"transactions/{filename}"
                return await self.storage.delete_file(object_key)
            else:
                # For local storage
                return await self.storage.delete_file(filename, 'transactions')
                
        except Exception as e:
            logger.error(f"Error deleting transaction receipt: {e}")
            return False


# Global service instance
file_upload_service = FileUploadService()
