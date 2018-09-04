$source = 'C:\dBackup - Copy'
$dest = 'c:\dBackup'
$newName = 'dBackup'
$newSource = 'C:\dBackup'
$newDest = 'c:\dBackup - Copy'

Remove-Item -Path $dest -Recurse -Force
Rename-Item -Path $source -NewName $newName -Force
Copy-Item -Path $newSource -Destination $newDest -Recurse 

Remove-Item -Path C:\Users\DAIsProfile -Recurse -Force
Remove-Item -Path 'C:\Users\DAIsProfile - Copy' -Recurse -Force
Remove-Item -Path 'C:\Users\DAIsProfile - Copy - Copy' -Recurse -Force