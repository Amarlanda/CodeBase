## This Script Mirrors a directory tree from source to destination with the Windows builtin command robocopy.
## Exit codes from robocopy are logged to Windows Eventlog.
## Usage: Run with administrative rights in Windows Task Scheduler or Administrator:PowerShell
## If not executed with administrative privileges the script will not write to eventlog.
 
## Change these parameters
## ================================================================
 
## Name of the job, name of source in Windows Event Log and name of robocopy Logfile.
$JOB = "MyApplication"
 
## Source directory
$SOURCE = "f:\events"
 
## Destination directory. Files in this directory will mirror the source directory. Extra files will be deleted!
$DESTINATION = "g:\test"
 
## Path to robocopy logfile
$LOGFILE = "g:\test\$JOB"
 
## Log events from the script to this location
$SCRIPTLOG = "g:\test\$JOB-scriptlog.log"
 
## Mirror a direcotory tree
$WHAT = @("/COPYALL")
## /COPY:DATS: Copy Data, Attributes, Timestamps, Security
## /SECFIX : FIX file SECurity on all files, even skipped files.
 
## Retry open files 3 times wait 30 seconds between tries. 
$OPTIONS = @("/E", "/ZB", "/X", "/TEE")
## /NFL : No File List - don't log file names.
## /NDL : No Directory List - don't log directory names.
## /L   : List only - don't copy, timestamp or delete any files.
 
## This will create a timestamp like yyyy-mm-yy
$TIMESTAMP = get-date -uformat "%Y-%m%-%d"
 
## This will get the time like HH:MM:SS
$TIME = get-date -uformat "%T"
 
## Append to robocopy logfile with timestamp
$ROBOCOPYLOG = "/LOG+:$LOGFILE`-Robocopy`-$TIMESTAMP.log"
 
## Wrap all above arguments
$cmdArgs = @("$SOURCE","$DESTINATION",$WHAT,$ROBOCOPYLOG,$OPTIONS)
 
## ================================================================
 
## Start the robocopy with above parameters and log errors in Windows Eventlog.
& C:\Windows\System32\Robocopy.exe @cmdArgs
 
## Get LastExitCode and store in variable
$ExitCode = $LastExitCode
 
$MSGType=@{
"16"="Errror"
"8"="Error"
"4"="Warning"
"2"="Information"
"1"="Information"
"0"="Information"
}
 
## Message descriptions for each ExitCode.
$MSG=@{
"16"="Serious error. robocopy did not copy any files.`n
Examine the output log: $LOGFILE`-Robocopy`-$TIMESTAMP.log"
"8"="Some files or directories could not be copied (copy errors occurred and the retry limit was exceeded).`n
Check these errors further: $LOGFILE`-Robocopy`-$TIMESTAMP.log"
"4"="Some Mismatched files or directories were detected.`n
Examine the output log: $LOGFILE`-Robocopy`-$TIMESTAMP.log.`
Housekeeping is probably necessary."
"2"="Some Extra files or directories were detected and removed in $DESTINATION.`n
Check the output log for details: $LOGFILE`-Robocopy`-$TIMESTAMP.log"
"1"="New files from $SOURCE copied to $DESTINATION.`n
Check the output log for details: $LOGFILE`-Robocopy`-$TIMESTAMP.log"
"0"="$SOURCE and $DESTINATION in sync. No files copied.`n
Check the output log for details: $LOGFILE`-Robocopy`-$TIMESTAMP.log"
}
 
## Function to see if running with administrator privileges
function Test-Administrator  
{  
    $user = [Security.Principal.WindowsIdentity]::GetCurrent();
    (New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)  
}
 
## If running with administrator privileges
If (Test-Administrator -eq $True) {
	"Has administrator privileges"
 
	## Create EventLog Source if not already exists
	if ([System.Diagnostics.EventLog]::SourceExists("$JOB") -eq $false) {
	"Creating EventLog Source `"$JOB`""
    [System.Diagnostics.EventLog]::CreateEventSource("$JOB", "Application")
	}
 
	## Write known ExitCodes to EventLog
	if ($MSG."$ExitCode" -gt $null) {
		Write-EventLog -LogName Application -Source $JOB -EventID $ExitCode -EntryType $MSGType."$ExitCode" -Message $MSG."$ExitCode"
	}
	## Write unknown ExitCodes to EventLog
	else {
		Write-EventLog -LogName Application -Source $JOB -EventID $ExitCode -EntryType Warning -Message "Unknown ExitCode. EventID equals ExitCode"
	}
}
## If not running with administrator privileges
else {
	## Write to screen and logfile
	Add-content $SCRIPTLOG "$TIMESTAMP $TIME No administrator privileges" -PassThru
	Add-content $SCRIPTLOG "$TIMESTAMP $TIME Cannot write to EventLog" -PassThru
 
	## Write known ExitCodes to screen and logfile
	if ($MSG."$ExitCode" -gt $null) {
		Add-content $SCRIPTLOG "$TIMESTAMP $TIME Printing message to logfile:" -PassThru
		Add-content $SCRIPTLOG ($TIMESTAMP + ' ' + $TIME + ' ' + $MSG."$ExitCode") -PassThru
		Add-content $SCRIPTLOG "$TIMESTAMP $TIME ExitCode`=$ExitCode" -PassThru
	}
	## Write unknown ExitCodes to screen and logfile
	else {
		Add-content $SCRIPTLOG "$TIMESTAMP $TIME ExitCode`=$ExitCode (UNKNOWN)" -PassThru
	}
	Add-content $SCRIPTLOG ""
	Return
}