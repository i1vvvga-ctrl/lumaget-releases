#!/bin/bash
# Установка Luma на Mac одной командой в Терминале:
#   curl -fsSL https://raw.githubusercontent.com/i1vvvga-ctrl/lumaget-releases/main/install-mac.sh | bash
set -euo pipefail
REPO="i1vvvga-ctrl/lumaget-releases"

case "$(uname -m)" in
  arm64) pat="arm64" ;;
  x86_64) pat="x64" ;;
  *) echo "Эта архитектура не поддерживается: $(uname -m)"; exit 1 ;;
esac

echo "Ищем последнюю версию Luma для Mac ($pat)…"
# The newest release that has a Mac build (a Windows-only release must not break the Mac command).
json="$(curl -fsSL "https://api.github.com/repos/$REPO/releases?per_page=15")"
url="$(printf '%s' "$json" | grep -o '"browser_download_url": *"[^"]*macOS-'"$pat"'[^"]*\.zip"' | head -1 | sed 's/.*"\(https[^"]*\)"/\1/')"
if [ -z "$url" ]; then
  echo "Версия для Mac пока не опубликована. Попробуйте позже."
  exit 1
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
echo "Скачиваем…"
curl -fL --progress-bar "$url" -o "$tmp/luma.zip"
ditto -x -k "$tmp/luma.zip" "$tmp/app"
app="$(find "$tmp/app" -maxdepth 2 -name '*.app' | head -1)"
[ -n "$app" ] || { echo "В архиве не найдено приложение."; exit 1; }

dest="/Applications"
[ -w "$dest" ] || dest="$HOME/Applications"
mkdir -p "$dest"
pkill -x Luma 2>/dev/null || true
rm -rf "$dest/Luma.app"
ditto "$app" "$dest/Luma.app"

# Приложение не подписано Apple: снимаем карантин и ставим локальную подпись, чтобы macOS его открыл.
xattr -cr "$dest/Luma.app"
codesign --force --deep --sign - "$dest/Luma.app" >/dev/null 2>&1 || true

echo "Готово: $dest/Luma.app"
echo "Чтобы обновить Luma, запустите эту же команду ещё раз."
open "$dest/Luma.app"
