#!/bin/bash

# macOS Build Script for Cherry Note
# This script builds the macOS desktop application

set -e

echo "🍒 Building Cherry Note for macOS..."

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

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This script must be run on macOS."
    exit 1
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

print_status "Building macOS $BUILD_TYPE..."

case $BUILD_TYPE in
    "debug")
        flutter build macos --debug
        ;;
    "profile")
        flutter build macos --profile
        ;;
    "release")
        flutter build macos --release
        ;;
    *)
        print_error "Invalid build type: $BUILD_TYPE. Use debug, profile, or release."
        exit 1
        ;;
esac

print_status "✅ macOS build completed!"

# Show output location
echo ""
echo "📦 Build output:"
echo "  App Bundle: build/macos/Build/Products/$BUILD_TYPE/Cherry Note.app"

# Show app bundle size
if [ -d "build/macos/Build/Products/$BUILD_TYPE/Cherry Note.app" ]; then
    size=$(du -sh "build/macos/Build/Products/$BUILD_TYPE/Cherry Note.app" | cut -f1)
    echo "  Size: $size"
fi

# Create DMG (if create-dmg is available)
if command -v create-dmg &> /dev/null; then
    print_status "Creating DMG installer..."
    
    DMG_NAME="CherryNote-v1.0.0-macOS.dmg"
    
    create-dmg \
        --volname "Cherry Note" \
        --volicon "assets/icons/app_icon.icns" \
        --window-pos 200 120 \
        --window-size 600 300 \
        --icon-size 100 \
        --icon "Cherry Note.app" 175 120 \
        --hide-extension "Cherry Note.app" \
        --app-drop-link 425 120 \
        "build/$DMG_NAME" \
        "build/macos/Build/Products/$BUILD_TYPE/"
    
    echo "  DMG: build/$DMG_NAME"
else
    print_warning "create-dmg not found. Skipping DMG creation."
    print_warning "Install create-dmg with: brew install create-dmg"
fi

# Code signing (if certificates are available)
if [ -n "$APPLE_DEVELOPER_ID" ]; then
    print_status "Code signing application..."
    codesign --force --deep --sign "$APPLE_DEVELOPER_ID" "build/macos/Build/Products/$BUILD_TYPE/Cherry Note.app"
    print_status "✅ Code signing completed!"
else
    print_warning "APPLE_DEVELOPER_ID not set. Skipping code signing."
    print_warning "Set APPLE_DEVELOPER_ID environment variable for code signing."
fi