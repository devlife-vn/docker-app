#!/bin/bash

################################################################################
# Database Generation & Export Script
# Purpose: Import DB, mask sensitive data, export & optimize Laravel app
# Author: Development Team
# Version: 2.0
################################################################################

set -euo pipefail  # e=exit on error, u=error on undefined vars, o=pipe failure detection

################################################################################
# SECTION 1: CONFIGURATION & VARIABLES
################################################################################

# Color codes for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Generate timestamp once at script start
CURRENT_DATE=$(date +%Y_%m_%d)
TIME_STAMP=$(date +%H%M%S)

# ============ Path Configuration ============
DOWNLOADS_DIR="/Users/quandn/Downloads"
SCRIPTS_DIR="/Users/quandn/quandn"
TIC_WEB_DIR="/Users/quandn/quandn/web/tic"

# ============ Database Configuration ============
DATABASE_IMPORT_NAME="db_tic"

# ============ File Paths ============
GZ_FILE_PATH=""       # Sẽ được tìm tự động bởi find_sql_backup_file()
SQL_FILE_PATH=""      # Sẽ được set sau khi giải nén file .gz
SQL_MASK_FILE_PATH="$SCRIPTS_DIR/mask.sql"
ENV_FILE="$TIC_WEB_DIR/.env"

# ============ MySQL Configuration ============
MYSQL_USER="root"
MYSQL_PASS="root"
MYSQL_LOGIN="mysql -u $MYSQL_USER -p$MYSQL_PASS --batch --silent"

# ============ Logging Configuration ============
LOG_FILE="$DOWNLOADS_DIR/gen_db_${CURRENT_DATE}_${TIME_STAMP}.log"
TEMP_FILES=()  # Array to track temporary files for cleanup

################################################################################
# SECTION 2: UTILITY FUNCTIONS
################################################################################

printCurrentPath() {
    echo "Script location: $(realpath "$0")"
}

alert_success() {
    osascript -e 'display notification "Database generation completed successfully!" with title "Success" sound name "Glass"'
}

# ============ Logging Functions ============
# Ghi log với timestamp, giúp tracking toàn bộ quá trình thực thi
log() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${BLUE}[${timestamp}]${NC} ${message}" | tee -a "$LOG_FILE"
}

# Ghi log lỗi với màu đỏ để dễ phát hiện
log_error() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${RED}[ERROR]${NC} [${timestamp}] ${message}" | tee -a "$LOG_FILE" >&2
}

# Ghi log thành công với màu xanh
log_success() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${GREEN}[SUCCESS]${NC} [${timestamp}] ${message}" | tee -a "$LOG_FILE"
}

# Ghi log cảnh báo
log_warning() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${YELLOW}[WARNING]${NC} [${timestamp}] ${message}" | tee -a "$LOG_FILE"
}

move_to_trash() {
    local path="$1"

    if [ ! -e "$path" ]; then
        log_warning "File already gone: $path"
        return 0
    fi

    local trash_path="$HOME/.Trash/$(basename "$path")"
    if ! mv -f "$path" "$trash_path"; then
        log_error "Failed to move to Trash: $path"
        return 1
    fi
}

# ============ Performance Tracking ============
# Đo thời gian thực thi của từng command để phát hiện bottleneck
measure_time() {
    local task_name="$1"
    shift  # Loại bỏ tham số đầu, lấy phần còn lại làm command
    
    log "Starting: $task_name"
    local start_time=$(date +%s%N)
    
    # Thực thi command
    if eval "$@"; then
        local end_time=$(date +%s%N)
        local duration=$(echo "scale=3; ($end_time - $start_time) / 1000000000" | bc)
        log_success "$task_name completed in ${duration}s"
    else
        local exit_code=$?
        log_error "$task_name failed with exit code $exit_code"
        return $exit_code
    fi
}

# ============ Error Handling & Cleanup ============
# Cleanup tất cả file tạm thời khi script kết thúc (success hoặc error)
cleanup() {
    local exit_code=$?

    if [ $exit_code -ne 0 ]; then
        log_error "Script failed. Performing cleanup..."
    else
        log "Performing cleanup..."
        # Xóa log file khi thành công (không cần giữ lại)
        rm -f "$DOWNLOADS_DIR"/gen_db_*.log
        log_success "Log files removed (successful run)"
    fi

    # Xóa các file tạm thời trong TEMP_FILES array
    for temp_file in "${TEMP_FILES[@]:-}"; do
        if [ -f "$temp_file" ]; then
            rm -f "$temp_file"
            log "Removed temporary file: $temp_file"
        fi
    done

    exit $exit_code
}

