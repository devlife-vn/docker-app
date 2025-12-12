#!/bin/bash

# ============================================
# SCRIPT: Import Database (Reset hoàn toàn)
# ============================================
# Chức năng: Reset và import database từ đầu
# - Bước 1: XOÁ database cũ (DROP DATABASE)
# - Bước 2: TẠO database mới (CREATE DATABASE)
# - Bước 3: IMPORT dữ liệu từ file SQL
#
# Sử dụng khi: Muốn reset hoàn toàn database về trạng thái mới
#
# So sánh:
#   - importsql: Import trực tiếp (giữ nguyên data cũ)
#   - importdb:  Drop DB → Create DB → Import (xoá hết data cũ)
# ============================================

# ============================================
# CẤU HÌNH DATABASE - Thay đổi tại đây
# ============================================
DB_HOST="localhost"        # Địa chỉ host database
DB_PORT="3306"             # Port của MySQL
DB_USER="root"             # Username
DB_PASS="root"             # Password
DB_NAME="db_tic"                 # Tên database (để trống nếu file SQL đã có USE database)
DB_CHARSET="utf8mb4"       # Charset mặc định

# ============================================
# XỬ LÝ THAM SỐ VÀ KIỂM TRA
# ============================================

# Lấy đường dẫn file (từ tham số hoặc hỏi user)
if [ -z "$1" ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Nhập đường dẫn tới file SQL cần import:"
    read -r FILE_PATH

    # Kiểm tra xem user có nhập gì không
    if [ -z "$FILE_PATH" ]; then
        echo "Lỗi: Đường dẫn file không được để trống"
        exit 1
    fi

    # Chế độ interactive: luôn hỏi database name
    INTERACTIVE_MODE=true
else
    FILE_PATH="$1"
    INTERACTIVE_MODE=false
fi

# Xử lý tên database
if [ ! -z "$2" ]; then
    # Có tham số thứ 2: dùng luôn
    DB_NAME="$2"
elif [ "$INTERACTIVE_MODE" = true ]; then
    # Chế độ interactive: hỏi user với option mặc định
    echo ""
    echo "Chọn database để import:"
    echo "  1. Sử dụng database mặc định: $DB_NAME"
    echo "  2. Nhập tên database khác"
    echo ""
    read -p "Lựa chọn của bạn (1/2, mặc định=1): " choice

    if [ "$choice" = "2" ]; then
        read -p "Nhập tên database mới: " INPUT_DB_NAME
        if [ ! -z "$INPUT_DB_NAME" ]; then
            DB_NAME="$INPUT_DB_NAME"
        fi
    fi
    # Nếu choice = 1 hoặc Enter, giữ nguyên DB_NAME mặc định
fi

# Đảm bảo DB_NAME không rỗng
if [ -z "$DB_NAME" ]; then
    echo "Lỗi: Tên database không hợp lệ"
    exit 1
fi

# Kiểm tra file có tồn tại không
if [ ! -f "$FILE_PATH" ]; then
    echo "Lỗi: File không tồn tại: $FILE_PATH"
    exit 1
fi

# ============================================
# THỰC HIỆN IMPORT
# ============================================

echo "============================================"
echo "Thông tin kết nối:"
echo "  Host: $DB_HOST"
echo "  Port: $DB_PORT"
echo "  User: $DB_USER"
echo "  Database: $DB_NAME"
echo "  File: $FILE_PATH"
echo "============================================"

# Câu lệnh MySQL cơ bản (không chỉ định database)
MYSQL_CMD="mysql -h$DB_HOST -P$DB_PORT -u$DB_USER -p$DB_PASS --default-character-set=$DB_CHARSET"

# Bước 1: Xoá database cũ
echo ""
echo "[1/3] Đang xoá database cũ: $DB_NAME"
$MYSQL_CMD -e "DROP DATABASE IF EXISTS $DB_NAME;"

if [ $? -eq 0 ]; then
    echo "✓ Đã xoá database: $DB_NAME"
else
    echo "✗ Lỗi khi xoá database!"
    exit 1
fi

# Bước 2: Tạo database mới
echo ""
echo "[2/3] Đang tạo database mới: $DB_NAME"
$MYSQL_CMD -e "CREATE DATABASE $DB_NAME CHARACTER SET $DB_CHARSET COLLATE ${DB_CHARSET}_unicode_ci;"

if [ $? -eq 0 ]; then
    echo "✓ Đã tạo database: $DB_NAME"
else
    echo "✗ Lỗi khi tạo database!"
    exit 1
fi

# Bước 3: Import file SQL
echo ""
echo "[3/3] Đang import file SQL vào database..."
$MYSQL_CMD $DB_NAME < "$FILE_PATH"

# Kiểm tra kết quả
if [ $? -eq 0 ]; then
    echo "✓ Import thành công!"
    echo ""
    echo "============================================"
    echo "Hoàn thành! Database $DB_NAME đã được reset và import dữ liệu mới."
    echo "============================================"
else
    echo "✗ Import thất bại!"
    exit 1
fi
