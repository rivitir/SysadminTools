<#

    Script to remove all old files
    Written by James Stull aka Rivitir

    This script will remove all files that are older than X days. To use, add your
    path and number of days in negative you want to delete files (ie: to delete all files older than 30 days use -30).
    It will be recursive.

#>


$path = "C:\Path\to\Folder"
$age = (Get-Date).AddDays(-30)


# Delete files older than then $age in $path.
Get-ChildItem -Path $path -Recurse -Force | Where-Object { !$_.PSIsContainer -and $_.CreationTime -lt $age } | Remove-Item -Force

# To Delete any empty directories left behind after deleting the old files uncomment below.
# Get-ChildItem -Path $path -Recurse -Force | Where-Object { $_.PSIsContainer -and (Get-ChildItem -Path $_.FullName -Recurse -Force | Where-Object { !$_.PSIsContainer }) -eq $null } | Remove-Item -Force -Recurse
