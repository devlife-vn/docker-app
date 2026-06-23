#!/bin/bash

set -euo pipefail

ENV_FILE="/Users/quandn/quandn/web/tic/.env"
TIC_WEB_DIR="/Users/quandn/quandn/web/tic"
DB_ORIGINAL="db_tic"
DB_ROLE="db_role"

restore_db() {
    sed -i '' -E "s|^DB_DATABASE=.*|DB_DATABASE=$DB_ORIGINAL|" "$ENV_FILE"
    echo "DB_DATABASE restored to $DB_ORIGINAL."
}

trap restore_db EXIT

# ============ Đổi DB_DATABASE sang db_role ============
echo "Switching DB_DATABASE to $DB_ROLE..."
sed -i '' -E "s|^DB_DATABASE=.*|DB_DATABASE=$DB_ROLE|" "$ENV_FILE"
echo "Done."

# ============ Chạy migrate:fresh --seed + dump + open ============
echo "Running migrate:fresh --seed..."
cd "$TIC_WEB_DIR"
SQL_FILE=~/Downloads/update_permission_$(date +%Y%m%d_%H%M%S).sql
php artisan migrate:fresh --seed && \
    mysqldump -u root -proot db_role permissions roles_permissions > "$SQL_FILE" && \
    open ~/Downloads/ && \
    importsql "$SQL_FILE"
