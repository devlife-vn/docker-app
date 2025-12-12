#!/bin/bash
set -e  # Exit on error

CURRENT_DATE=$(date +%d%m%Y)
PERMISSION_NAME="update_permission_${CURRENT_DATE}"
EXPORT_PATH=~/Downloads/${PERMISSION_NAME}.sql

# Check if the file already exists and add timestamp if it does
if [ -f "${EXPORT_PATH}" ]; then
    TIMESTAMP=$(date +%H%M%S)
    PERMISSION_NAME="update_permission_${CURRENT_DATE}_${TIMESTAMP}"
    EXPORT_PATH=~/Downloads/${PERMISSION_NAME}.sql
    echo "File already exists. Updated export path with timestamp."
fi

echo "Exporting permissions to ${EXPORT_PATH}..."
mysqldump -u root -psecret tic_role permissions roles_permissions > "${EXPORT_PATH}"

# Check if export was successful
if [ -f "${EXPORT_PATH}" ] && [ -s "${EXPORT_PATH}" ]; then
    echo "Permission export completed successfully."
else
    echo "Failed to export permissions."
    exit 1
fi