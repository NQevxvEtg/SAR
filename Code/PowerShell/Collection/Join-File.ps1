# https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/splitting-large-files-in-smaller-parts-part-2

<#
PS> dir "C:\Users\username\Downloads\*.part"


    Folder: C:\Users\username\Downloads


Mode                LastWriteTime         Length Name                                                              
----                -------------         ------ ----                                                              
-a----       03.03.2019     16:25        6291456 video.mp4.00.part                    
-a----       03.03.2019     16:25        6291456 video.mp4.01.part                    
-a----       03.03.2019     16:25        6291456 video.mp4.02.part                    
-a----       03.03.2019     16:25        5207382 video.mp4.03.part 


PS C:\> Join-File -Path "C:\Users\username\Downloads\video.mp4" -DeletePartFiles -Verbose
VERBOSE: processing C:\Users\username\Downloads\video.mp4.00.part...
VERBOSE: processing C:\Users\username\Downloads\video.mp4.01.part...
VERBOSE: processing C:\Users\username\Downloads\video.mp4.02.part...
VERBOSE: processing C:\Users\username\Downloads\video.mp4.03.part...
VERBOSE: Deleting part files...

PS C:\>

 #>
 
function Join-File
{
    
    param
    (
        [Parameter(Mandatory)]
        [String]
        $Path,

        [Switch]
        $DeletePartFiles
    )

    try
    {
        # get the file parts
        $files = Get-ChildItem -Path "$Path.*.part" | 
        # sort by part 
        Sort-Object -Property {
            # get the part number which is the "extension" of the
            # file name without extension
            $baseName = [IO.Path]::GetFileNameWithoutExtension($_.Name)
            $part = [IO.Path]::GetExtension($baseName)
            if ($part -ne $null -and $part -ne '')
            {
                $part = $part.Substring(1)
            }
            [int]$part
        }
        # append part content to file
        $writer = [IO.File]::OpenWrite($Path)
        $files |
        ForEach-Object {
            Write-Verbose "processing $_..."
            $bytes = [IO.File]::ReadAllBytes($_)
            $writer.Write($bytes, 0, $bytes.Length)
        }
        $writer.Close()

        if ($DeletePartFiles)
        {
            Write-Verbose "Deleting part files..."
            $files | Remove-Item
        }
    }
    catch
    {
        throw "Unable to join part files: $_"
    }
}
