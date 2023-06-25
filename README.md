# copy env-local ---> .env
cp env-local .env

# change folder source code in env
APP_CODE_PATH_HOST=...

# start build container by sh file
./start.sh


# Generate CA key and cert:
openssl genrsa -out rootCA.key 2048
openssl req -x509 -new -key rootCA.key -days 3650 -out rootCA.pem \
-subj '/C=AA/ST=AA/L=AA/O=AA Ltd/OU=AA/CN=AA/emailAddress=aa@aa.com'

# Generate client key and csr:
openssl genrsa -out client1.key 2048
openssl req -new -key client1.key -out client1.csr \
-subj '/C=BB/ST=BB/L=BB/O=BB Ltd/OU=BB/CN=BB/emailAddress=bb@bb.com'

# Generate client cert signed with CA cert:
openssl x509 -req -days 365 -CA rootCA.pem -CAkey rootCA.key \
-CAcreateserial -CAserial serial -in client1.csr -out client1.pem
Of course you can set your config file to use right CA files and use the 'openssl ca' tool after that.

# You can verify your certificate like this:
openssl verify -verbose -CAfile rootCA.pem client1.pem


# Command common
## Command copy file between docker container and local machine
`Nếu như muốn copy file từ trong container docker ra ngoài máy thật thì đường dẫn của file trong container docker sẻ để phía trước, đường dẫn tới máy thật phía sau. Và nếu như muốn copy ngược lại thì đổi vị trí của 2 đường dẫn`
> docker cp CONTAINER_NAME:/`đường_dẫn_file_trong_container`**[_khoảng trắng_]**`đường_dẫn_lưu_file_trong_máy_thật`


# Cách chạy file tạo SSL cho doamin local
`Trong docker có tạo 1 file tên là ssl.sh, file này có nhiệm vụ tạo ra các chứng chỉ ssl cho domain local nam đang muốn tạo`
`B1: chạy script sh: `
> Command:
~~~
./ssl/sh domain-local-name.local
~~~

## Mô tả:
- Trong file này sẽ thực hiện 2 công việc chính, 1 là tạo ra root CA file này sẽ được tạo trong thư mục `/ca-certificates/`, CHÚ Ý: trong lần tạo rootCA đầu tiên password phrase (quandn) của bước này là phải nhớ để sau này tạo cho các domain khác, nó sẽ tạo ra 3 file **.key**, **.pem** và **.srl**
- Nếu như rootCA đã có rồi hoặc sau khi tạo rootCA sẽ tạo certificates cho `domain-local-name`, cuối cùng sẽ cần nhập mật khẩu của rootCA (quandn) trong lần tạo trên để có thể tạo được

`B2: Thêm cấu hình trong file nginx.config cho domain name`
> Example file nginx config:
~~~
server {
    listen 80;
    server_name devlife.local;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    ssl_certificate /etc/nginx/ssl/devlife.local.crt;
    ssl_certificate_key /etc/nginx/ssl/devlife.local.key;

    server_name devlife.local;
    root /var/www/devlife/dist;
    index index.php index.html index.htm;
    
    location / {
         try_files $uri $uri/ /index.php$is_args$args;
    }

    location ~ \.php$ {
        try_files $uri /index.php =404;
        fastcgi_pass php-upstream;
        fastcgi_index index.php;
        fastcgi_buffers 16 16k;
        fastcgi_buffer_size 32k;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        #fixes timeouts
        fastcgi_read_timeout 600;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }

    location /.well-known/acme-challenge/ {
        root /var/www/letsencrypt/;
        log_not_found off;
    }

    error_log /var/log/nginx/devlife-error.log;
    access_log /var/log/nginx/devlife-access.log;
}

~~~

`B3: Import rootCA.pem vào trình duyệt`
> Example file nginx config:
~~~
Trong trình duyệt tìm mục certificates và import rootCA.pem vào trong trình duyệt, tùy máy tính sẽ có cách import khác nhau
~~~

