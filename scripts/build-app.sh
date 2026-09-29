#!/usr/bin/env bash
# Собирает Glazki.app и Glazki.dmg. Запускается на macOS (локально или в GitHub Actions).
set -euo pipefail
cd "$(dirname "$0")/.."

APP=Glazki
VERSION="${VERSION:-1.0.0}"
BUILD="${BUILD:-1}"
OUT=build
BUNDLE="$OUT/$APP.app"

swift build -c release --arch arm64
BIN="$(swift build -c release --arch arm64 --show-bin-path)/$APP"

rm -rf "$OUT"
mkdir -p "$BUNDLE/Contents/MacOS" "$BUNDLE/Contents/Resources"
cp "$BIN" "$BUNDLE/Contents/MacOS/$APP"
sed -e "s/__VERSION__/$VERSION/" -e "s/__BUILD__/$BUILD/" Resources/Info.plist > "$BUNDLE/Contents/Info.plist"
cp Resources/Sounds/*.wav "$BUNDLE/Contents/Resources/"

ICONSET="$OUT/AppIcon.iconset"
mkdir -p "$ICONSET"
for s in 16 32 128 256 512; do
  sips -z $s $s Resources/AppIcon.png --out "$ICONSET/icon_${s}x${s}.png" >/dev/null
  d=$((s * 2))
  sips -z $d $d Resources/AppIcon.png --out "$ICONSET/icon_${s}x${s}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$BUNDLE/Contents/Resources/AppIcon.icns"

# Подпись без сертификата разработчика (ad-hoc) — нужна, чтобы приложение запускалось на Apple Silicon.
codesign --force --deep --sign - "$BUNDLE"

mkdir -p "$OUT/dmg"
cp -R "$BUNDLE" "$OUT/dmg/"
ln -s /Applications "$OUT/dmg/Applications"
hdiutil create -volname "Глазки" -srcfolder "$OUT/dmg" -ov -format UDZO "$OUT/$APP.dmg"
echo "Готово: $OUT/$APP.dmg"
