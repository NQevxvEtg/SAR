# print ca certs
awk -v cmd='openssl x509 -noout -subject' '/BEGIN/{close(cmd)};{print | cmd}' < /etc/ssl/certs/ca-certificates.crt

# convert to crt first
openssl x509 -outform der -in CERTIFICATE.pem -out CERTIFICATE.crt

# copy to ca dir
cp CERTIFICATE.crt /usr/local/share/ca-certificates

# update ca
update-ca-certificates

# read certificate
openssl x509 -inform pem -noout -text -in 'cert.pem'
openssl x509 -inform der -noout -text -in 'cert.crt'
