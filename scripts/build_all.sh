#!/bin/bash

# Universal Build Script for Cherry Note
# This script builds the application for all supported platforms

set -e

echo "🍒 Building Cherry Note for all platforms..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}[BUILD]${NC} $1"
}

# Build type (default: release)
BUILD_TYPE=${1:-release}

print_status "Starting multi-platform build process..."
print_status "Build type: $BUILD_TYPE"

# Create build output directory
mkdir -p build/releases

# Build Android (if Android SDK is available)
if command -v flutter &> /dev/null && flutter doctor | grep -q "Android toolchain"; then
    print_header "Building for Android..."
    ./scripts/build_android.sh production $BUILD_TYPE
    
    # Copy outputs to releases directory
    if [ -f "build/app/outputs/flutter-apk/app-production-$BUILD_TYPE.apk" ]; then
        cp "build/app/outputs/flutter-apk/app-production-$BUILD_TYPE.apk" "build/releases/CherryNote-v1.0.0-android.apk"
    fi
    
    if [ -f "build/app/outputs/bundle/productionRelease/app-production-release.aab" ]; then
        cp "build/app/outputs/bundle/productionRelease/app-production-release.aab" "build/releases/CherryNote-v1.0.0-android.aab"
    fi
else
    print_warning "Android SDK not available. Skipping Android build."
fi

# Build Windows (if on Windows or WSL)
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" || (-f /proc/version && grep -q Microsoft /proc/version 2>/dev/null) ]]; then
    print_header "Building for Windows..."
    ./scripts/build_windows.sh $BUILD_TYPE
    
    # Copy output to releases directory
    if [ -f "build/windows/runner/$BUILD_TYPE/CherryNote.exe" ]; then
        mkdir -p "build/releases/CherryNote-Windows"
        cp -r "build/windows/runner/$BUILD_TYPE/"* "build/releases/CherryNote-Windows/"
        
        # Create ZIP archive
        cd build/releases
        zip -r "CherryNote-v1.0.0-windows.zip" "CherryNote-Windows/"
        cd ../..
    fi
else
    print_warning "Not on Windows. Skipping Windows build."
fi

# Build macOS (if on macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    print_header "Building for macOS..."
    ./scripts/build_macos.sh $BUILD_TYPE
    
    # Copy output to releases directory
    if [ -d "build/macos/Build/Products/$BUILD_TYPE/Cherry Note.app" ]; then
        cp -r "build/macos/Build/Products/$BUILD_TYPE/Cherry Note.app" "build/releases/"
        
        # Create ZIP archive
        cd build/releases
        zip -r "CherryNote-v1.0.0-macos.zip" "Cherry Note.app"
        cd ../..
    fi
else
    print_warning "Not on macOS. Skipping macOS build."
fi

# Build Web (always available)
print_header "Building for Web..."
./scripts/build_web.sh $BUILD_TYPE

# Copy web output to releases directory
if [ -d "build/web" ]; then
    mkdir -p "build/releases/CherryNote-Web"
    cp -r build/web/* "build/releases/CherryNote-Web/"
    
    # Create ZIP archive for web deployment
    cd build/releases
    zip -r "CherryNote-v1.0.0-web.zip" "CherryNote-Web/"
    cd ../..
fi

print_status "✅ Multi-platform build completed!"

# Show all build outputs
echo ""
echo "📦 All build outputs:"
find build/releases -type f \( -name "*.apk" -o -name "*.aab" -o -name "*.zip" -o -name "*.dmg" \) | while read file; do
    size=$(du -h "$file" | cut -f1)
    echo "  $(basename "$file"): $size"
done

# Show web deployment info
if [ -d "build/releases/CherryNote-Web" ]; then
    echo ""
    echo "🌐 Web deployment ready:"
    echo "  Directory: build/releases/CherryNote-Web/"
    echo "  Archive: CherryNote-v1.0.0-web.zip"
    echo "  Test locally: cd build/releases/CherryNote-Web && python3 -m http.server 8000"
fi

echo ""
print_status "🎉 Cherry Note is ready for distribution!"