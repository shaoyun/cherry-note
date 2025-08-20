#!/bin/bash

# Android Build Script for Cherry Note
# This script builds the Android APK for different flavors and build types

set -e

echo "🍒 Building Cherry Note for Android..."

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

# Check if key.properties exists
if [ ! -f "android/key.properties" ]; then
    print_warning "key.properties not found. Using debug signing."
    print_warning "For release builds, copy android/key.properties.example to android/key.properties and configure it."
fi

# Clean previous builds
print_status "Cleaning previous builds..."
flutter clean
flutter pub get

# Generate code if needed
print_status "Generating code..."
flutter packages pub run build_runner build --delete-conflicting-outputs

# Build flavor (default: production)
FLAVOR=${1:-production}
BUILD_TYPE=${2:-release}

print_status "Building Android $BUILD_TYPE for $FLAVOR flavor..."

case $BUILD_TYPE in
    "debug")
        flutter build apk --debug --flavor $FLAVOR
        ;;
    "profile")
        flutter build apk --profile --flavor $FLAVOR
        ;;
    "release")
        flutter build apk --release --flavor $FLAVOR
        ;;
    *)
        print_error "Invalid build type: $BUILD_TYPE. Use debug, profile, or release."
        exit 1
        ;;
esac

# Build App Bundle for Play Store
if [ "$BUILD_TYPE" = "release" ]; then
    print_status "Building Android App Bundle for Play Store..."
    flutter build appbundle --release --flavor $FLAVOR
fi

print_status "✅ Android build completed!"

# Show output locations
echo ""
echo "📦 Build outputs:"
if [ "$BUILD_TYPE" = "release" ]; then
    echo "  APK: build/app/outputs/flutter-apk/app-$FLAVOR-release.apk"
    echo "  AAB: build/app/outputs/bundle/${FLAVOR}Release/app-$FLAVOR-release.aab"
else
    echo "  APK: build/app/outputs/flutter-apk/app-$FLAVOR-$BUILD_TYPE.apk"
fi

# Show file sizes
echo ""
echo "📊 File sizes:"
find build/app/outputs -name "*.apk" -o -name "*.aab" | while read file; do
    size=$(du -h "$file" | cut -f1)
    echo "  $(basename "$file"): $size"
done