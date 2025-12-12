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
CURRENT_DATE=$(date +%d_%m_%Y)
TIME_STAMP=$(date +%H%M%S)

# ============ Path Configuration ============
DOWNLOADS_DIR="/Users/quandn/Downloads"
SCRIPTS_DIR="/Users/quandn/quandn"
TIC_WEB_DIR="/Users/quandn/quandn/web/tic"

# ============ Database Configuration ============
DATABASE_IMPORT_NAME="db_tic"
DATABASE_EXPORT_NAME="${CURRENT_DATE}_database"
ACTIVE_LOG_TABLE="active_logs"
ACTIVE_LOG_NAME="${CURRENT_DATE}_${ACTIVE_LOG_TABLE}"

# ============ File Paths ============
SQL_FILE_PATH="$DOWNLOADS_DIR/$CURRENT_DATE.sql"
SQL_MASK_FILE_PATH="$SCRIPTS_DIR/mask.sql"
ACTIVE_LOG_SQL_PATH="$DOWNLOADS_DIR/$ACTIVE_LOG_NAME.sql"
DATABASE_EXPORT_PATH="$DOWNLOADS_DIR/$DATABASE_EXPORT_NAME"
FINAL_ZIP_PATH="${DATABASE_EXPORT_PATH}.zip"
ENV_FILE="$TIC_WEB_DIR/.env"

# ============ MySQL Configuration ============
MYSQL_USER="root"
MYSQL_PASS="root"
MYSQL_LOGIN="mysql -u $MYSQL_USER -p$MYSQL_PASS --batch --silent"
MYSQL_DUMP="mysqldump -u $MYSQL_USER -p$MYSQL_PASS"

# ============ Logging Configuration ============
LOG_FILE="$DOWNLOADS_DIR/gen_db_${CURRENT_DATE}_${TIME_STAMP}.log"
TEMP_FILES=()  # Array to track temporary files for cleanup

################################################################################
# SECTION 2: UTILITY FUNCTIONS
################################################################################

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
    fi
    
    # Xóa active_logs.sql nếu vẫn còn
    cleanup_active_logs_sql
    
    # Xóa các file tạm thời trong TEMP_FILES array
    for temp_file in "${TEMP_FILES[@]}"; do
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

# ============ Specific Cleanup ============
# Xóa file active_logs.sql sau khi backup (nếu vẫn còn)
cleanup_active_logs_sql() {
    if [ -f "$ACTIVE_LOG_SQL_PATH" ]; then
        rm -f "$ACTIVE_LOG_SQL_PATH"
        log "Cleaned up: $ACTIVE_LOG_SQL_PATH"
    fi
}

################################################################################
# SECTION 3: PREREQUISITE CHECKS
################################################################################

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
        "$SQL_FILE_PATH:SQL import file"
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
    check_required_files || return 1
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
    log "Active logs export: $DOWNLOADS_DIR/$ACTIVE_LOG_NAME.zip"
    log "Final database export: $FINAL_ZIP_PATH"
    log ""
    log "--- Database Info ---"
    log "Database name: $DATABASE_IMPORT_NAME"
    log "Active logs table: $ACTIVE_LOG_TABLE"
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
# SECTION 6: ACTIVE LOGS BACKUP & TRUNCATE (PARALLEL)
################################################################################

# ============ 6.1: Export Active Logs ============
# Backup bảng active_logs trước khi xóa
# Chạy background để tối ưu thời gian
backup_active_logs() {
    log "Exporting active_logs table..."
    
    # Dump bảng active_logs ra file SQL
    $MYSQL_DUMP "$DATABASE_IMPORT_NAME" "$ACTIVE_LOG_TABLE" > "$ACTIVE_LOG_SQL_PATH" \
        || { log_error "Failed to dump active_logs"; return 1; }
    
    log_success "Active logs exported: $ACTIVE_LOG_SQL_PATH"
}

