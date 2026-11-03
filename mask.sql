-- data mask
UPDATE users
SET password='$2y$10$hJFWXhpdpqK.bu1hnflSCuMQfdX2XQ10sAnJofS7V6J4Jm3ZQZh.e';

-- delete large data
delete from user_alerts where user_alerts.alert_id in (select id from alerts
where alerts.date_entered < DATE_ADD(CURDATE(), INTERVAL -15 DAY));
delete
from alerts
where date_entered < DATE_ADD(CURDATE(), INTERVAL -15 DAY);

delete
from active_logs
where call_time < DATE_ADD(CURDATE(), INTERVAL -15 DAY);

update users
set users.phone = CONCAT('0911', LPAD(FLOOR(RAND() * 1000000), 6, '0'));
update users
set users.zalo = CONCAT('0911', LPAD(FLOOR(RAND() * 1000000), 6, '0'));
update users
set users.facebook = CONCAT('https://www.facebook.com/', LEFT(UUID(), 8));
update users
set users.birthday = DATE_ADD(DATE_ADD(users.birthday, INTERVAL FLOOR(10 + RAND() * 90) DAY), INTERVAL FLOOR(2 + RAND() * 3) YEAR);
update users
set users.address = CONCAT(
        'Số ', FLOOR(1 + RAND() * 999), ' ',
        ELT(FLOOR(1 + RAND() * 10),
            'Trần Phú, Phường Điện Biên, Quận Ba Đình, Hà Nội',
            'Lê Lợi, Phường Bến Nghé, Quận 1, TP Hồ Chí Minh',
            'Nguyễn Văn Linh, Phường Thạc Gián, Quận Thanh Khê, Đà Nẵng',
            'Trần Phú, Phường Máy Tơ, Quận Ngô Quyền, Hải Phòng',
            'Trần Hưng Đạo, Phường An Phú, Quận Ninh Kiều, Cần Thơ',
            'Nguyễn Huệ, Phường Bến Thành, Quận 1, TP Hồ Chí Minh',
            'Lý Thường Kiệt, Phường Đồng Xuân, Quận Hoàn Kiếm, Hà Nội',
            'Phan Chu Trinh, Phường Hải Châu 1, Quận Hải Châu, Đà Nẵng',
            'Lê Duẩn, Phường Chính Gián, Quận Thanh Khê, Đà Nẵng',
            'Ngô Quyền, Phường Máy Chai, Quận Ngô Quyền, Hải Phòng'
        ));
update customers
set customers.phone = CONCAT('0911', LPAD(FLOOR(RAND() * 1000000), 6, '0'));
update customers
set customers.zalo = CONCAT('0911', LPAD(FLOOR(RAND() * 1000000), 6, '0'));
update customers
set customers.facebook = CONCAT('https://www.facebook.com/', LEFT(UUID(), 8));
update customers
set customers.birthday = DATE_ADD(DATE_ADD(customers.birthday, INTERVAL FLOOR(10 + RAND() * 90) DAY), INTERVAL FLOOR(2 + RAND() * 3) YEAR);
update customers
set customers.address = CONCAT(
        'Số ', FLOOR(1 + RAND() * 999), ' ',
        ELT(FLOOR(1 + RAND() * 10),
            'Trần Phú, Phường Điện Biên, Quận Ba Đình, Hà Nội',
            'Lê Lợi, Phường Bến Nghé, Quận 1, TP Hồ Chí Minh',
            'Nguyễn Văn Linh, Phường Thạc Gián, Quận Thanh Khê, Đà Nẵng',
            'Trần Phú, Phường Máy Tơ, Quận Ngô Quyền, Hải Phòng',
            'Trần Hưng Đạo, Phường An Phú, Quận Ninh Kiều, Cần Thơ',
            'Nguyễn Huệ, Phường Bến Thành, Quận 1, TP Hồ Chí Minh',
            'Lý Thường Kiệt, Phường Đồng Xuân, Quận Hoàn Kiếm, Hà Nội',
            'Phan Chu Trinh, Phường Hải Châu 1, Quận Hải Châu, Đà Nẵng',
            'Lê Duẩn, Phường Chính Gián, Quận Thanh Khê, Đà Nẵng',
            'Ngô Quyền, Phường Máy Chai, Quận Ngô Quyền, Hải Phòng'
        ));