# Trap EXIT để chạy cleanup dù script thành công hay lỗi
trap cleanup EXIT

# Trap ERR để log lỗi và exit
trap 'log_error "Error at line $LINENO"; exit 1' ERR

################################################################################
# SECTION 3: PREREQUISITE CHECKS
################################################################################

# ============ 3.0: Find & Extract SQL Backup File ============
# Tự động tìm file backup-daily-*.gz được tải về trong ngày hôm nay
# Format tên file: backup-daily-YYYYMMDDHHMMSS-<random>.gz
find_sql_backup_file() {
    log "Searching for today's SQL backup file in $DOWNLOADS_DIR..."

    local today=$(date +%Y%m%d)
    local found_file

    # Dùng -newer so sánh với mốc đầu ngày hôm nay (tương thích macOS BSD find)
    # Tạo file tạm làm mốc thời gian 00:00:00 hôm nay
    local today_marker
    today_marker=$(mktemp)
    touch -t "${today}0000" "$today_marker"

    local all_files
    all_files=$(find "$DOWNLOADS_DIR" \
        -maxdepth 1 \
        -name "backup-daily-*.gz" \
        -newer "$today_marker" \
        | sort)  # sort alphabet = sort theo timestamp vì format tên cố định

    rm -f "$today_marker"

    local file_count
    file_count=$(echo "$all_files" | grep -c . || true)

    if [ "$file_count" -gt 1 ]; then
        log_warning "Found $file_count backup files today, picking the latest:"
        echo "$all_files" | while read -r f; do log "  - $(basename "$f")"; done
    fi

    found_file=$(echo "$all_files" | tail -1)

    if [ -z "$found_file" ]; then
        log_error "No backup-daily-*.gz file found in $DOWNLOADS_DIR for today ($today)"
        log_error "Expected file pattern: backup-daily-${today}HHMMSS-<random>.gz"
        return 1
    fi

    # Validate tên file đúng pattern: backup-daily-YYYYMMDDHHMMSS-<random>.gz
    local filename
    filename=$(basename "$found_file")
    if [[ ! "$filename" =~ ^backup-daily-[0-9]{14}-[A-Za-z0-9]+\.gz$ ]]; then
        log_error "File name does not match expected pattern: $filename"
        log_error "Expected: backup-daily-YYYYMMDDHHMMSS-<random>.gz"
        return 1
    fi

    GZ_FILE_PATH="$found_file"
    log_success "Found backup file: $filename"

    # Validate file không rỗng
    if [ ! -s "$GZ_FILE_PATH" ]; then
        log_error "Backup file is empty: $filename"
        return 1
    fi

    # Validate file là gzip hợp lệ
    if ! gunzip -t "$GZ_FILE_PATH" 2>/dev/null; then
        log_error "File is not a valid gzip archive: $filename"
        return 1
    fi

    log_success "Backup file integrity verified"

    # Giải nén .gz thành .sql trong Downloads
    SQL_FILE_PATH="${GZ_FILE_PATH%.gz}.sql"
    log "Extracting to: $(basename "$SQL_FILE_PATH")..."

    gunzip -c "$GZ_FILE_PATH" > "$SQL_FILE_PATH" \
        || { log_error "Failed to extract $GZ_FILE_PATH"; return 1; }

    log_success "Extracted: $(basename "$SQL_FILE_PATH")"

}

# ============ 3.1: Verify MySQL Connection ============
# Kiểm tra kết nối MySQL trước khi chạy để tránh lãng phí thời gian
verify_mysql_connection() {
    log "Verifying MySQL connection..."
    
    if $MYSQL_LOGIN -e "SELECT 1" &>/dev/null; then
        log_success "MySQL connection verified"
        return 0
    else
        log_error "MySQL connection failed. Please check credentials:"
        log_error "  User: $MYSQL_USER"
        log_error "  Host: localhost"
        return 1
    fi
}

