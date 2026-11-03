#!/bin/bash

EXTENSIONS=$(code --list-extensions)
# Đường dẫn thực thi của Antigravity IDE trên macOS
ANTIGRAVITY_BIN="/Applications/Antigravity IDE.app/Contents/Resources/app/bin/code"

if [ ! -f "$ANTIGRAVITY_BIN" ]; then
  # Tự động tìm đường dẫn binary nếu app tên khác
  ANTIGRAVITY_BIN=$(which antigravity-ide 2>/dev/null || which antigravity 2>/dev/null)
fi

echo "Đang tự động cài đặt danh sách extension vào Antigravity IDE..."

for ext in $EXTENSIONS; do
  echo "----------------------------------------"
  echo "Đang cài đặt: $ext"
  "$ANTIGRAVITY_BIN" --install-extension "$ext"
done

echo "----------------------------------------"
echo "Bắt đầu đồng bộ settings"


# 1. Tạo thư mục User nếu chưa có
mkdir -p "$HOME/Library/Application Support/Antigravity IDE/User"

# 2. Đồng bộ file Cấu hình (settings.json)
cp "$HOME/Library/Application Support/Code/User/settings.json" "$HOME/Library/Application Support/Antigravity IDE/User/settings.json"

# 3. Đồng bộ file Phím tắt (keybindings.json)
cp "$HOME/Library/Application Support/Code/User/keybindings.json" "$HOME/Library/Application Support/Antigravity IDE/User/keybindings.json"

# 4. Đồng bộ toàn bộ Code Snippets (nếu có)
if [ -d "$HOME/Library/Application Support/Code/User/snippets" ]; then
  cp -R "$HOME/Library/Application Support/Code/User/snippets" "$HOME/Library/Application Support/Antigravity IDE/User/"
fi

echo "----------------------------------------"
echo "Hoàn tất quá trình đồng bộ!"
