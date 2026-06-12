#!/bin/bash

# ============================================
# SCRIPT: Import Database (Reset hoàn toàn)
# ============================================
# Chức năng: Reset và import database từ đầu
# - Bước 0: GIẢI NÉN file ZIP (nếu input là .zip)
# - Bước 1: XOÁ database cũ (DROP DATABASE)
# - Bước 2: TẠO database mới (CREATE DATABASE)
# - Bước 3: IMPORT dữ liệu từ file SQL
# - Bước 4: DỌN DẸP file tạm (xóa file SQL đã giải nén)
#
# Hỗ trợ file input:
#   - File .sql: Import trực tiếp
#   - File .zip: Tự động giải nén → Import → Xóa file tạm
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
DB_NAME="db_tic"           # Tên database (để trống nếu file SQL đã có USE database)
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

# Xử lý tham số thứ 2
# --role: import vào database tic_role
# Tham số khác: báo lỗi và dừng
if [ ! -z "$2" ]; then
    if [ "$2" = "--role" ]; then
        DB_NAME="tic_role"
    else
        echo "Lỗi: Tham số thứ 2 không hợp lệ: $2"
        echo "Chỉ hỗ trợ tham số: --role (import vào database tic_role)"
        echo ""
        echo "Cách sử dụng:"
        echo "  $0 <file.sql>          # Import vào database mặc định (db_tic)"
        echo "  $0 <file.sql> --role   # Import vào database tic_role"
        exit 1
    fi
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
# XỬ LÝ FILE ZIP (NẾU CÓ)
# ============================================

# Kiểm tra extension của file
FILE_EXT="${FILE_PATH##*.}"
CLEANUP_REQUIRED=false

if [ "$FILE_EXT" = "zip" ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📦 Phát hiện file ZIP, đang giải nén..."
    echo ""

    # Tạo thư mục tạm để giải nén
    EXTRACT_DIR=$(mktemp -d)

    # Giải nén file
    unzip -q "$FILE_PATH" -d "$EXTRACT_DIR"

    if [ $? -ne 0 ]; then
        echo "✗ Lỗi khi giải nén file ZIP!"
        rm -rf "$EXTRACT_DIR"
        exit 1
    fi

    # Tìm file .sql trong thư mục giải nén (lấy file đầu tiên nếu có nhiều file)
    SQL_FILE=$(find "$EXTRACT_DIR" -type f -name "*.sql" | head -n 1)

    if [ -z "$SQL_FILE" ]; then
        echo "✗ Không tìm thấy file .sql trong file ZIP!"
        rm -rf "$EXTRACT_DIR"
        exit 1
    fi

    echo "✓ Đã giải nén: $(basename "$SQL_FILE")"
    echo "✓ Kích thước: $(du -h "$SQL_FILE" | cut -f1)"

    # Cập nhật FILE_PATH để sử dụng file SQL đã giải nén
    FILE_PATH="$SQL_FILE"
    CLEANUP_REQUIRED=true
    CLEANUP_PATH="$EXTRACT_DIR"
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

# ============================================
# DỌN DẸP FILE TẠM (NẾU CÓ)
# ============================================

if [ "$CLEANUP_REQUIRED" = true ]; then
    echo ""
    echo "🧹 Đang dọn dẹp file tạm..."

    # Xóa thư mục giải nén (bao gồm cả file .sql)
    rm -rf "$CLEANUP_PATH"

    if [ $? -eq 0 ]; then
        echo "✓ Đã xóa file SQL đã giải nén và giải phóng dung lượng"
    else
        echo "⚠️  Cảnh báo: Không thể xóa file tạm tại: $CLEANUP_PATH"
        echo "   Bạn có thể xóa thủ công để giải phóng dung lượng"
    fi
fi

if ([ "$2" = "--role" ]); then
    cd /Users/quandn/quandn/web/tic;

    # đổi DATABASE_NAME thành tic_role trong .env
    sed -i '' "s/DB_DATABASE=.*/DB_DATABASE=tic_role/" /Users/quandn/quandn/web/tic/.env

    # chạy command để lấy ra bảng permissions từ tic_role và import vào bảng permissions của db_tic
    php artisan migrate:fresh --seed && mysql -u root -proot -e "SELECT * FROM permissions" tic_role | sed 's/\t/,/g' > ~/Downloads/permission_$(date +%d%m%Y_%H%M%S).csv && open ~/Downloads/

    # đổi lại DATABASE_NAME thành db_tic trong .env
    sed -i '' "s/DB_DATABASE=.*/DB_DATABASE=db_tic/" /Users/quandn/quandn/web/tic/.env

    # optimize lại
    php artisan optimize:clear
fi

osascript -e 'display notification "Đã import database thành công" with title "Terminal"'