# ============ 3.2: Check Required Files ============
# Đảm bảo tất cả file cần thiết tồn tại trước khi bắt đầu
check_required_files() {
    log "Checking required files..."

    local files_to_check=(
        "$SQL_MASK_FILE_PATH:SQL mask file"
        "$ENV_FILE:Laravel .env file"
    )

    local all_exist=true
    for file_check in "${files_to_check[@]}"; do
        local file_path="${file_check%%:*}"
        local file_desc="${file_check##*:}"

        if [ ! -f "$file_path" ]; then
            log_error "Missing: $file_desc - $file_path"
            all_exist=false
        else
            log "Found: $file_desc"
        fi
    done

    [ "$all_exist" = true ] || return 1

    # Validate nội dung file SQL đã giải nén
    log "Validating SQL file content..."

    if [ ! -s "$SQL_FILE_PATH" ]; then
        log_error "SQL file is empty: $SQL_FILE_PATH"
        return 1
    fi

    if ! grep -q -m1 "^CREATE\|^INSERT\|^DROP\|^ALTER" "$SQL_FILE_PATH"; then
        log_error "File does not appear to be a valid SQL dump: $SQL_FILE_PATH"
        return 1
    fi

    log_success "SQL file content looks valid"
}

# ============ 3.3: Check Directory Access ============
# Kiểm tra quyền ghi/đọc trên các thư mục quan trọng
check_directory_access() {
    log "Checking directory access..."
    
    local dirs_to_check=(
        "$DOWNLOADS_DIR"
        "$TIC_WEB_DIR"
    )
    
    for dir in "${dirs_to_check[@]}"; do
        if [ ! -d "$dir" ]; then
            log_error "Directory not found: $dir"
            return 1
        fi
        
        if [ ! -w "$dir" ]; then
            log_error "No write permission: $dir"
            return 1
        fi
        
        log "Directory OK: $dir"
    done
}

# ============ 3.4: Check Disk Space ============
# Tính toán dung lượng cần thiết (~3x file SQL)
# Vì cần chỗ cho: file SQL gốc + database trong memory + export file
check_disk_space() {
    log "Checking available disk space..."
    
    local sql_file_size=$(stat -f%z "$SQL_FILE_PATH" 2>/dev/null || echo 0)
    local required_space=$((sql_file_size * 3))  # Estimate: 3x original file
    
    # Lấy dung lượng trống của ổ đĩa nơi DOWNLOADS_DIR
    local available_space=$(df "$DOWNLOADS_DIR" | awk 'NR==2 {print $4}' | awk '{print $1 * 1024}')
    
    log "SQL file size: $(echo "scale=2; $sql_file_size / 1024 / 1024" | bc) MB"
    log "Estimated space needed: $(echo "scale=2; $required_space / 1024 / 1024" | bc) MB"
    log "Available space: $(echo "scale=2; $available_space / 1024 / 1024" | bc) MB"
    
    if [ $available_space -lt $required_space ]; then
        log_error "Insufficient disk space!"
        return 1
    fi
    
    log_success "Disk space check passed"
}

# ============ 3.5: Run All Prerequisite Checks ============
run_prerequisite_checks() {
    log "=========================================="
    log "Running prerequisite checks..."
    log "=========================================="

    verify_mysql_connection || return 1
    find_sql_backup_file || return 1   # Tìm & giải nén .gz -> set SQL_FILE_PATH
    check_required_files || return 1

    log "Appending SQL mask to the extracted dump..."
    {
        printf '\n\n-- Begin data masking --\n'
        cat "$SQL_MASK_FILE_PATH"
        printf '\n-- End data masking --\n'
    } >> "$SQL_FILE_PATH" \
        || { log_error "Failed to append SQL mask"; return 1; }
    log_success "SQL dump and mask merged"

    check_directory_access || return 1
    check_disk_space || return 1

    log_success "All prerequisite checks passed!"
}

################################################################################
# SECTION 4: PRINT CONFIGURATION SUMMARY
################################################################################

# Hiển thị overview thông tin và cấu hình trước khi bắt đầu
print_overview() {
    log "=========================================="
    log "Database Generation Overview"
    log "=========================================="
    log "Date: $CURRENT_DATE"
    log "Time: $TIME_STAMP"
    log ""
    log "--- File Paths ---"
    log "SQL import: $SQL_FILE_PATH"
    log "SQL mask: $SQL_MASK_FILE_PATH"
    log ""
    log "--- Database Info ---"
    log "Database name: $DATABASE_IMPORT_NAME"
    log ""
    log "--- Output Locations ---"
    log "Script log: $LOG_FILE"
    log "=========================================="
}

################################################################################
# SECTION 5: DATABASE IMPORT
################################################################################

# ============ 5.1: Drop & Create Database ============
# Xóa database cũ (nếu tồn tại) và tạo mới
# Điều này đảm bảo môi trường clean, không có dữ liệu stale
drop_and_create_database() {
    log "Preparing database: $DATABASE_IMPORT_NAME"
    
    $MYSQL_LOGIN -e "DROP DATABASE IF EXISTS $DATABASE_IMPORT_NAME;" \
        || { log_error "Failed to drop database"; return 1; }
    
    $MYSQL_LOGIN -e "CREATE DATABASE $DATABASE_IMPORT_NAME;" \
        || { log_error "Failed to create database"; return 1; }
    
    log_success "Database prepared"
}

