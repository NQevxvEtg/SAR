Add-Type -AssemblyName System.Windows.Forms

while ($true)
{
  $Pos = [System.Windows.Forms.Cursor]::Position
  $x = ($pos.X % 500) + 1
  $y = ($pos.Y % 500) + 1
  [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($x, $y)
  Start-Sleep -Seconds 10
}



Add-Type -AssemblyName System.Windows.Forms

while ($true)
{
  # Randomize within a 500x500 region
  $x = Get-Random -Minimum 1 -Maximum 500
  $y = Get-Random -Minimum 1 -Maximum 500
  [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($x, $y)
  Start-Sleep -Seconds 10
}
