#!/usr/bin/env python3
import sys
import os
sys.path.insert(0, '/workspaces/flutter-expense-tracker/backend')

try:
    from app import app
    print("✅ FastAPI app imported successfully")
    
    # Test if we can access the app
    print(f"✅ App title: {app.title}")
    print(f"✅ App version: {app.version}")
    
    print("\n📋 Available routes:")
    for route in app.routes:
        if hasattr(route, 'path'):
            print(f"  {route.path}")
    
    print("\n🎉 Backend setup completed successfully!")
    
except Exception as e:
    print(f"❌ Error: {e}")
    sys.exit(1)
