#!/bin/bash

# Expense Tracker Flutter App Setup Script

echo "🚀 Setting up Expense Tracker Flutter App..."

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed. Please install Flutter first:"
    echo "   Visit: https://docs.flutter.dev/get-started/install"
    echo "   Or run: sudo snap install flutter --classic"
    exit 1
fi

# Check Flutter doctor
echo "🔍 Checking Flutter installation..."
flutter doctor

# Get dependencies
echo "📦 Getting Flutter dependencies..."
flutter pub get

# Check for any issues
echo "🔧 Running Flutter analyze..."
flutter analyze

# Clean and get dependencies again
echo "🧹 Cleaning project..."
flutter clean
flutter pub get

echo "✅ Setup complete!"
echo ""
echo "📱 To run the app:"
echo "   flutter run"
echo ""
echo "🔨 To build the app:"
echo "   flutter build apk (for Android)"
echo "   flutter build ios (for iOS)"
echo ""
echo "🧪 To run tests:"
echo "   flutter test"
