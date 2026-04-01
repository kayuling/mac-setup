#!/bin/zsh
set -e

XCODEBUILD="/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild"
APP_NAME="MacSetup"
BUILD_DIR="build"
RELEASE_DIR="$BUILD_DIR/Build/Products/Release"
APP_PATH="$RELEASE_DIR/$APP_NAME.app"
DMG_OUTPUT="$APP_NAME.dmg"

echo "==> Building $APP_NAME (Release)..."
"$XCODEBUILD" \
  -project "$APP_NAME.xcodeproj" \
  -scheme "$APP_NAME" \
  -configuration Release \
  -derivedDataPath "$BUILD_DIR" \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  | grep -E "(error:|warning:|BUILD (SUCCEEDED|FAILED))"

echo "==> Installing create-dmg if needed..."
brew install create-dmg 2>/dev/null || true

echo "==> Creating DMG..."
rm -f "$DMG_OUTPUT"

# Stage only the .app — avoids dSYM / swiftmodule clutter in the DMG
STAGING_DIR="$BUILD_DIR/dmg-staging"
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"
cp -R "$APP_PATH" "$STAGING_DIR/"

echo "==> Codesigning..."
codesign --force --deep --sign - "$STAGING_DIR/$APP_NAME.app"

create-dmg \
  --volname "$APP_NAME" \
  --window-pos 200 120 \
  --window-size 540 380 \
  --icon-size 120 \
  --icon "$APP_NAME.app" 160 185 \
  --hide-extension "$APP_NAME.app" \
  --app-drop-link 380 185 \
  "$DMG_OUTPUT" \
  "$STAGING_DIR/"

rm -rf "$STAGING_DIR"

echo ""
echo "✓ Done: $(pwd)/$DMG_OUTPUT"
