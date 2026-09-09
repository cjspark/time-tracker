#!/bin/bash
# sync-xcode.sh — 在 Mac 上运行，自动同步 Windows 推送的 Swift 代码到 Xcode 项目
# 用法: ./sync-xcode.sh

set -e

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SWIFT_SRC="$REPO/AnnuliSwift"
XCODE_SRC="$REPO/Annuli/Annuli"
XCODE_PROJ="$REPO/Annuli/Annuli.xcodeproj"

echo "→ git pull..."
git -C "$REPO" pull

echo "→ 同步 Swift 文件到 Xcode 目录..."
rsync -a --include="*.swift" --include="*/" --exclude="*" \
  "$SWIFT_SRC/" "$XCODE_SRC/"

echo "→ 检查并添加新文件到 Xcode 项目..."
ruby "$REPO/scripts/add-to-xcode.rb" "$XCODE_PROJ" "$XCODE_SRC" "$SWIFT_SRC"

echo ""
echo "✓ 完成！在 Xcode 中按 ⌘B 编译"
