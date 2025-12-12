#!/bin/bash
# UPDATE users SET `password`='$2y$10$hJFWXhpdpqK.bu1hnflSCuMQfdX2XQ10sAnJofS7V6J4Jm3ZQZh.e';

# Get database name from command line argument
if [ $# -eq 0 ]; then
    echo "Please provide database name as argument"
    exit 1
fi

DATABASE_IMPORT_NAME=$1
CURRENT_DATE=$(date +%d_%m_%Y)

# ================/CHỈ CẦN SỬA 2 THÔNG TIN NÀY/====================
DATABASE_EXPORT_NAME="${CURRENT_DATE}_database"
MYSQL_LOGIN="mysql -u root -psecret"
MYSQL_DUMP="mysqldump -u root -psecret"
DATABASE_EXPORT_PATH_NAME=/Users/quandn/Downloads/${DATABASE_EXPORT_NAME}

echo "Dumping database..."
$MYSQL_DUMP $DATABASE_IMPORT_NAME > ${DATABASE_EXPORT_PATH_NAME}.sql

echo "Compressing database dump..."
zip -j ${DATABASE_EXPORT_PATH_NAME}.zip ${DATABASE_EXPORT_PATH_NAME}.sql

echo "Cleaning up..."
rm -f ${DATABASE_EXPORT_PATH_NAME}.sql

echo "Database export completed: ${DATABASE_EXPORT_PATH_NAME}.zip"