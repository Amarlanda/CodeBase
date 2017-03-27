 cat c:\test\vm.txt |% { gci \\$_\\c$\"Documents and Settings" | ?{$_.name -ne "Administrator" -and $_.name -ne "All Users"}|% {write $("Deleted $($_.fullname)")}} #
 