openssl enc -d -aes-256-cbc -md sha512 -pbkdf2 -iter 100000 -salt -in $1 -out $1.txt -pass file:"password.txt"
