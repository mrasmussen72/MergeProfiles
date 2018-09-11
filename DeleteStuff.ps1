function Delete-Empties($path)
{
    $items = Get-ChildItem -Path $path -Recurse -Filter "*.*"
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
}

Delete-Empties -path "C:\temp\IsProfile"