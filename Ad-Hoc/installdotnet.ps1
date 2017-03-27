[string]$drive = "x:"

net use $drive /Delete /Yes
net use $drive \\10.203.35.23\Dotnet 
Set-Location $drive
#

Copy-Item -Force -path x:\* -Recurse -Destination "C:\DotNet\"
Copy-Item -Force -path x:\* -Recurse -Destination "C:\DotNet\"


DISM.exe /Online /Remove-Package /PackagePath:c:\dotnet\amd64_Package_for_KB2769166_6.2.1.0_neutral_31bf3856ad364e35_\windows8-rt-kb2769166-x64.cab  /NoRestart
powershell -executionpolicy bypass -file "c:\dotnet\2.Install.Net351.Ps1" 
<#

make directory

$targetdirectory = "D:\To"
$sourcedirectory = "\\server\from"

if (!(Test-Path -path $targetdirectory)) {New-Item $targetdirectory -Type Directory}
Copy-Item -Path $sourcedirectory\file.zip -Destination $targetdirectory

GCI $drive -Recurse -Force | ?{$_.psiscontainer } | select *

#>