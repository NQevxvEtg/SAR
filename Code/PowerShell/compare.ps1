## Step 1 - Folders To Be Searched
$folder1 = "path"
$folder2 = "path"

## Step 2 - Search Both Folders For Files To Be Compared
$List1 = gci $folder1 -Recurse | Select Name
$List2 = gci $folder2 -Recurse | Select Name

## Step 3 - See All Compare Output
$Compare = Compare-Object -ReferenceObject $List1 -DifferenceObject $List2 -property name -passthru -IncludeEqual


## Step 4 See Only Difference in reference objects
##=> - Difference in destination object.
##<= - Difference in reference (source) object.
##== - When the source and destination objects are equal.

$DifferenceInReference = (Compare-Object -ReferenceObject $List1 -DifferenceObject $List2 | Where SideIndicator -eq "<=")
$DifferenceInReference
$DifferenceInDestination = (Compare-Object -ReferenceObject $List1 -DifferenceObject $List2 | Where SideIndicator -eq "=>")
$DifferenceInDestination
$EqualInBoth = (Compare-Object -ReferenceObject $List1 -DifferenceObject $List2 | Where SideIndicator -eq "==")
$EqualInBoth
