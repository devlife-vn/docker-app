#!/bin/bash

################################################################################
# Download Folder Cleanup Script
# Purpose: Clean up unnecessary files in Downloads folder
# Author: Development Team
# Version: 2.0
################################################################################

set -euo pipefail

################################################################################
# SECTION 1: CONFIGURATION & VARIABLES
################################################################################

# Color codes for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Download timestamp
CURRENT_DATE=$(date +%Y_%m_%d)
TIME_STAMP=$(date +%H%M%S)

# ============ Path Configuration ============
DOWNLOADS_DIR="/Users/quandn/Downloads"
SCRIPTS_DIR="/Users/quandn/quandn"

# ============ File Paths ============
LOG_FILE="$DOWNLOADS_DIR/clean_download_${CURRENT_DATE}_${TIME_STAMP}.log"

# ============ File Patterns to Delete ============
# Directories
DIRS_TO_DELETE=(
    "Screenshot*"
    "QUYET_TOAN_*"
    "THEO_DOI_NGAN_SACH*"
    "Danh_sach_bookin*"
    "quan-ly-doan*"
    "Danh_sach_lich_khoi_hanh_*"
    "LOI_NHUAN_TOUR*"
    "Seri\ tổng_template*"
    "*landing_page_*"
    "*landing_page_desktop_image*"
)

# Files by pattern
FILES_TO_DELETE=(
    # Tour/Contract related
    "*-HDLK*"
    "*-PCGKT*"
    "*-HDKL*"
    "*danh-sach-nguoi-dung*"
    "*ma-bao-luu-*"
    "* - SERIES  *"
    "*-air-template*"
    "*monthly_bonus_*"
    "*update_permission_*"
    "*thong_tin_hop_dong_bi_tra_lai*"
    "*doanh-thu-nguoi-dung*"
    "*reservation-code*"
    "*TICVietnam_production*"
    "*DOANH SỐ THÁNG*"
    "*sample*"
    "THEO_DOI_NGAN_SACH*"
    "QUYET_TOAN_TOUR*"
    "clean_download_*"
    "gen_db_*"
    "genretaildb_*"
    "Phieu-chi-*"
    "*-HDDR*"
    "*-HDLAND*"
    "*-HDVMB*"
    "*-HĐKLTT*"
    "*danh-sach-to-chuc*"
    "*monthly_bonus*"
    "*CTY_TNHH_TM_DL_SAI_GON_THOI_DA*"
    # Image/Document related
    "image_*"
    "Namelist*"
    "Namelist_*"
    "NameList_*"
    "HO_CHIEU_*"
    "SO_TOUR*"

    # Payment/Financial
    "danh-sach-thanh-toan*"

    # Extensions to delete
    "*.csv"
    "*.ods"
    "*.sql"
    "*.svg"
    "*.txt"
    "*.sh"
)

# Counters for summary
DIRS_DELETED=0
FILES_DELETED=0

################################################################################
# SECTION 2: UTILITY FUNCTIONS
################################################################################

printCurrentPath() {
    echo "Script location: $(realpath "$0")"
}

