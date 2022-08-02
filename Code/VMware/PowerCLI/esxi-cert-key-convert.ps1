$ESXI_PATH='\\ssl'
Write-Host $ESXI_PATH

$ESXI_configs=$ESXI_PATH+'configs\'
Write-Host $ESXI_configs

$ESXI_csr=$ESXI_PATH+'csr\'
Write-Host $ESXI_csr

$ESXI_key=$ESXI_PATH+'key\'
Write-Host $ESXI_key

$ESXI_rui_key=$ESXI_PATH+'rui-key\'
Write-Host $ESXI_rui_key

$domainName='fqdn'

$names=@(
'dev1',
'dev2',
'dev3'

)

# generate config directories and files

ForEach ($name in $names) {

$key = $ESXI_key + $name + '.key'
$rui_key = $ESXI_rui_key + $name + '.key'

# Write-Host $key
# Write-Host $rui_key

\\openssl.exe rsa -in $key -out $rui_key

(Get-Content $rui_key) | Write-Host

}

