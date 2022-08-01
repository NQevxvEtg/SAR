#!/bin/bash

for cert in `ls crts/*.crt`
 do
certFile=`basename $cert | awk -F. '{print $1}'`

cat keys/${certFile}.key > pems/${certFile}.pem
cat crts/${certFile}.crt >> pems/${certFile}.pem


done
