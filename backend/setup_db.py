#!/usr/bin/env python3
"""
Database setup script for Expense Tracker Backend
This script creates the initial migration and applies it to the database.
"""
import os
import sys
import subprocess
from pathlib import Path

# Add the backend directory to Python path
backend_dir = Path(__file__).parent
sys.path.insert(0, str(backend_dir))

def run_command(command, cwd=None):
    """Run a shell command and return the result"""
    print(f"🔧 Running: {command}")
    try:
        result = subprocess.run(
            command, 
            shell=True, 
            check=True, 
            capture_output=True, 
            text=True,
            cwd=cwd or backend_dir
        )
        if result.stdout:
            print(result.stdout)
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ Error running command: {e}")
        if e.stdout:
            print(f"STDOUT: {e.stdout}")
        if e.stderr:
            print(f"STDERR: {e.stderr}")
        return False

def main():
    print("🚀 Setting up Expense Tracker Database...")
    
    # Check if .env file exists
    env_file = backend_dir / ".env"
    if not env_file.exists():
        print("❌ .env file not found. Please create one based on .env.example")
        return False
    
    print("✅ Environment file found")
    
    # Initialize Alembic if not already done
    versions_dir = backend_dir / "migrations" / "versions"
    if not versions_dir.exists():
        print("📁 Creating Alembic versions directory...")
        versions_dir.mkdir(parents=True, exist_ok=True)
    
    # Create initial migration
    print("📝 Creating initial migration...")
    if not run_command("alembic revision --autogenerate -m 'Initial migration'"):
        return False
    
    # Apply migrations
    print("⚡ Applying migrations to database...")
    if not run_command("alembic upgrade head"):
        return False
    
    print("🎉 Database setup completed successfully!")
    print("\n📋 Next steps:")
    print("1. Start the server: python main.py")
    print("2. Visit API docs: http://localhost:8000/docs")
    print("3. Test the endpoints using the API documentation")
    
    return True

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
