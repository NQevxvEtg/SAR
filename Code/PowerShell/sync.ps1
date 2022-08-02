

if ($args.count -ne 3) {
	Write-Host "Usage: sync.ps1 <source> <target> <mode>"
	Write-Host "Mode: 1 = 1 way sync"
	Write-Host "Mode: 2 = 2 way sync"
	exit
	}


$source = $args[0]
$target = $args[1]

New-Item -Force $source'initial.initial'
New-Item -Force $target'initial.initial'

  $sourceFiles = Get-ChildItem -LiteralPath $source  -Recurse
  $targetFiles = Get-ChildItem -LiteralPath $target  -Recurse
  
  write-host $sourceFiles

  if ($debug -eq $true) {
    Write-Output "Source=$source, Target=$target"
    Write-Output "sourcefiles = $sourceFiles TargetFiles = $targetFiles"
  }

  $syncMode = $args[2] 

  if ($sourceFiles -eq $null -or $targetFiles -eq $null) {
    Write-Host "Empty Directory encountered. Skipping file Copy."
  } else
  {
    $diff = Compare-Object -ReferenceObject $sourceFiles -DifferenceObject $targetFiles

    foreach ($f in $diff) {
      if ($f.SideIndicator -eq "<=") {
        $fullSourceObject = $f.InputObject.FullName
        $fullTargetObject = $f.InputObject.FullName.Replace($source,$target)

        Write-Host "Attempt to copy the following: " $fullSourceObject
        Copy-Item -LiteralPath $fullSourceObject -Destination $fullTargetObject
      }


      if ($f.SideIndicator -eq "=>" -and $syncMode -eq 2) {
        $fullSourceObject = $f.InputObject.FullName
        $fullTargetObject = $f.InputObject.FullName.Replace($target,$source)

        Write-Host "Attempt to copy the following: " $fullSourceObject
        Copy-Item -LiteralPath $fullSourceObject -Destination $fullTargetObject
      }

    }
  }
  
    Remove-Item -Force $source'initial.initial'
    Remove-Item -Force $target'initial.initial'