# ============ 6.2: Compress Active Logs ============
# Nén file active logs để tiết kiệm dung lượng
compress_active_logs() {
    log "Compressing active_logs..."
    
    zip -j -q "$DOWNLOADS_DIR/$ACTIVE_LOG_NAME.zip" "$ACTIVE_LOG_SQL_PATH" \
        || { log_error "Failed to compress active_logs"; return 1; }
    
    log_success "Active logs compressed: $DOWNLOADS_DIR/$ACTIVE_LOG_NAME.zip"
}

# ============ 6.3: Truncate Active Logs ============
# Xóa dữ liệu cũ (không xóa structure)
# Dùng TRUNCATE (nhanh hơn DELETE) vì không cần log từng row
truncate_active_logs() {
    log "Truncating active_logs table..."
    
    $MYSQL_LOGIN -e "USE $DATABASE_IMPORT_NAME; TRUNCATE TABLE $ACTIVE_LOG_TABLE;" \
        || { log_error "Failed to truncate active_logs"; return 1; }
    
    log_success "Active logs truncated"
}

# ============ 6.4: Parallel Execution ============
# Thực thi backup & truncate song song để tiết kiệm thời gian
# Thay vì: Dump (10s) + Zip (5s) + Truncate (2s) = 17s
# Giờ là: Max(Dump, Zip+Truncate) ≈ 10s
handle_active_logs_parallel() {
    log "=========================================="
    log "Processing active_logs (parallel mode)"
    log "=========================================="
    
    # Chạy backup background
    backup_active_logs &
    BACKUP_PID=$!
    
    # Chờ backup hoàn tất
    wait $BACKUP_PID
    
    # Chạy compress và truncate song song
    compress_active_logs &
    COMPRESS_PID=$!
    
    truncate_active_logs &
    TRUNCATE_PID=$!
    
    # Chờ cả hai hoàn tất
    wait $COMPRESS_PID $TRUNCATE_PID
    
    log_success "Active logs processing completed"
}

################################################################################
# SECTION 7: DATA MASKING
################################################################################

# ============ 7.1: Import Masked Data ============
# Import dữ liệu mask (ẩn thông tin nhạy cảm)
# Đây là bước quan trọng để bảo vệ dữ liệu thực trong môi trường dev
import_masked_data() {
    log "Importing masked/fake data for sensitive columns..."
    
    $MYSQL_LOGIN "$DATABASE_IMPORT_NAME" < "$SQL_MASK_FILE_PATH" \
        || { log_error "Failed to import masked data"; return 1; }
    
    log_success "Masked data imported successfully"
}

################################################################################
# SECTION 8: FINAL DATABASE EXPORT & COMPRESSION
################################################################################

# ============ 8.1: Export Database with Optimization ============
# Dump toàn bộ database với các flag tối ưu cho file lớn
export_database() {
    log "Exporting database with optimizations..."
    
    # Giải thích các flag:
    # --single-transaction: Snapshot consistency không lock table
    # --quick: Dump từng row thay vì load hết vào memory
    # --lock-tables=false: Không lock, giúp app vẫn hoạt động
    # --max_allowed_packet: Handle large BLOB/TEXT data
    $MYSQL_DUMP \
        --single-transaction \
        --quick \
        --lock-tables=false \
        --max_allowed_packet=256M \
        "$DATABASE_IMPORT_NAME" > "${DATABASE_EXPORT_PATH}.sql" \
        || { log_error "Failed to export database"; return 1; }
    
    local export_size=$(stat -f%z "${DATABASE_EXPORT_PATH}.sql" 2>/dev/null || echo 0)
    log_success "Database exported: $(echo "scale=2; $export_size / 1024 / 1024" | bc) MB"
}

