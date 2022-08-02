[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

$signature=@'
[DllImport("user32.dll",CharSet=CharSet.Auto,CallingConvention=CallingConvention.StdCall)]
public static extern void mouse_event(long dwFlags, long dx, long dy, long cButtons, long dwExtraInfo);
'@

$SendMouseClick = Add-Type -memberDefinition $signature -name "Win32MouseEventNew" -namespace Win32Functions -passThru

$x = 1431
$y = 370

for ($i=0; $i -le 100; $i=$i+1 ) {
	
[System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($x, $y)
sleep -Seconds 01

# left click
$SendMouseClick::mouse_event(0x00000002, 0, 0, 0, 0);
$SendMouseClick::mouse_event(0x00000004, 0, 0, 0, 0);
	
	}


# left click
# $SendMouseClick::mouse_event(0x00000002, 0, 0, 0, 0);
# $SendMouseClick::mouse_event(0x00000004, 0, 0, 0, 0);

# double click
# $SendMouseClick::mouse_event(0x00000002, 0, 0, 0, 0);
# $SendMouseClick::mouse_event(0x00000004, 0, 0, 0, 0);
# $SendMouseClick::mouse_event(0x00000002, 0, 0, 0, 0);
# $SendMouseClick::mouse_event(0x00000004, 0, 0, 0, 0);
