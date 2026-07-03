#!/bin/bash

# ============================================
# SCRIPT: Import SQL (Không xoá database)
# ============================================
# Chức năng: Import file SQL vào database hiện có
# - KHÔNG xoá database cũ
# - KHÔNG tạo lại database mới
# - Chỉ thực hiện import trực tiếp vào database
#
# Sử dụng khi: Muốn thêm/cập nhật dữ liệu vào database đã có
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
# XỬ LÝ THAM SỐ BẮT BUỘC
# ============================================

DB_NAME=""
FILE_PATH=""

# Parse tất cả tham số
while [[ $# -gt 0 ]]; do
    case $1 in
        --db=*)
            DB_NAME="${1#--db=}"
            shift
            ;;
        --file=*)
            FILE_PATH="${1#--file=}"
            shift
            ;;
        --help|-h)
            echo "Usage: $0 --db=<database_name> --file=<sql_file>"
            echo ""
            echo "Options:"
            echo "  --db=<name>     Database name to import (required)"
            echo "  --file=<path>   SQL file path to import (required)"
            echo "  -h, --help      Show this help message"
            echo ""
            echo "Example:"
            echo "  $0 --db=db_tic --file=/path/to/backup.sql"
            exit 0
            ;;
        *)
            echo "Lỗi: Tham số không hợp lệ: $1"
            echo ""
            echo "Usage: $0 --db=<database_name> --file=<sql_file>"
            exit 1
            ;;
    esac
done

# Kiểm tra tham số bắt buộc
if [ -z "$DB_NAME" ]; then
    echo "Lỗi: Tham số --db là bắt buộc"
    echo ""
    echo "Usage: $0 --db=<database_name> --file=<sql_file>"
    exit 1
fi

if [ -z "$FILE_PATH" ]; then
    echo "Lỗi: Tham số --file là bắt buộc"
    echo ""
    echo "Usage: $0 --db=<database_name> --file=<sql_file>"
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
if [ ! -z "$DB_NAME" ]; then
    echo "  Database: $DB_NAME"
fi
echo "  File: $FILE_PATH"
echo "============================================"

# Xây dựng câu lệnh MySQL
MYSQL_CMD="mysql -h$DB_HOST -P$DB_PORT -u$DB_USER -p$DB_PASS"

# Thêm database name nếu có
if [ ! -z "$DB_NAME" ]; then
    MYSQL_CMD="$MYSQL_CMD $DB_NAME"
fi

# Thêm charset
MYSQL_CMD="$MYSQL_CMD --default-character-set=$DB_CHARSET"

# Thực hiện import
echo "Đang import file..."
$MYSQL_CMD < "$FILE_PATH"

# Kiểm tra kết quả
if [ $? -eq 0 ]; then
    echo "Import thành công!"
else
    echo "Import thất bại!"
    exit 1
fi
