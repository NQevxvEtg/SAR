<# openssl.cfg example
[ req ]
default_bits = 2048
default_keyfile = rui.key
distinguished_name = req_distinguished_name
encrypt_key = no
prompt = no
string_mask = nombstr
req_extensions = v3_req

[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = digitalSignature, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = DNS:hostname, IP:0.0.0.0, DNS:hostname.fqdn

[ req_distinguished_name ]
countryName = US
organizationName = org
organizationalUnitName = org
organizationalUnitName = org
organizationalUnitName = org
commonName = hostname.fqdn
#>



$ESXI_PATH='\\ssl\'
Write-Host $ESXI_PATH

$ESXI_configs=$ESXI_PATH+'configs\'
Write-Host $ESXI_configs

$ESXI_csr=$ESXI_PATH+'csr\'
Write-Host $ESXI_csr

$ESXI_key=$ESXI_PATH+'key\'
Write-Host $ESXI_key



$domainName='fqdn'

$ips=@(
'0.0.0.0',
'0.0.0.0',
'0.0.0.0'

)

$names=@(
'dev1',
'dev2',
'dev3'

)

# generate config directories and files

ForEach ($name in $names) {
if ($name -ne 'dev1') {
Copy-Item -Path $ESXI_configs'dev1' -Recurse -Destination $ESXI_configs$name
}
}



for ($i=0; $i -le 100000000; $i=$i+1 ) {

$dns1 = $names[$i]
$dns2 = $names[$i]+'.'+$domainName
$ip1 = $ips[$i]

$subjectAltName = "subjectAltName = DNS:$dns1, IP:$ip1, DNS:$dns2"
$commonName = "commonName = $dns2"

$config1 = $ESXI_configs + $names[$i] + '\openssl.cfg'
$config2 = $ESXI_configs + $names[$i] + '\openssl2.cfg'



(Get-Content $config1) | ForEach-Object {
  if ( $_ -match '^subjectAltName' ) {
    $_ -replace $_, $subjectAltName
  }
  elseif ( $_ -match '^commonName' ) {
    $_ -replace $_, $commonName
  }
  else {
    $_
  }
} |  Set-Content $config1
#} | Out-File $config2

$csr=$ESXI_csr+$dns1+'.csr'
$key=$ESXI_key+$dns1+'.key'


\\openssl.exe req -new -nodes -out $csr -keyout $key -config $config1

}
