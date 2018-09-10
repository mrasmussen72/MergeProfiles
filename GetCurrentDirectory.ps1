# Determine script location for PowerShell
$ScriptDir = Split-Path $script:MyInvocation.MyCommand.Definition 
$temp = $script:MyInvocation.MyCommand.Definition
 
Write-Host "Current script directory is $ScriptDir"