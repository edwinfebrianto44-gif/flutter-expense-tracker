from fastapi import FastAPI
from dotenv import load_dotenv
import os

# Load environment variables
load_dotenv()

from app import app

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True
    )
