#!/bin/bash

set -e

APP_NAME="SYFLV"
# 从 Info.plist 读取版本号（单一版本源）
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" Info.plist)
echo "📋 Version: $VERSION"

BUILD_DIR=".build/release"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
ICONSET_DIR="$BUILD_DIR/AppIcon.iconset"

echo "🔨 Building release..."
swift build -c release

echo "🎨 Generating app icon..."
# 创建 iconset 目录
rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR"

# 使用 rsvg-convert 或 sips 转换 SVG 到各种尺寸 PNG
if command -v rsvg-convert &> /dev/null; then
    for size in 16 32 64 128 256 512 1024; do
        rsvg-convert -w $size -h $size AppIcon.svg -o "$ICONSET_DIR/icon_${size}x${size}.png"
    done
    # 创建 @2x 版本
    cp "$ICONSET_DIR/icon_32x32.png" "$ICONSET_DIR/icon_16x16@2x.png"
    cp "$ICONSET_DIR/icon_64x64.png" "$ICONSET_DIR/icon_32x32@2x.png"
    cp "$ICONSET_DIR/icon_256x256.png" "$ICONSET_DIR/icon_128x128@2x.png"
    cp "$ICONSET_DIR/icon_512x512.png" "$ICONSET_DIR/icon_256x256@2x.png"
    cp "$ICONSET_DIR/icon_1024x1024.png" "$ICONSET_DIR/icon_512x512@2x.png"
    rm -f "$ICONSET_DIR/icon_64x64.png" "$ICONSET_DIR/icon_1024x1024.png"
else
    echo "⚠️  rsvg-convert not found, using placeholder icon"
    # 创建简单的占位图标
    for size in 16 32 128 256 512; do
        sips -z $size $size Sources/RuntimePilot/Resources/java.png --out "$ICONSET_DIR/icon_${size}x${size}.png" 2>/dev/null || true
    done
fi

# 生成 icns 文件
if [ -d "$ICONSET_DIR" ] && [ "$(ls -A $ICONSET_DIR)" ]; then
    iconutil -c icns "$ICONSET_DIR" -o "$BUILD_DIR/AppIcon.icns" 2>/dev/null || echo "⚠️  Could not generate icns"
fi

echo "📦 Creating app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# 复制可执行文件
cp "$BUILD_DIR/$APP_NAME" "$MACOS_DIR/"

# 复制 Info.plist
cp "Info.plist" "$CONTENTS_DIR/"

# 复制图标
if [ -f "$BUILD_DIR/AppIcon.icns" ]; then
    cp "$BUILD_DIR/AppIcon.icns" "$RESOURCES_DIR/"
    # 更新 Info.plist 添加图标引用
    /usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon" "$CONTENTS_DIR/Info.plist" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Set :CFBundleIconFile AppIcon" "$CONTENTS_DIR/Info.plist"
fi

# 复制资源文件
cp Sources/RuntimePilot/Resources/*.png "$RESOURCES_DIR/" 2>/dev/null || true

echo "✅ App bundle created: $APP_BUNDLE"

# 签名：有 Developer ID 时做正式签名；没有时至少做 ad-hoc 签名。
# 未签名的组装 App bundle 会被 macOS 判定为“已损坏”（资源与签名不匹配）。
if [ -n "${CODESIGN_IDENTITY:-}" ]; then
    echo "🔐 Signing app with identity: $CODESIGN_IDENTITY..."
    codesign --force --deep --options runtime --timestamp --sign "$CODESIGN_IDENTITY" "$APP_BUNDLE"
else
    echo "ℹ️  CODESIGN_IDENTITY not set; applying ad-hoc signature (no Apple Developer required)."
    codesign --force --deep --sign - "$APP_BUNDLE"
fi
codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"

echo "💿 Creating DMG..."
DMG_NAME="$APP_NAME-$VERSION.dmg"
DMG_TEMP="$BUILD_DIR/dmg_temp"

rm -rf "$DMG_TEMP"
mkdir -p "$DMG_TEMP"
cp -R "$APP_BUNDLE" "$DMG_TEMP/"

# 创建 Applications 软链接
ln -s /Applications "$DMG_TEMP/Applications"

# 生成 DMG
rm -f "$DMG_NAME"
hdiutil create -volname "$APP_NAME" -srcfolder "$DMG_TEMP" -ov -format UDZO "$DMG_NAME"

# 可选公证
if [ -n "${NOTARY_PROFILE:-}" ]; then
    echo "📝 Notarizing DMG with profile: $NOTARY_PROFILE..."
    xcrun notarytool submit "$DMG_NAME" --keychain-profile "$NOTARY_PROFILE" --wait
    xcrun stapler staple "$DMG_NAME"
fi

rm -rf "$DMG_TEMP"

echo ""
echo "🎉 Done!"
echo "   App: $APP_BUNDLE"
echo "   DMG: $DMG_NAME"
echo ""
echo "To run the app:"
echo "  open $APP_BUNDLE"
echo ""
echo "To install:"
echo "  open $DMG_NAME"
