# print ca certs
awk -v cmd='openssl x509 -noout -subject' '/BEGIN/{close(cmd)};{print | cmd}' < /etc/ssl/certs/ca-certificates.crt

# convert to crt first
openssl x509 -outform der -in CERTIFICATE.pem -out CERTIFICATE.crt

# copy to ca dir
cp CERTIFICATE.crt /usr/local/share/ca-certificates

# update ca
update-ca-certificates
