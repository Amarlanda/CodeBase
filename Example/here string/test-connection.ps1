$ie = (New-Object -COM "Shell.Application").Windows() | ? { $_.Name -eq "Windows Internet Explorer" }
#$ie[0].Navigate("http://www.google.com/", 2048)

$Computers = "10.216.174.157", "10.216.174.158", "10.216.174.159",  "10.216.174.160", "10.216.174.161", "10.216.174.162", "10.216.174.219", "10.216.174.220", "10.216.174.178", "10.216.174.190", "10.216.174.221"
    

cls
 <#$Computers = @"
UKDTAVSH003
UKDCAVD003
UKDTAVSH004
UKDTAVSH005
UKDTAVSH006
UKDTAVSH009
UKDTAVSH010
UKDTAVSH078
UKDTAVSH079
UKDTAVSH034
UKDTAVSH046
UKDTAVSH080      
"@
#>

$user =@()
#$computers.split("", [StringSplitOptions]::RemoveEmptyEntries).TRIM( ) | ForEach-Object {

$computers | % {

  # Could do the full set of tests against the ILO as well.
  # Create a small array of the original computer name ($_) and the computer name with IRB appended.
  $_ , "$($_)irb" | ForEach-Object {
    #"$($_)rb" 
 
    $Ping = Test-Connection $_ -Count 1 -ErrorAction SilentlyContinue
    # If DNS no worky, Ping no worky too. Will muddy the results a lot.
    $DNSResolves = [Boolean]$(try { [Net.Dns]::GetHostEntry($_) | Select-Object -ExpandProperty AddressList } catch { })
    New-Object PSObject -Property ([Ordered]@{
      ComputerName   = $_
      DNSResolves    = $DNSResolves
      RespondsToPing = $(if ($Ping) { $true } else { $false })
      IPV4Address    = $Ping.IPV4Address
      ResponseTime   = $Ping.ResponseTime
      TimeToLive     = $Ping.TimeToLive
      ReverseLookUp  = [System.Net.Dns]::GetHostbyAddress(10.216.174.221)
      Pingilo        = (Test-Connection "$($_)irb" -Quiet -Count 1)
    })
    # Wrong place, drop out a loop level.
  }
  # Need the full file path to iexplore, it's not in %PATH%
  #$ie[0].Navigate("http://www.google.com/", 2048)
  #$ie[0].Navigate("http://$($_)irb", 2048)
  #Start-Process 'C:\Program Files (x86)\Internet Explorer\iexplore.exe' "http://$($_)irb"

} | FT



#% { 
#
#
#$user +=  @($_)
#
#                                                  
# # REMOVE TO TEST $(($Computers -split '[\r\n]') |? {$_} )| % {                           
#
####Actually ping code ##
#Test-Connection -Cn $_ -Count 1 -ErrorAction 0; if (-not $?) { write-host "Stuff went wrong : $_" } } |select Address ,IPv4address, ResponseTime, TimeToLive 
#
#$user
#$user.count

