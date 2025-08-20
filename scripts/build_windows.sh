#!/bin/bash

# Windows Build Script for Cherry Note
# This script builds the Windows desktop application

set -e

echo "🍒 Building Cherry Note for Windows..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Check if running on Windows or WSL
if [[ "$OSTYPE" != "msys" && "$OSTYPE" != "win32" && ! -f /proc/version || ! grep -q Microsoft /proc/version 2>/dev/null ]]; then
    print_warning "This script is designed for Windows or WSL environment."
fi

# Clean previous builds
print_status "Cleaning previous builds..."
flutter clean
flutter pub get

# Generate code if needed
print_status "Generating code..."
flutter packages pub run build_runner build --delete-conflicting-outputs

# Build type (default: release)
BUILD_TYPE=${1:-release}

print_status "Building Windows $BUILD_TYPE..."

case $BUILD_TYPE in
    "debug")
        flutter build windows --debug
        ;;
    "profile")
        flutter build windows --profile
        ;;
    "release")
        flutter build windows --release
        ;;
    *)
        print_error "Invalid build type: $BUILD_TYPE. Use debug, profile, or release."
        exit 1
        ;;
esac

print_status "✅ Windows build completed!"

# Show output location
echo ""
echo "📦 Build output:"
echo "  Executable: build/windows/runner/$BUILD_TYPE/CherryNote.exe"

# Show file size
if [ -f "build/windows/runner/$BUILD_TYPE/CherryNote.exe" ]; then
    size=$(du -h "build/windows/runner/$BUILD_TYPE/CherryNote.exe" | cut -f1)
    echo "  Size: $size"
fi

# Create installer package (if NSIS is available)
if command -v makensis &> /dev/null; then
    print_status "Creating Windows installer..."
    # Note: This would require an NSIS script
    print_warning "NSIS installer script not implemented yet."
else
    print_warning "NSIS not found. Skipping installer creation."
    print_warning "Install NSIS to create Windows installers automatically."
fi