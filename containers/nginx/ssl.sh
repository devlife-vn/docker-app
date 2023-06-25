NAME=$1


if [ ! -d "/etc/nginx/ssl/ca-certificates" ]; then
    mkdir /etc/nginx/ssl/ca-certificates;
fi

cd /etc/nginx/ssl/ca-certificates;
if [ ! -f "/etc/nginx/ssl/ca-certificates/rootCA.key" ]; then

    echo "Generating root ca certificate key"
    # Generate private key
    openssl genrsa -des3 -out rootCA.key 2048
    # Generate root certificate
    openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 825 -out rootCA.pem
fi

cd ..;

if [ ! -f /etc/nginx/ssl/$NAME.key ]; then
echo "Generating $NAME ca certificate key"

# Generate a private key
openssl genrsa -out /etc/nginx/ssl/$NAME.key 2048

# Create a certificate-signing request
openssl req -new -key /etc/nginx/ssl/$NAME.key -out /etc/nginx/ssl/$NAME.csr

# Create a config file for the extensions
>/etc/nginx/ssl/$NAME.ext cat <<-EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = $NAME # Be sure to include the domain name here because Common Name is not so commonly honoured by itself
DNS.2 = bar.$NAME # Optionally, add additional domains (I've added a subdomain here)
EOF

# Create the signed certificate
openssl x509 -req -in /etc/nginx/ssl/$NAME.csr -CA /etc/nginx/ssl/ca-certificates/rootCA.pem -CAkey /etc/nginx/ssl/ca-certificates/rootCA.key -CAcreateserial -out /etc/nginx/ssl/$NAME.crt -days 825 -sha256 -extfile /etc/nginx/ssl/$NAME.ext

fi