# File Upload Feature - Phase 7

## Overview

This phase adds comprehensive file upload functionality for transaction receipts and proofs, supporting both local storage and S3-compatible cloud storage.

## Features

### ✅ File Upload System
- **Receipt/Proof Upload**: Attach images to transactions as proof
- **Multiple Storage Options**: Local filesystem or S3-compatible storage
- **Image Processing**: Automatic thumbnail generation and compression
- **File Validation**: Size limits, format validation, security checks
- **Secure Access**: User-based file access control

### ✅ Supported File Types
- **Images**: JPG, JPEG, PNG, GIF, WEBP
- **Size Limit**: Configurable (default: 5MB)
- **Processing**: Auto-rotation, compression, thumbnail generation

### ✅ Storage Options

#### Local Storage
- Files stored in `storage/uploads/` directory
- Automatic thumbnail generation in `storage/thumbnails/`
- Direct file serving through FastAPI static files
- Perfect for development and small deployments

#### S3-Compatible Storage
- AWS S3 support
- MinIO support (self-hosted S3-compatible)
- Other S3-compatible services
- Metadata storage for file tracking

## API Endpoints

### Upload Receipt
```http
POST /api/v1/transactions/{transaction_id}/upload
Content-Type: multipart/form-data

file: [binary file data]
```

**Response:**
```json
{
  "data": {
    "transaction_id": 123,
    "file_url": "http://localhost:8000/storage/transactions/user_1_20240115_abc123.jpg",
    "thumbnail_url": "http://localhost:8000/storage/thumbnails/thumb_user_1_20240115_abc123.jpg",
    "filename": "user_1_20240115_abc123.jpg",
    "original_filename": "receipt.jpg",
    "file_size": 1048576,
    "content_type": "image/jpeg"
  },
  "message": "File uploaded successfully"
}
```

### Get Attachment Info
```http
GET /api/v1/transactions/{transaction_id}/attachment
```

**Response:**
```json
{
  "data": {
    "transaction_id": 123,
    "has_attachment": true,
    "attachment_url": "http://localhost:8000/storage/transactions/user_1_20240115_abc123.jpg",
    "attachment_filename": "receipt.jpg",
    "attachment_size": 1048576,
    "thumbnail_url": "http://localhost:8000/storage/thumbnails/thumb_user_1_20240115_abc123.jpg"
  },
  "message": "Attachment info retrieved"
}
```

### Delete Attachment
```http
DELETE /api/v1/transactions/{transaction_id}/upload
```

### Serve Files (Local Storage Only)
```http
GET /api/v1/storage/{subfolder}/{filename}
```

### Test Upload
```http
POST /api/v1/upload/test
Content-Type: multipart/form-data

file: [binary file data]
```

## Configuration

### Environment Variables

```bash
# File Storage Configuration
STORAGE_TYPE=local                    # 'local' or 's3'
UPLOAD_DIR=storage/uploads           # Local storage directory
BASE_URL=http://localhost:8000       # Base URL for file serving
MAX_FILE_SIZE=5242880               # Max file size (5MB)

# S3 Configuration
S3_BUCKET_NAME=your-bucket-name
S3_REGION=us-east-1
S3_ACCESS_KEY_ID=your-access-key
S3_SECRET_ACCESS_KEY=your-secret-key
S3_ENDPOINT_URL=                    # For S3-compatible services

# Image Processing
CREATE_THUMBNAILS=True
COMPRESS_IMAGES=True
IMAGE_QUALITY=85
```

## Database Changes

### New Transaction Fields
- `attachment_url`: URL of uploaded file
- `attachment_filename`: Original filename
- `attachment_size`: File size in bytes
- `notes`: Additional transaction notes
- `type`: Transaction type classification
- `updated_at`: Last update timestamp

### Migration
```bash
# Apply migration
alembic upgrade head
```

## Security Features

### File Validation
- **Extension Validation**: Only allowed image formats
- **MIME Type Validation**: Content-type verification
- **Size Limits**: Configurable maximum file size
- **Filename Security**: Dangerous character filtering
- **Path Traversal Protection**: Secure file path handling

### Access Control
- **User Ownership**: Users can only access their own files
- **Admin Access**: Admins can manage all files
- **Authentication Required**: All endpoints require valid JWT

### File Storage Security
- **Unique Filenames**: UUID-based naming prevents conflicts
- **User Segregation**: Files organized by user ID
- **Secure Serving**: Path validation for local file serving

## File Processing

### Image Processing Pipeline
1. **Upload Validation**: Check file type, size, security
2. **Image Processing**: Auto-rotation, format conversion
3. **Thumbnail Generation**: Create compressed thumbnails
4. **Compression**: Optimize file size while maintaining quality
5. **Storage**: Save to configured storage backend
6. **Database Update**: Store file metadata