# ============ 5.2: Import SQL Data ============
# Import dữ liệu từ file SQL
# Dùng pv nếu có để theo dõi progress (hữu ích cho file lớn > 500MB)
import_sql_data() {
    log "Importing SQL data into $DATABASE_IMPORT_NAME..."
    
    if command -v pv &>/dev/null; then
        # Nếu có pv, hiển thị progress bar
        pv "$SQL_FILE_PATH" | $MYSQL_LOGIN $DATABASE_IMPORT_NAME \
            || { log_error "SQL import failed"; return 1; }
    else
        # Fallback: import bình thường
        $MYSQL_LOGIN $DATABASE_IMPORT_NAME < "$SQL_FILE_PATH" \
            || { log_error "SQL import failed"; return 1; }
    fi
    
    log_success "SQL data imported successfully"
}

# ============ 5.3: Validate Import ============
# Kiểm tra xem import có thành công không
# Đếm số bảng và tổng số rows để xác thực
validate_import() {
    log "Validating database import..."
    
    local table_count=$($MYSQL_LOGIN "$DATABASE_IMPORT_NAME" -se \
        "SELECT COUNT(DISTINCT table_name) FROM information_schema.tables WHERE table_schema='$DATABASE_IMPORT_NAME';")
    
    local row_count=$($MYSQL_LOGIN "$DATABASE_IMPORT_NAME" -se \
        "SELECT SUM(table_rows) FROM information_schema.tables WHERE table_schema='$DATABASE_IMPORT_NAME';")
    
    log "Database validation:"
    log "  - Tables: $table_count"
    log "  - Total rows: $row_count"
    
    if [ "$table_count" -le 0 ]; then
        log_error "Database import appears to be empty!"
        return 1
    fi
    
    log_success "Import validation passed"
}

################################################################################
# SECTION 6: ENVIRONMENT FILE UPDATE
################################################################################

# ============ 9.1: Update .env File ============
# Cập nhật DB_DATABASE trong .env để Laravel kết nối tới database mới
update_env_file() {
    log "Updating .env file with new database name..."
    
    if [ ! -f "$ENV_FILE" ]; then
        log_error ".env file not found: $ENV_FILE"
        return 1
    fi
    
    # Backup .env trước khi sửa (bảo mật)
    cp "$ENV_FILE" "${ENV_FILE}.backup"
    log "Backup created: ${ENV_FILE}.backup"
    
    # Check xem DB_DATABASE đã tồn tại chưa
    if grep -q "^DB_DATABASE=" "$ENV_FILE"; then
        # Cập nhật giá trị hiện tại
        sed -i '' -E "s|^DB_DATABASE=.*|DB_DATABASE=$DATABASE_IMPORT_NAME|" "$ENV_FILE"
        log "Updated existing DB_DATABASE variable"
    else
        # Thêm dòng mới nếu chưa tồn tại
        echo "" >> "$ENV_FILE"
        echo "DB_DATABASE=$DATABASE_IMPORT_NAME" >> "$ENV_FILE"
        log "Added new DB_DATABASE variable"
    fi
    
    log_success ".env file updated successfully"
}

# ============ Options ============
KEEP_ORIGINAL=false

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --keep-original|-k)
                KEEP_ORIGINAL=true
                shift
                ;;
            --help|-h)
                echo "Usage: $0 [options]"
                echo "Options:"
                echo "  -k, --keep-original    Do not delete original backup-daily-*.gz file(s)"
                echo "  -h, --help             Show this help message"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
}

remove_other_file() {
    # Xóa file .sql đã giải nén (chỉ xóa khi thành công, giữ lại khi lỗi để debug)
    if [ -f "$SQL_FILE_PATH" ]; then
        rm -f "$SQL_FILE_PATH"
        log_success "Removed extracted SQL file: $(basename "$SQL_FILE_PATH")"
    fi

    # Xóa tất cả file backup-daily-*.gz (nếu KHÔNG bật tùy chọn KEEP_ORIGINAL)
    if [ "$KEEP_ORIGINAL" = true ]; then
        log "Skipping deletion of original backup-daily-*.gz file(s) (--keep-original enabled)"
    else
        local gz_count=0
        for gz_file in "$DOWNLOADS_DIR"/backup-daily-*.gz; do
            if [ -f "$gz_file" ]; then
                move_to_trash "$gz_file" || return 1
                log "Moved to Trash: $(basename "$gz_file")"
                ((gz_count++))
            fi
        done
        [ $gz_count -gt 0 ] && log_success "Removed $gz_count backup-daily-*.gz file(s)"
    fi

    # Chạy thành công -> xóa tất cả log (kể cả log của các lần chạy cũ)
    rm -f "$DOWNLOADS_DIR"/gen_db_*.log
    log_success "All log files removed (successful run)"
}

