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
create-dmg \
  --volname "$APP_NAME" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --icon "$APP_NAME.app" 175 190 \
  --hide-extension "$APP_NAME.app" \
  --app-drop-link 425 190 \
  "$DMG_OUTPUT" \
  "$RELEASE_DIR/"

echo ""
echo "✓ Done: $(pwd)/$DMG_OUTPUT"
