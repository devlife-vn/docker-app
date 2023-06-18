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