alert_success() {
    osascript -e 'display notification "Download folder cleanup completed successfully!" with title "Success" sound name "Glass"'
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

# ============ Error Handling & Cleanup ============
cleanup() {
    local exit_code=$?

    if [ $exit_code -ne 0 ]; then
        log_error "Script failed. Log file preserved for debugging: $LOG_FILE"
    else
        log_success "All cleanup completed successfully!"
        # Xóa log file khi thành công
        rm -f "$LOG_FILE"
        log_success "Log file removed (successful run)"
    fi

    exit $exit_code
}

trap cleanup EXIT
trap 'log_error "Error at line $LINENO"; exit 1' ERR

################################################################################
# SECTION 3: PREREQUISITE CHECKS
################################################################################

check_directory_access() {
    log "Checking directory access..."

    if [ ! -d "$DOWNLOADS_DIR" ]; then
        log_error "Directory not found: $DOWNLOADS_DIR"
        return 1
    fi

    if [ ! -w "$DOWNLOADS_DIR" ]; then
        log_error "No write permission: $DOWNLOADS_DIR"
        return 1
    fi

    log "Directory OK: $DOWNLOADS_DIR"
}

check_disk_space() {
    log "Checking available disk space..."

    local available_space=$(df "$DOWNLOADS_DIR" | awk 'NR==2 {print $4}' | awk '{print $1 * 1024}')
    log "Available space: $(echo "scale=2; $available_space / 1024 / 1024" | bc) MB"

    if [ $available_space -lt 10485760 ]; then  # 10MB minimum
        log_error "Insufficient disk space!"
        return 1
    fi

    log_success "Disk space check passed"
}

run_prerequisite_checks() {
    log "=========================================="
    log "Running prerequisite checks..."
    log "=========================================="

    check_directory_access || return 1
    check_disk_space || return 1

    log_success "All prerequisite checks passed!"
}

################################################################################
# SECTION 4: PRINT CONFIGURATION SUMMARY
################################################################################

print_overview() {
    log "=========================================="
    log "Download Folder Cleanup Overview"
    log "=========================================="
    log "Date: $CURRENT_DATE"
    log "Time: $TIME_STAMP"
    log ""
    log "--- Configuration ---"
    log "Downloads directory: $DOWNLOADS_DIR"
    log "Log file: $LOG_FILE"
    log ""
    log "--- Patterns to Delete ---"
    log "Directories: ${#DIRS_TO_DELETE[@]}"
    log "Files: ${#FILES_TO_DELETE[@]}"
    log ""
    log "=========================================="
}

################################################################################
# SECTION 5: CLEANUP FUNCTIONS
################################################################################

# ============ 5.1: Delete Directories ============
delete_directories() {
    log "=========================================="
    log "Cleaning directories..."
    log "=========================================="

    for dir_pattern in "${DIRS_TO_DELETE[@]}"; do
        local count=0
        while IFS= read -r -d '' dir; do
            if [ -d "$dir" ]; then
                log "Moving directory to Trash: $(basename "$dir")"
                move_to_trash "$dir" || return 1
                ((count++))
                ((DIRS_DELETED++))
            fi
        done < <(find "$DOWNLOADS_DIR" -maxdepth 1 -type d -name "$dir_pattern" -print0 2>/dev/null)

        [ $count -gt 0 ] && log_success "Removed $count directory(ies) matching: $dir_pattern"
    done

    log_success "Directory cleanup completed"
}

# ============ 5.2: Delete Files ============
delete_files() {
    log "=========================================="
    log "Cleaning files..."
    log "=========================================="

    for file_pattern in "${FILES_TO_DELETE[@]}"; do
        local count=0
        while IFS= read -r -d '' file; do
            if [ -f "$file" ]; then
                if [ "$file" = "$LOG_FILE" ]; then
                    continue
                fi
                log "Moving file to Trash: $(basename "$file")"
                move_to_trash "$file" || return 1
                ((count++))
                ((FILES_DELETED++))
            fi
        done < <(find "$DOWNLOADS_DIR" -maxdepth 1 -type f -name "$file_pattern" -print0 2>/dev/null)

        [ $count -gt 0 ] && log_success "Removed $count file(s) matching: $file_pattern"
    done

    log_success "File cleanup completed"
}

# ============ 5.3: Optional - Keep Recent Files ============
# Uncomment to keep files modified in last N days
# keep_recent_files() {
#     local days=7
#     log "Preserving files modified within last $days days..."
#
#     for pattern in "${FILES_TO_DELETE[@]}"; do
#         find "$DOWNLOADS_DIR" -maxdepth 1 -type f -name "$pattern" -mtime +"$days" -delete 2>/dev/null || true
#     done
# }

################################################################################
# SECTION 6: FINAL SUMMARY
################################################################################

print_completion_summary() {
    local cleanup_time=$(date '+%Y-%m-%dT%H:%M:%S')

    log "=========================================="
    log_success "All cleanup tasks completed!"
    log "=========================================="
    log ""
    log "📊 Summary:"
    log "   - Directories removed: $DIRS_DELETED"
    log "   - Files removed: $FILES_DELETED"
    log "   - Completion time: $cleanup_time"
    log ""
    log "=========================================="
}

################################################################################
# SECTION 7: MAIN EXECUTION FLOW
################################################################################

main() {
    log "=========================================="
    log "Starting Download Folder Cleanup Script"
    log "=========================================="
    printCurrentPath

    # Step 1: Kiểm tra prerequisites
    run_prerequisite_checks || exit 1

    # Step 2: Hiển thị overview
    print_overview

    # Step 3: Xóa directories
    delete_directories

    # Step 4: Xóa files
    delete_files

    # Step 5: Print summary
    print_completion_summary

    # Step 6: Gửi thông báo macOS
    alert_success
}

################################################################################
# SCRIPT EXECUTION
################################################################################

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