update customers
set customers.passport_code = SUBSTRING(SHA2(RAND(), 256), 1, 9);
UPDATE customers
SET customers.passport_issued_date =
        CASE
            -- First convert from DD/MM/YYYY format if needed
            WHEN customers.passport_issued_date LIKE '__/__/____' THEN
                -- Use safer range for subtraction to avoid overflow
                DATE_SUB(
                        DATE_SUB(
                                STR_TO_DATE(customers.passport_issued_date, '%d/%m/%Y'),
                                INTERVAL FLOOR(10 + RAND() * 30) DAY
                        ),
                        INTERVAL FLOOR(1 + RAND() * 2) YEAR
                )
            -- For dates already in correct format
            ELSE
                -- Use safer range for subtraction to avoid overflow
                DATE_SUB(
                        DATE_SUB(
                                customers.passport_issued_date,
                                INTERVAL FLOOR(10 + RAND() * 30) DAY
                        ),
                        INTERVAL FLOOR(1 + RAND() * 2) YEAR
                )
            END
WHERE customers.passport_issued_date IS NOT NULL
  AND customers.passport_issued_date > '1002-01-01';
update customers
set customers.passport_expiration = DATE_ADD(DATE_ADD(customers.passport_expiration, INTERVAL FLOOR(10 + RAND() * 90) DAY), INTERVAL FLOOR(2 + RAND() * 3) YEAR);

-- truncate _history tables
truncate table customers_history;
truncate table contacts_history;
truncate table contract_customers_history;
truncate table contracts_history;
truncate table	payment_slip_history;

-- data mask contact
update contacts
set contacts.phone = CONCAT('0911', LPAD(FLOOR(RAND() * 1000000), 6, '0'));
update contacts
set contacts.zalo = CONCAT('0911', LPAD(FLOOR(RAND() * 1000000), 6, '0'));
update contacts
set contacts.facebook = CONCAT('https://www.facebook.com/', LEFT(UUID(), 8));
update contacts
set contacts.birthday = DATE_ADD(DATE_ADD(contacts.birthday, INTERVAL FLOOR(10 + RAND() * 90) DAY), INTERVAL FLOOR(2 + RAND() * 3) YEAR);
update contacts
set contacts.address = CONCAT(
        'Số ', FLOOR(1 + RAND() * 999), ' ',
        ELT(FLOOR(1 + RAND() * 10),
            'Trần Phú, Phường Điện Biên, Quận Ba Đình, Hà Nội',
            'Lê Lợi, Phường Bến Nghé, Quận 1, TP Hồ Chí Minh',
            'Nguyễn Văn Linh, Phường Thạc Gián, Quận Thanh Khê, Đà Nẵng',
            'Trần Phú, Phường Máy Tơ, Quận Ngô Quyền, Hải Phòng',
            'Trần Hưng Đạo, Phường An Phú, Quận Ninh Kiều, Cần Thơ',
            'Nguyễn Huệ, Phường Bến Thành, Quận 1, TP Hồ Chí Minh',
            'Lý Thường Kiệt, Phường Đồng Xuân, Quận Hoàn Kiếm, Hà Nội',
            'Phan Chu Trinh, Phường Hải Châu 1, Quận Hải Châu, Đà Nẵng',
            'Lê Duẩn, Phường Chính Gián, Quận Thanh Khê, Đà Nẵng',
            'Ngô Quyền, Phường Máy Chai, Quận Ngô Quyền, Hải Phòng'
        ));
update contacts
set contacts.email = CONCAT(LEFT(UUID(), 8), '@outlook.com');

-- data mask contract_customers
update contract_customers
set contract_customers.phone = CONCAT('0911', LPAD(FLOOR(RAND() * 1000000), 6, '0'));
UPDATE contract_customers
SET contract_customers.birthday = DATE_ADD(
        DATE_ADD(
                CASE
                    WHEN contract_customers.birthday LIKE '__/__/____'
                        THEN STR_TO_DATE(contract_customers.birthday, '%d/%m/%Y')
                    ELSE contract_customers.birthday
                    END,
                INTERVAL FLOOR(10 + RAND() * 90) DAY
        ),
        INTERVAL FLOOR(2 + RAND() * 3) YEAR
                                  )
WHERE contract_customers.birthday IS NOT NULL;
update contract_customers
set contract_customers.passport_code = SUBSTRING(SHA2(RAND(), 256), 1, 9);
UPDATE contract_customers
SET contract_customers.passport_expiration = DATE_ADD(
        DATE_ADD(
                CASE
                    WHEN contract_customers.passport_expiration LIKE '__/__/____'
                        THEN STR_TO_DATE(contract_customers.passport_expiration, '%d/%m/%Y')
                    ELSE contract_customers.passport_expiration
                    END,
                INTERVAL FLOOR(10 + RAND() * 90) DAY
        ),
        INTERVAL FLOOR(2 + RAND() * 3) YEAR
                                             )
WHERE contract_customers.passport_expiration IS NOT NULL;