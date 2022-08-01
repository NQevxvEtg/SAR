
$MAIN_PATH='\\0.0.0.0\c$\path\stig\'
Write-Host $MAIN_PATH

$HOST_PATH='\\0.0.0.0\c$\path\hosts\'
Write-Host $HOST_PATH

$EXPORT_PATH='\\0.0.0.0\c$\path\stig\test\'
Write-Host $EXPORT_PATH

$file = $MAIN_PATH + 'test.ckl'
$host_file = $HOST_PATH + 'host-info.csv'

$csv = Import-Csv $host_file

foreach($item in $csv) {
    Write-Host $item.hostname
	Write-Host $item.ip
	Write-Host $item.mac
	$fqdn = $item.hostname+'fqdn.domain'
	Write-Host $fqdn
	
	$newfile = $EXPORT_PATH + $item.hostname + '.ckl'
	
	Copy-Item $file -Destination $newfile
	
	$fixed = foreach($line in [System.IO.File]::ReadLines($newfile)) {
		
	  if ( $line -match 'HOST_NAME' ) {
		$fix = '<HOST_NAME>' + $item.hostname + '</HOST_NAME>'
		$line -replace $line, $fix
		Write-Host $line
	  }
	  elseif ( $line -match 'HOST_IP' ) {
		$fix = '<HOST_IP>' + $item.ip + '</HOST_IP>'
		$line -replace $line, $fix
		Write-Host $line
	  }
	  elseif ( $line -match 'HOST_MAC' ) {
		$fix = '<HOST_MAC>' + $item.mac + '</HOST_MAC>'
		$line -replace $line, $fix
		Write-Host $line
	  }  
	  elseif ( $line -match 'HOST_FQDN' ) {
		$fix = '<HOST_FQDN>' + $fqdn + '</HOST_FQDN>'
		$line -replace $line, $fix
		Write-Host $line
	  }  
	  else {
		$line
	  } 
	} 
	
	
	
	$fixed | Out-File $newfile
	
}