# ============ 8.2: Compress Database ============
# Nén file SQL để giảm dung lượng 60-80% tùy dữ liệu
compress_database() {
    log "Compressing database export..."
    
    local original_size=$(stat -f%z "${DATABASE_EXPORT_PATH}.sql" 2>/dev/null || echo 0)
    
    zip -j -q "$FINAL_ZIP_PATH" "${DATABASE_EXPORT_PATH}.sql" \
        || { log_error "Failed to compress database"; return 1; }
    
    local compressed_size=$(stat -f%z "$FINAL_ZIP_PATH" 2>/dev/null || echo 0)
    local ratio=$(echo "scale=2; $original_size / $compressed_size" | bc)
    
    # Thêm vào temp files để cleanup
    TEMP_FILES+=("${DATABASE_EXPORT_PATH}.sql")
    
    log_success "Database compressed: $(echo "scale=2; $compressed_size / 1024 / 1024" | bc) MB (${ratio}x compression)"
}

################################################################################
# SECTION 9: ENVIRONMENT FILE UPDATE
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
    local final_db_size=$(stat -f%z "$FINAL_ZIP_PATH" 2>/dev/null || echo 0)
    local completion_time=$(date '+%Y-%m-%dT%H:%M:%S')
    
    log "=========================================="
    log_success "All tasks completed successfully!"
    log "=========================================="
    log ""
    log "📊 Final Summary:"
    log "   - Database name: $DATABASE_IMPORT_NAME"
    log "   - Export file: $FINAL_ZIP_PATH"
    log "   - Export size: $(echo "scale=2; $final_db_size / 1024 / 1024" | bc) MB"
    log "   - Completion time: $completion_time"
    log "   - Log file: $LOG_FILE"
    log ""
    log "✅ Next Steps:"
    log "   1. Verify $TIC_WEB_DIR/.env has correct DB_DATABASE"
    log "   2. Run: php artisan migrate (if needed)"
    log "   3. Run: php artisan seed (if needed)"
    log ""
    log "=========================================="
}

################################################################################
# SECTION 12: MAIN EXECUTION FLOW
################################################################################

# ============ 12.1: Main Function ============
# Kết hợp tất cả các bước lại thành một quy trình hoàn chỉnh
main() {
    log "=========================================="
    log "Starting Database Generation Script"
    log "=========================================="
    
    # Step 1: Kiểm tra prerequisites
    run_prerequisite_checks || exit 1
    
    # Step 2: Hiển thị overview
    print_overview
    
    # Step 3: Import database gốc
    log "=========================================="
    log "PHASE 1: Database Import"
    log "=========================================="
    measure_time "Drop & Create Database" "drop_and_create_database" || exit 1
    measure_time "Import SQL Data" "import_sql_data" || exit 1
    measure_time "Validate Import" "validate_import" || exit 1
    
    # Step 4: Xử lý active logs
    log "=========================================="
    log "PHASE 2: Active Logs Processing"
    log "=========================================="
    measure_time "Handle Active Logs (Parallel)" "handle_active_logs_parallel" || exit 1
    
    # Step 5: Import dữ liệu mask
    log "=========================================="
    log "PHASE 3: Data Masking"
    log "=========================================="
    measure_time "Import Masked Data" "import_masked_data" || exit 1
    
    # Step 6: Export & compress
    log "=========================================="
    log "PHASE 4: Database Export & Compression"
    log "=========================================="
    measure_time "Export Database" "export_database" || exit 1
    measure_time "Compress Database" "compress_database" || exit 1
    
    # Step 7: Cập nhật environment
    log "=========================================="
    log "PHASE 5: Environment Configuration"
    log "=========================================="
    measure_time "Update .env File" "update_env_file" || exit 1
    
    # Step 8: Optimize Laravel
    log "=========================================="
    log "PHASE 6: Laravel Optimization"
    log "=========================================="
    measure_time "Optimize Laravel" "optimize_laravel" || exit 1
    
    # Step 9: Print summary
    print_completion_summary
}

################################################################################
# SCRIPT EXECUTION
################################################################################

# Chỉ chạy main nếu script được gọi trực tiếp (không được source)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi