#!/bin/bash

# Cherry Note Web Build Script
# Usage: ./scripts/build_web.sh [profile|release]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default build mode
BUILD_MODE=${1:-release}

echo -e "${BLUE}🍒 Cherry Note Web Build Script${NC}"
echo -e "${BLUE}================================${NC}"

# Validate build mode
if [[ "$BUILD_MODE" != "profile" && "$BUILD_MODE" != "release" ]]; then
    echo -e "${RED}❌ Invalid build mode: $BUILD_MODE${NC}"
    echo -e "${YELLOW}Usage: $0 [profile|release]${NC}"
    exit 1
fi

echo -e "${BLUE}📋 Build Configuration:${NC}"
echo -e "   Mode: ${GREEN}$BUILD_MODE${NC}"
echo -e "   Platform: ${GREEN}Web${NC}"
echo ""

# Check Flutter installation
echo -e "${BLUE}🔍 Checking Flutter installation...${NC}"
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter is not installed or not in PATH${NC}"
    exit 1
fi

FLUTTER_VERSION=$(flutter --version | head -n 1)
echo -e "${GREEN}✅ $FLUTTER_VERSION${NC}"

# Check if web support is enabled
echo -e "${BLUE}🌐 Checking web support...${NC}"
if ! flutter config | grep -q "enable-web: true"; then
    echo -e "${YELLOW}⚠️  Web support is not enabled. Enabling...${NC}"
    flutter config --enable-web
fi
echo -e "${GREEN}✅ Web support is enabled${NC}"

# Clean previous builds
echo -e "${BLUE}🧹 Cleaning previous builds...${NC}"
flutter clean
echo -e "${GREEN}✅ Clean completed${NC}"

# Get dependencies
echo -e "${BLUE}📦 Getting dependencies...${NC}"
flutter pub get
echo -e "${GREEN}✅ Dependencies updated${NC}"

# Generate code if needed
if [ -f "pubspec.yaml" ] && grep -q "build_runner" pubspec.yaml; then
    echo -e "${BLUE}🔧 Generating code...${NC}"
    flutter packages pub run build_runner build --delete-conflicting-outputs
    echo -e "${GREEN}✅ Code generation completed${NC}"
fi

# Run tests
echo -e "${BLUE}🧪 Running tests...${NC}"
if flutter test --coverage; then
    echo -e "${GREEN}✅ All tests passed${NC}"
else
    echo -e "${YELLOW}⚠️  Some tests failed, but continuing with build...${NC}"
fi

# Build for web
echo -e "${BLUE}🏗️  Building for web ($BUILD_MODE)...${NC}"

BUILD_ARGS=""
if [ "$BUILD_MODE" = "release" ]; then
    BUILD_ARGS="--release"
elif [ "$BUILD_MODE" = "profile" ]; then
    BUILD_ARGS="--profile"
fi

# Additional web-specific optimizations
BUILD_ARGS="$BUILD_ARGS --optimization-level=4"
BUILD_ARGS="$BUILD_ARGS --source-maps"

if flutter build web $BUILD_ARGS; then
    echo -e "${GREEN}✅ Web build completed successfully${NC}"
else
    echo -e "${RED}❌ Web build failed${NC}"
    exit 1
fi

# Build info
BUILD_DIR="build/web"
BUILD_SIZE=$(du -sh $BUILD_DIR | cut -f1)

echo -e "${BLUE}📊 Build Summary:${NC}"
echo -e "   Output directory: ${GREEN}$BUILD_DIR${NC}"
echo -e "   Build size: ${GREEN}$BUILD_SIZE${NC}"
echo -e "   Build mode: ${GREEN}$BUILD_MODE${NC}"
echo -e "   Optimization: ${GREEN}Level 4${NC}"

# List main files
echo -e "${BLUE}📁 Main build files:${NC}"
ls -la $BUILD_DIR/ | head -10

# Deployment instructions
echo ""
echo -e "${BLUE}🚀 Deployment Instructions:${NC}"
echo -e "${YELLOW}1. Upload the contents of '$BUILD_DIR' to your web server${NC}"
echo -e "${YELLOW}2. Ensure your server serves the files with correct MIME types${NC}"
echo -e "${YELLOW}3. Configure HTTPS for PWA features to work properly${NC}"
echo -e "${YELLOW}4. Set up proper caching headers for static assets${NC}"

# PWA check
if [ -f "$BUILD_DIR/manifest.json" ]; then
    echo -e "${GREEN}✅ PWA manifest found${NC}"
else
    echo -e "${YELLOW}⚠️  PWA manifest not found${NC}"
fi

# Service worker check
if [ -f "$BUILD_DIR/flutter_service_worker.js" ]; then
    echo -e "${GREEN}✅ Service worker found${NC}"
else
    echo -e "${YELLOW}⚠️  Service worker not found${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Web build completed successfully!${NC}"
echo -e "${BLUE}You can test the build locally by running:${NC}"
echo -e "${YELLOW}   cd $BUILD_DIR && python3 -m http.server 8000${NC}"
echo -e "${BLUE}Then open: ${YELLOW}http://localhost:8000${NC}"