from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    # Database
    database_url: str
    
    # JWT
    jwt_secret_key: str
    jwt_algorithm: str = "HS256"
    jwt_access_token_expire_minutes: int = 30
    jwt_refresh_token_expire_days: int = 7
    
    # App
    app_name: str = "Expense Tracker API"
    app_version: str = "1.0.0"
    debug: bool = False
    
    # File Storage
    storage_type: str = "local"  # 'local' or 's3'
    upload_dir: str = "storage/uploads"
    max_file_size: int = 5 * 1024 * 1024  # 5MB
    base_url: str = "http://localhost:8000"
    
    # S3 Configuration (for S3-compatible storage)
    s3_bucket_name: str = ""
    s3_region: str = "us-east-1"
    s3_access_key_id: str = ""
    s3_secret_access_key: str = ""
    s3_endpoint_url: str = ""  # For S3-compatible services like MinIO
    
    # Image Processing
    create_thumbnails: bool = True
    compress_images: bool = True
    image_quality: int = 85

    class Config:
        env_file = ".env"


@lru_cache()
def get_settings():
    return Settings()
