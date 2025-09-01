#!/usr/bin/env python3
"""
Script to export Postman collection from OpenAPI specification
"""

import json
import requests
from pathlib import Path
import sys
import os

# Add the app directory to Python path
sys.path.append(os.path.join(os.path.dirname(__file__), 'app'))

def get_openapi_spec():
    """Get OpenAPI specification from FastAPI app"""
    try:
        # Import the FastAPI app
        from main import app
        return app.openapi()
    except Exception as e:
        print(f"Error getting OpenAPI spec: {e}")
        return None

def convert_to_postman_collection(openapi_spec):
    """Convert OpenAPI spec to Postman collection format"""
    if not openapi_spec:
        return None
    
    # Basic Postman collection structure
    postman_collection = {
        "info": {
            "name": openapi_spec.get("info", {}).get("title", "Expense Tracker API"),
            "description": openapi_spec.get("info", {}).get("description", ""),
            "version": openapi_spec.get("info", {}).get("version", "1.0.0"),
            "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
        },
        "auth": {
            "type": "bearer",
            "bearer": [
                {
                    "key": "token",
                    "value": "{{jwt_token}}",
                    "type": "string"
                }
            ]
        },
        "variable": [
            {
                "key": "base_url",
                "value": "http://localhost:8000",
                "type": "string"
            },
            {
                "key": "jwt_token",
                "value": "",
                "type": "string"
            }
        ],
        "item": []
    }
    
    # Group endpoints by tags
    groups = {}
    
    # Process each path and method
    for path, methods in openapi_spec.get("paths", {}).items():
        for method, details in methods.items():
            if method.upper() not in ["GET", "POST", "PUT", "DELETE", "PATCH"]:
                continue
                
            # Get the tag (group) for this endpoint
            tags = details.get("tags", ["Default"])
            tag = tags[0] if tags else "Default"
            
            if tag not in groups:
                groups[tag] = {
                    "name": tag.title(),
                    "item": []
                }
            
            # Create Postman request
            request = {
                "name": details.get("summary", f"{method.upper()} {path}"),
                "request": {
                    "method": method.upper(),
                    "header": [
                        {
                            "key": "Content-Type",
                            "value": "application/json"
                        }
                    ],
                    "url": {
                        "raw": "{{base_url}}" + path,
                        "host": ["{{base_url}}"],
                        "path": path.strip("/").split("/") if path != "/" else []
                    },
                    "description": details.get("description", "")
                }
            }
            
            # Add authentication for protected endpoints
            if "security" in details or any("Authorization" in str(resp) for resp in details.get("responses", {}).values()):
                request["request"]["auth"] = {
                    "type": "bearer",
                    "bearer": [
                        {
                            "key": "token",
                            "value": "{{jwt_token}}",
                            "type": "string"
                        }
                    ]
                }
            
            # Add request body for POST/PUT requests
            if method.upper() in ["POST", "PUT", "PATCH"] and "requestBody" in details:
                request_body = details["requestBody"]
                if "application/json" in request_body.get("content", {}):
                    schema = request_body["content"]["application/json"].get("schema", {})
                    example = get_example_from_schema(schema, openapi_spec)
                    
                    request["request"]["body"] = {
                        "mode": "raw",
                        "raw": json.dumps(example, indent=2),
                        "options": {
                            "raw": {
                                "language": "json"
                            }
                        }
                    }
            
            # Add query parameters
            parameters = details.get("parameters", [])
            query_params = [p for p in parameters if p.get("in") == "query"]
            if query_params:
                request["request"]["url"]["query"] = []
                for param in query_params:
                    request["request"]["url"]["query"].append({
                        "key": param["name"],
                        "value": "",
                        "description": param.get("description", ""),
                        "disabled": not param.get("required", False)
                    })
            
            # Add path parameters
            path_params = [p for p in parameters if p.get("in") == "path"]
            if path_params:
                if "variable" not in request["request"]["url"]:
                    request["request"]["url"]["variable"] = []
                for param in path_params:
                    request["request"]["url"]["variable"].append({
                        "key": param["name"],
                        "value": "1",  # Default value
                        "description": param.get("description", "")
                    })
            
            groups[tag]["item"].append(request)
    
    # Convert groups to Postman collection items
    postman_collection["item"] = list(groups.values())
    
    return postman_collection

def get_example_from_schema(schema, openapi_spec):
    """Generate example data from OpenAPI schema"""
    if "$ref" in schema:
        # Resolve reference
        ref_path = schema["$ref"].replace("#/", "").split("/")
        ref_schema = openapi_spec
        for part in ref_path:
            ref_schema = ref_schema.get(part, {})
        return get_example_from_schema(ref_schema, openapi_spec)
    
    schema_type = schema.get("type", "object")
    
    if schema_type == "object":
        example = {}
        properties = schema.get("properties", {})
        for prop_name, prop_schema in properties.items():
            example[prop_name] = get_example_from_schema(prop_schema, openapi_spec)
        return example
    
    elif schema_type == "array":
        items_schema = schema.get("items", {})
        return [get_example_from_schema(items_schema, openapi_spec)]
    
    elif schema_type == "string":
        format_type = schema.get("format")
        if format_type == "email":
            return "user@example.com"
        elif format_type == "date":
            return "2024-01-15"
        elif format_type == "date-time":
            return "2024-01-15T10:30:00Z"
        return schema.get("example", "string")
    
    elif schema_type == "integer":
        return schema.get("example", 1)
    
    elif schema_type == "number":
        return schema.get("example", 1.0)
    
    elif schema_type == "boolean":
        return schema.get("example", True)
    
    return None

def save_postman_collection(collection, filename="expense_tracker_postman_collection.json"):
    """Save Postman collection to file"""
    output_path = Path(__file__).parent / filename
    
    try:
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(collection, f, indent=2, ensure_ascii=False)
        
        print(f"✅ Postman collection exported successfully to: {output_path}")
        return True
    except Exception as e:
        print(f"❌ Error saving Postman collection: {e}")
        return False

def main():
    """Main function to export Postman collection"""
    print("🚀 Exporting Postman collection from OpenAPI specification...")
    
    # Get OpenAPI specification
    openapi_spec = get_openapi_spec()
    if not openapi_spec:
        print("❌ Failed to get OpenAPI specification")
        return False
    
    print("✅ OpenAPI specification retrieved successfully")
    
    # Convert to Postman collection
    postman_collection = convert_to_postman_collection(openapi_spec)
    if not postman_collection:
        print("❌ Failed to convert OpenAPI spec to Postman collection")
        return False
    
    print("✅ OpenAPI spec converted to Postman collection format")
    
    # Save to file
    success = save_postman_collection(postman_collection)
    if success:
        print("\n📋 Collection includes:")
        print("  • All API endpoints with proper grouping")
        print("  • Authentication setup (Bearer token)")
        print("  • Request examples and schemas")
        print("  • Environment variables for base URL and JWT token")
        print("\n📝 To use the collection:")
        print("  1. Import the JSON file into Postman")
        print("  2. Set the 'jwt_token' variable after logging in")
        print("  3. Update 'base_url' if running on different host/port")
        
        return True
    
    return False

if __name__ == "__main__":
    main()