################################################################################
# SECTION 10: LARAVEL OPTIMIZATION
################################################################################

# ============ 10.1: Clear & Optimize Laravel ============
# Clear cache, compile config & routes
# Đây là bước quan trọng sau khi import dữ liệu mới
optimize_laravel() {
    log "=========================================="
    log "Optimizing Laravel application"
    log "=========================================="
    
    cd "$TIC_WEB_DIR" || { log_error "Failed to cd to $TIC_WEB_DIR"; return 1; }
    
    # Clear caches
    log "Clearing application cache..."
    php artisan optimize:clear --quiet || log_warning "optimize:clear encountered an issue"
    php artisan cache:clear --quiet || log_warning "cache:clear encountered an issue"
    
    # Pre-compile config & routes (tăng performance)
    log "Pre-compiling configuration..."
    php artisan config:cache --quiet || log_warning "config:cache encountered an issue"
    
    log "Pre-compiling routes..."
    php artisan route:cache --quiet || log_warning "route:cache encountered an issue"
    
    log "Pre-compiling views..."
    php artisan view:cache --quiet || log_warning "view:cache encountered an issue"
    
    log_success "Laravel optimization completed"
}

################################################################################
# SECTION 11: FINAL SUMMARY & COMPLETION
################################################################################

# ============ 11.1: Print Summary ============
# Hiển thị kết quả cuối cùng với các thông tin quan trọng
print_completion_summary() {
    local completion_time=$(date '+%Y-%m-%dT%H:%M:%S')
    
    log "=========================================="
    log_success "All tasks completed successfully!"
    log "=========================================="
    log ""
    log "📊 Final Summary:"
    log "   - Database name: $DATABASE_IMPORT_NAME"
    log "   - Database generated and masked locally"
    log "   - Completion time: $completion_time"
    log "   - Log file: $LOG_FILE"
    log "   - Keep Original File: $KEEP_ORIGINAL"
    log ""
    log "✅ Next Steps:"
    log "   1. Run ticDBExport separately when a staff export is needed"
    log ""
    log "=========================================="
}

################################################################################
# SECTION 12: MAIN EXECUTION FLOW
################################################################################

# ============ 12.1: Main Function ============
# Kết hợp tất cả các bước lại thành một quy trình hoàn chỉnh
main() {
    parse_args "$@"

    log "=========================================="
    log "Starting Database Generation Script"
    log "=========================================="
    printCurrentPath

    # Step 1: Kiểm tra prerequisites
    run_prerequisite_checks || exit 1
    
    # Step 2: Hiển thị overview
    print_overview
    
    # Step 3: Import database gốc và masking trong một lần
    log "=========================================="
    log "PHASE 1: Database Import & Masking"
    log "=========================================="
    measure_time "Drop & Create Database" "drop_and_create_database" || exit 1
    measure_time "Import Database & Apply Mask" "import_sql_data" || exit 1
    measure_time "Validate Import & Masking" "validate_import" || exit 1
    
    # # Step 5: Cập nhật environment
    # log "=========================================="
    # log "PHASE 5: Environment Configuration"
    # log "=========================================="
    # measure_time "Update .env File" "update_env_file" || exit 1
    
    # # Step 6: Optimize Laravel
    # log "=========================================="
    # log "PHASE 6: Laravel Optimization"
    # log "=========================================="
    # measure_time "Optimize Laravel" "optimize_laravel" || exit 1
    
    # Step 7: Cleanup các file không cần thiết
    log "=========================================="
    log "PHASE 5: Cleanup Temporary Files"
    log "=========================================="
    remove_other_file || log_warning "Cleanup encountered an issue"

    if [ "$KEEP_ORIGINAL" = false ]; then
        bash ~/quandn/clean_download_folder.sh;
    else
        log "Skipping clean_download_folder.sh (--keep-original enabled)"
    fi

    # Step 8: Print summary
    print_completion_summary

    # Step 9: Gửi thông báo macOS
    alert_success
}

################################################################################
# SCRIPT EXECUTION
################################################################################

# Chỉ chạy main nếu script được gọi trực tiếp (không được source)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi