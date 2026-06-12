#!/bin/bash

################################################################################
# Retail Database Import Script
# Purpose: Import DB, mask sensitive data, update .env
# Author: Development Team
# Version: 1.0
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
RETAIL_WEB_DIR="/Users/quandn/quandn/web/retail"

# ============ Database Configuration ============
DATABASE_IMPORT_NAME="retail"
ACTIVE_LOG_TABLE="active_logs"
ACTIVE_LOG_NAME="${CURRENT_DATE}_${ACTIVE_LOG_TABLE}"

# ============ File Paths ============
SQL_FILE_PATH=""  # Sẽ được tìm tự động
SQL_MASK_FILE_PATH="$SCRIPTS_DIR/mask_retail.sql"
ACTIVE_LOG_SQL_PATH="$DOWNLOADS_DIR/$ACTIVE_LOG_NAME.sql"
ENV_FILE="$RETAIL_WEB_DIR/.env"

# ============ MySQL Configuration ============
MYSQL_USER="root"
MYSQL_PASS="root"
MYSQL_LOGIN="mysql -u $MYSQL_USER -p$MYSQL_PASS --batch --silent"
MYSQL_DUMP="mysqldump -u $MYSQL_USER -p$MYSQL_PASS"

# ============ Logging Configuration ============
LOG_FILE="$DOWNLOADS_DIR/genretaildb_${CURRENT_DATE}_${TIME_STAMP}.log"

################################################################################
# SECTION 2: UTILITY FUNCTIONS
################################################################################

printCurrentPath() {
    echo "Script location: $(realpath "$0")"
}

alert_success() {
    osascript -e 'display notification "Retail database generation completed successfully!" with title "Success" sound name "Glass"'
}

# ============ Logging Functions ============
log() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${BLUE}[${timestamp}]${NC} ${message}" | tee -a "$LOG_FILE"
}

log_error() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${RED}[ERROR]${NC} [${timestamp}] ${message}" | tee -a "$LOG_FILE" >&2
}

log_success() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${GREEN}[SUCCESS]${NC} [${timestamp}] ${message}" | tee -a "$LOG_FILE"
}

log_warning() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${YELLOW}[WARNING]${NC} [${timestamp}] ${message}" | tee -a "$LOG_FILE"
}

# ============ Performance Tracking ============
measure_time() {
    local task_name="$1"
    shift

    log "Starting: $task_name"
    local start_time=$(date +%s%N)

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
cleanup() {
    local exit_code=$?

    if [ $exit_code -ne 0 ]; then
        log_error "Script failed. Log file preserved for debugging: $LOG_FILE"
    else
        log "Performing cleanup..."
        # Xóa log file khi thành công
        rm -f "$LOG_FILE"
        log_success "Log file removed (successful run)"
    fi

    # Xóa active_logs.sql nếu vẫn còn
    cleanup_active_logs_sql

    exit $exit_code
}

trap cleanup EXIT
trap 'log_error "Error at line $LINENO"; exit 1' ERR

# ============ Specific Cleanup ============
cleanup_active_logs_sql() {
    if [ -f "$ACTIVE_LOG_SQL_PATH" ]; then
        rm -f "$ACTIVE_LOG_SQL_PATH"
        log "Cleaned up: $ACTIVE_LOG_SQL_PATH"
    fi
}

################################################################################
# SECTION 3: PREREQUISITE CHECKS
################################################################################

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

# ============ Find Latest SQL File ============
# Tự động tìm file sgtapidb*.sql mới nhất (xử lý file có số thứ tự như sgtapidb (1).sql)
find_latest_sql_file() {
    log "Searching for latest sgtapidb SQL file in $DOWNLOADS_DIR..."

    # Tìm tất cả file sgtapidb*.sql (bao gồm cả file có số thứ tự)
    # Sắp xếp theo tên (descending) để lấy file mới nhất
    local latest_file
    latest_file=$(find "$DOWNLOADS_DIR" -maxdepth 1 -type f -name "sgtapidb*.sql" 2>/dev/null | sort -r | head -1)

    if [ -z "$latest_file" ]; then
        log_error "No sgtapidb*.sql file found in $DOWNLOADS_DIR"
        log_error "Expected pattern: sgtapidb.sql, sgtapidb (1).sql, sgtapidb (2).sql, ..."
        return 1
    fi

    # Validate file không rỗng
    if [ ! -s "$latest_file" ]; then
        log_error "SQL file is empty: $latest_file"
        return 1
    fi

    SQL_FILE_PATH="$latest_file"
    log_success "Found SQL file: $(basename "$SQL_FILE_PATH")"
    log_success "SQL file size: $(echo "scale=2; $(stat -f%z "$SQL_FILE_PATH") / 1024 / 1024" | bc) MB"
}

check_required_files() {
    log "Checking required files..."

    # Tìm file SQL mới nhất trước
    find_latest_sql_file || return 1

    local files_to_check=(
        "$SQL_MASK_FILE_PATH:SQL mask file"
        "$ENV_FILE:Laravel .env file"
        "$SQL_FILE_PATH:Daily SQL file"
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

    # Validate nội dung file SQL
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

check_directory_access() {
    log "Checking directory access..."

    local dirs_to_check=(
        "$DOWNLOADS_DIR"
        "$RETAIL_WEB_DIR"
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

check_disk_space() {
    log "Checking available disk space..."

    local sql_file_size=$(stat -f%z "$SQL_FILE_PATH" 2>/dev/null || echo 0)
    local required_space=$((sql_file_size * 3))

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

print_overview() {
    log "=========================================="
    log "Retail Database Import Overview"
    log "=========================================="
    log "Date: $CURRENT_DATE"
    log "Time: $TIME_STAMP"
    log ""
    log "--- File Paths ---"
    log "SQL import: $(basename "$SQL_FILE_PATH")"
    log "SQL mask: $SQL_MASK_FILE_PATH"
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

drop_and_create_database() {
    log "Preparing database: $DATABASE_IMPORT_NAME"

    $MYSQL_LOGIN -e "DROP DATABASE IF EXISTS $DATABASE_IMPORT_NAME;" \
        || { log_error "Failed to drop database"; return 1; }

    $MYSQL_LOGIN -e "CREATE DATABASE $DATABASE_IMPORT_NAME;" \
        || { log_error "Failed to create database"; return 1; }

    log_success "Database prepared"
}

import_sql_data() {
    log "Importing SQL data into $DATABASE_IMPORT_NAME..."

    if command -v pv &>/dev/null; then
        pv "$SQL_FILE_PATH" | $MYSQL_LOGIN $DATABASE_IMPORT_NAME \
            || { log_error "SQL import failed"; return 1; }
    else
        $MYSQL_LOGIN $DATABASE_IMPORT_NAME < "$SQL_FILE_PATH" \
            || { log_error "SQL import failed"; return 1; }
    fi

    log_success "SQL data imported successfully"
}

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

backup_active_logs() {
    log "Exporting active_logs table..."

    $MYSQL_DUMP "$DATABASE_IMPORT_NAME" "$ACTIVE_LOG_TABLE" > "$ACTIVE_LOG_SQL_PATH" \
        || { log_error "Failed to dump active_logs"; return 1; }

    log_success "Active logs exported: $ACTIVE_LOG_SQL_PATH"
}

compress_active_logs() {
    log "Compressing active_logs..."

    zip -j -q "$DOWNLOADS_DIR/$ACTIVE_LOG_NAME.zip" "$ACTIVE_LOG_SQL_PATH" \
        || { log_error "Failed to compress active_logs"; return 1; }

    log_success "Active logs compressed: $DOWNLOADS_DIR/$ACTIVE_LOG_NAME.zip"
}

truncate_active_logs() {
    log "Truncating active_logs table..."

    $MYSQL_LOGIN -e "USE $DATABASE_IMPORT_NAME; TRUNCATE TABLE $ACTIVE_LOG_TABLE;" \
        || { log_error "Failed to truncate active_logs"; return 1; }

    log_success "Active logs truncated"
}

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
# SECTION 7: ENVIRONMENT FILE UPDATE
################################################################################

update_env_file() {
    log "Updating .env file with new database name..."

    if [ ! -f "$ENV_FILE" ]; then
        log_error ".env file not found: $ENV_FILE"
        return 1
    fi

    # Backup .env trước khi sửa
    cp "$ENV_FILE" "${ENV_FILE}.backup"
    log "Backup created: ${ENV_FILE}.backup"

    # Check xem DB_DATABASE đã tồn tại chưa
    if grep -q "^DB_DATABASE=" "$ENV_FILE"; then
        sed -i '' -E "s|^DB_DATABASE=.*|DB_DATABASE=$DATABASE_IMPORT_NAME|" "$ENV_FILE"
        log "Updated existing DB_DATABASE variable"
    else
        echo "" >> "$ENV_FILE"
        echo "DB_DATABASE=$DATABASE_IMPORT_NAME" >> "$ENV_FILE"
        log "Added new DB_DATABASE variable"
    fi

    log_success ".env file updated successfully"
}

################################################################################
# SECTION 8: FINAL SUMMARY & COMPLETION
################################################################################

print_completion_summary() {
    local completion_time=$(date '+%Y-%m-%dT%H:%M:%S')

    log "=========================================="
    log_success "All tasks completed successfully!"
    log "=========================================="
    log ""
    log "📊 Final Summary:"
    log "   - Database name: $DATABASE_IMPORT_NAME"
    log "   - Import file: $(basename "$SQL_FILE_PATH")"
    log "   - Completion time: $completion_time"
    log ""
    log "✅ Next Steps:"
    log "   1. Verify $RETAIL_WEB_DIR/.env has correct DB_DATABASE"
    log "   2. Run: php artisan migrate (if needed)"
    log "   3. Run: php artisan seed (if needed)"
    log ""
    log "=========================================="
}

################################################################################
# SECTION 9: MAIN EXECUTION FLOW
################################################################################

main() {
    log "=========================================="
    log "Starting Retail Database Import Script"
    log "=========================================="
    printCurrentPath

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

    # Step 5: Cập nhật environment
    log "=========================================="
    log "PHASE 3: Environment Configuration"
    log "=========================================="
    measure_time "Update .env File" "update_env_file" || exit 1

    # Step 6: Print summary
    print_completion_summary

    # Step 8: Gửi thông báo macOS
    alert_success
}

################################################################################
# SCRIPT EXECUTION
################################################################################

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
