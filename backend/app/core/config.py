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

    class Config:
        env_file = ".env"


@lru_cache()
def get_settings():
    return Settings()