### Thumbnail Generation
- **Size**: 300x300 pixels (configurable)
- **Format**: JPEG for compatibility
- **Quality**: Configurable compression
- **Auto-rotation**: EXIF data processing

## Usage Examples

### Upload with cURL
```bash
curl -X POST \
  "http://localhost:8000/api/v1/transactions/123/upload" \
  -H "Authorization: Bearer your-jwt-token" \
  -F "file=@receipt.jpg"
```

### Upload with Python requests
```python
import requests

url = "http://localhost:8000/api/v1/transactions/123/upload"
headers = {"Authorization": "Bearer your-jwt-token"}
files = {"file": open("receipt.jpg", "rb")}

response = requests.post(url, headers=headers, files=files)
print(response.json())
```

### Upload with JavaScript (Frontend)
```javascript
const formData = new FormData();
formData.append('file', fileInput.files[0]);

fetch('/api/v1/transactions/123/upload', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`
  },
  body: formData
})
.then(response => response.json())
.then(data => console.log(data));
```

## Storage Setup

### Local Storage Setup
1. **Directory Creation**: Automatically created on startup
2. **Permissions**: Ensure write permissions for upload directory
3. **Static Files**: Served through FastAPI StaticFiles

### S3 Storage Setup
1. **AWS S3**: Standard AWS S3 bucket
2. **MinIO**: Self-hosted S3-compatible storage
3. **Credentials**: Configure access keys in environment
4. **Bucket Policy**: Ensure proper bucket permissions

### MinIO Example Setup
```bash
# Start MinIO server
docker run -p 9000:9000 -p 9001:9001 \
  -e MINIO_ROOT_USER=minioadmin \
  -e MINIO_ROOT_PASSWORD=minioadmin \
  minio/minio server /data --console-address ":9001"

# Environment configuration
S3_ENDPOINT_URL=http://localhost:9000
S3_BUCKET_NAME=expense-tracker
S3_ACCESS_KEY_ID=minioadmin
S3_SECRET_ACCESS_KEY=minioadmin
```

## Error Handling

### Common Errors
- **413**: File too large
- **400**: Invalid file format
- **404**: Transaction not found
- **403**: Access denied
- **500**: Storage error

### Error Response Format
```json
{
  "message": "File validation failed",
  "detail": {
    "success": false,
    "message": "File validation failed",
    "errors": [
      "File size 10485760 exceeds maximum allowed size 5242880",
      "File extension .pdf not allowed. Allowed: .jpg, .jpeg, .png, .gif, .webp"
    ]
  }
}
```

## Performance Considerations

### File Size Optimization
- **Image Compression**: Reduces storage and bandwidth
- **Thumbnail Generation**: Fast loading for previews
- **Format Conversion**: JPEG for optimal compression

### Async Operations
- **Non-blocking Uploads**: Async file operations
- **Background Processing**: Image processing doesn't block API
- **Streaming**: Efficient file handling

### Caching
- **Static File Serving**: Browser caching for local files
- **CDN Support**: S3 files can be served through CDN
- **Thumbnail Caching**: Generated thumbnails are cached

## Monitoring and Logging

### File Upload Metrics
- Upload success/failure rates
- File size distributions
- Storage usage tracking
- Processing time monitoring

### Security Monitoring
- Failed upload attempts
- Invalid file type attempts
- Unauthorized access attempts
- Storage quota violations

## Testing

### Test Upload Endpoint
Use the `/api/v1/upload/test` endpoint to test file upload functionality without creating actual transactions.

### Test File Examples
```bash
# Test valid image
curl -X POST "http://localhost:8000/api/v1/upload/test" \
  -H "Authorization: Bearer token" \
  -F "file=@test-image.jpg"

# Test invalid file
curl -X POST "http://localhost:8000/api/v1/upload/test" \
  -H "Authorization: Bearer token" \
  -F "file=@document.pdf"
```

## Next Steps

This implementation provides a solid foundation for file uploads. Future enhancements could include:

1. **Multiple File Upload**: Support multiple receipts per transaction
2. **OCR Integration**: Extract text from receipt images
3. **Advanced Image Processing**: Automatic cropping, enhancement
4. **File Versioning**: Keep multiple versions of files
5. **Bulk Operations**: Batch upload/download capabilities
6. **Analytics**: File usage and storage analytics

## Flutter Integration (Phase 8)

The Flutter app will need updates to support file upload:
1. **Image Picker**: Select images from camera/gallery
2. **Upload Progress**: Show upload progress indicators
3. **Thumbnail Display**: Show thumbnails in transaction list
4. **Full Image View**: Tap to view full-size images
5. **Delete Functionality**: Remove attachments from transactions
