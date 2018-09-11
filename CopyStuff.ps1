# MergeProfiles
#Merge profiles from one directory to another

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$false,
    HelpMessage='Source folder path that will be searched for profiles')]
    [string] $sourceFolderPath,
    [Parameter(Mandatory=$false,
    HelpMessage='Location of log files')]
    [string] $LogFilePath,
    [Parameter(Mandatory=$false,
    HelpMessage='Location of user folder.  Typically this is c:\Users')]
    [string] $UsersFolderPath,
    [Parameter(Mandatory=$false,
    HelpMessage='Do we want to copy the public profile')]
    [boolean] $CopyPublicProfile
)

#Used for logging
$stringBuilder = New-Object System.Text.StringBuilder

#Source folder will be something like dBackup
$RootDirectory = "c:\"
$sourceFolderPath = "c:\dBackup"
$userFolderPath = "c:\Users"


$LogFilePath = "c:\Windows\CCM\Logs\CopyStuff.log"
$CopyPublicProfile = $true

function Get-FileNameAndPathFromString
{
    Param
    (
        [Parameter(Mandatory=$true)]
        [string] $DirectoryWithFilename
    )
    $returnObject = [PSCustomObject]@{
    FileName = ""
    DirectoryPath = ""
    }

    [int]$lastIndexOfBSlash = $DirectoryWithFilename.LastIndexOf('\')
    [int]$PathStringLength = $DirectoryWithFilename.Length
    $fileName = $DirectoryWithFilename.Substring(($lastIndexOfBSlash + 1), ($PathStringLength - $lastIndexOfBSlash) - 1)
    $DirectoryPath = $DirectoryWithFilename.Substring(0,$lastIndexOfBSlash)

    $returnObject = [PSCustomObject]@{
    FileName = $fileName
    DirectoryPath = $DirectoryPath
    }

    return $returnObject


}

function Copy-Profile
{
    Param(  
[Parameter(Mandatory=$true)]  
[string]$SourcePath,  
[Parameter(Mandatory=$true)]  
[string]$DestinationPath  
)  

    Write-Logging -message "Copy-Profile called"
    Write-Logging -message "Source Folder = $($SourcePath)"
    Write-Logging -message "Destination Folder = $($DestinationPath)"

    
    if(-not(Test-Path($SourcePath)))
    {
        throw "Source path of $($SourcePath) doesn't exist"

    }
    
    #gets all objects in source location
    $fileSystemObjects = Get-ChildItem -Path $sourcePath -Recurse -Filter "*.*"
    foreach($fileSystemObject in $fileSystemObjects)
    {  
        $numObjects = $fileSystemObjects.Length
        Write-Logging -message "Number of objects to migrate from $($SourcePath) = $($numObjects)"
        $sourcePathObject = $fileSystemObject.FullName  
        $destinationPathObject = $fileSystemObject.FullName.Replace($sourcePath, $destinationPath)
        if(-not (Test-Path $sourcePathObject))
        {
            #item already copied and removed, continuing
            continue
        }

        Write-Logging -message "Source object = $($sourcePathObject) and destination object = $($destinationPathObject)"
        Write-Logging -message "Checking if object is a directory"
        #we have the dest path, check if file or folder?
        if((Get-Item $sourcePathObject) -is [System.IO.DirectoryInfo])
        {
            Write-Logging -message "$($sourcePathObject) is a directory"
            Write-Logging -message "Determinging if directory already exists in destination"
            #directory
            # does it exist in the destination
            if(-not(Test-Path $destinationPathObject))
            {
                Write-Logging -message "Directory doesn't exist, copying entire tree.."
                #copy the entire directory, no worries
                $returnCode = Robocopy $sourcePathObject $destinationPathObject /zb /copyall /move /e
                Write-Logging -message $returnCode
                Write-Logging -message "Copy completed" 
            }
            else
            {
                Write-Logging -message "Directory already exists in destination, skipping..."
               #directory exists in the destination, do nothing 
            }
        }
        else
        {
            Write-Logging -message "Current object is a file"
            Write-Logging -message "Checking if file exists in destination"
            #file
            #does the file exist in the destination, if it does, check the timestamp, keep newer?  Make a copy, keep both?
            if(-not(Test-Path $destinationPathObject))
            {
                Write-Logging -message "File does not exist, moving file to destination"
                # just copy it
                $DestinationfileNameAndDirectory = Get-FileNameAndPathFromString -DirectoryWithFilename $destinationPathObject
                $SourceFileNameAndDirectory = Get-FileNameAndPathFromString -DirectoryWithFilename $sourcePathObject
                Write-Logging -message "Copying..." 
                Write-logging -message "`t Source = $($SourceFileNameAndDirectory.Directory)" + "\" + "$($SourceFileNameAndDirectory.FileName)"
                Write-logging -message "`t  Destination = $($DestinationfileNameAndDirectory.Directory)" + "\" + "$($DestinationfileNameAndDirectory.FileName)"
                if(Test-Path -Path "")
                {
                    $returnCode = Robocopy $SourceFileNameAndDirectory.DirectoryPath $DestinationfileNameAndDirectory.DirectoryPath $SourceFileNameAndDirectory.FileName /zb /copyall /mov
                    Write-Logging -message $returnCode
                    Write-Logging -message "Copying file completed"
                }
                else
                {
                    Write-Logging -message "File didn't exist in source, skipping..."
                }
            }
            else
            {
                Write-Logging -message "file exists in destination, determinging if compare needed"
                if(Test-Path $sourcePathObject)
                {
                    #source still exists, not copied yet
                    Write-Logging -message "Comparing files...."
                    #check timestamp, determine which is newer
                    $sourceDateTime = [datetime](Get-ItemProperty -Path $sourcePathObject -Name LastWriteTime).lastwritetime
                    $destinationDateTime = [datetime](Get-ItemProperty -Path $destinationPathObject -Name LastWriteTime).lastwritetime
                    Write-Logging -message "Source file LastWriteTime = $($sourceDateTime) and destination file LastWriteTime = $($destinationDateTime)"
                    if($sourceDateTime -gt $destinationDateTime)
                    {
                        Write-Logging -message "Source file is newer, overwriting destination file"
                        #copy the file, overwriting
                        $returnCode = Robocopy $sourcePathObject $destinationPathObject /zb /copyall /move
                    }
                    else
                    {
                        Write-Logging -message "Destination file is newer, ensuring source file is deleted"
                        if(Test-Path $sourcePathObject)
                        {
                            #item in destination is newer, remove old file
                            Remove-Item -Path $sourcePathObject -Force
                        }

                        Write-Logging -message "Removing $($sourcePathObject) completed"
                    }
                }
                else
                {
                    #source object was already copied during a MOVE, when destination folder didn't exist, move was performed
                    #check if the destination exists, if it doesn't there is a problem
                }
            }
        }  
    }
    Write-Logging -message "Copy profile completed"
}

function Is-Profile
{
  [CmdletBinding()]
  param
  (
    [string]$FolderPath
  )
  $isProfile = $false
  $foundDocs = $false
  $foundDesktop = $false
  $foundFavorites = $false
  #$foundPublicDesktop = $false
  $foundPublicDownloads = $false
  $isPublic = $false

  $folderList = dir -Path $FolderPath -Directory
  if($folderPath.EndsWith("\Public"))
  {
    #is public tree
    $isPublic = $true
  }
  foreach($f in $folderList)
  {

    if($f.Name.Trim().ToLower().Equals("desktop"))
    {
        $foundDesktop = $true
        continue
    }
    elseif($f.Name.Trim().ToLower().Equals("favorites"))
    {
        $foundFavorites = $true
        continue
    }
    elseif($f.Name.Trim().ToLower().Equals("documents"))
    {
        $foundDocs = $true
        continue
    }
    elseif($CopyPublicProfile -and $isPublic)
    {
        if($f.Name.Trim().ToLower().Equals("downloads"))
        {
            $foundPublicDownloads = $true
            continue
        }
        
    }

  }

if($CopyPublicProfile)
{
    if($foundPublicDownloads)
    {
        $isProfile = $true
    }
}
if($foundFavorites -and $foundDocs -and $foundDesktop)
{
    #is profile
    $isProfile = $true
}

  return $isProfile

}

function Write-Logging($message)
{
	$dateTime = Get-Date -Format yyyyMMddTHHmmss
	$null = $stringBuilder.Append($dateTime.ToString())
	$null = $stringBuilder.Append( "`t==>>`t")
	$null = $stringBuilder.AppendLine( $message)
    $stringBuilder.ToString() | Out-File -FilePath $LogFilePath -Append
    $stringBuilder.Clear()
}

function Delete-Empties($path)
{
    $items = Get-ChildItem -Path $path
    [long]$numOfObjects = $items.Length
    
    foreach($item in $items)
    {
        $sourcePathObject = $item.FullName
        if((Get-Item $sourcePathObject) -is [System.IO.DirectoryInfo])
        {
            [long]$objsInDir = (Get-ChildItem -Path $sourcePathObject).Length
            if($objsInDir -eq 0)
            {
                Remove-Item -Path $sourcePathObject
            }
            else
            {
                Delete-Empties -path $sourcePathObject
            }

        }
    }
    if($numOfObjects -ne 0)
    {
    }
    else
    {
        Remove-Item -Path $path
    }
}


Write-Logging -message "Start of script***********************"

#log starting variable state

try
{

    Write-Logging -message "Log file path = $($LogFilePath)"
    Write-Logging -message "Copy public profile = $($CopyPublicProfile)"
    Write-Logging -message "Source folder path = $($sourceFolderPath)"
    Write-Logging -message "user folder = $($userFolder)"

    $DirectoriesInSourceFolder = dir -Directory -Path $sourceFolderPath

    foreach($dir in $DirectoriesInSourceFolder)
    {
        $fullPath = $dir.FullName
        Write-Logging "Checking if $($dir) is a profile..."

        if((Is-Profile -Folder $fullPath))
        {
            Write-Logging "$($dir) is a profile, running copy"
            #found profile, merge
            Copy-Profile -sourcePath "$fullPath" -destinationPath "$($userFolderPath)\$($dir.Name)"
        }
        else
        {
            Write-Logging "$($dir) is not a profile, skipping"
        }

    }
}
Catch
{
    Write-Logging -message "Exception caught, message = " + $_.Exception.ToString()
}

Write-Logging -message "End of script***********************"

#C:\Source\scripts\CopyStuff.ps1 -FolderNamesToDetermineProfile "favorites,documents,desktop" -SourceFolderPath "c:\dBackup" -LogFilePath "C:\Windows\CCM\Logs"