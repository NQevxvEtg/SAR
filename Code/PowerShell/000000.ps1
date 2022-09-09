Get-CimInstance -ClassName Win32_ComputerSystem -ComputerName hostname

# linux tail -f like
Get-Content -Path "file.log" -Wait

# remove software
MsiExec.exe /X{long-uuid-here}

# get info
wmic /node:hostname product get name,version /format:csv > hostname.csv
