

$RegularExpression = '^[a-z][a-z]', "(ab|vw|ef)", "..", "\w\w", "\S\S", "\D\D", ".{2}","[^c]{2}", "[^c]{2,2}", "[ab?|vw?|ef?]", "[abvwef]{3}+" , "[a-be-fv-w]{3]", "[w+][^d][^y][^h]{3}" ,"[^\r\[n^][d^][^y][^h]", "[(?ab|vw|ef){2}]", "ab(?=c)|vw(?=x)", "(?=a(b))|(?=v(w))", "ab(?!c)", "^(?!c)"
$RegularExpression | % { 

$re = $_
@"
abcd
vwxy
efgh
"@ -split '\n' | %{
  if ($_ -match $re) { 
    Write-Host "Matched $_ using $re to $($Matches[0])"
  } else {
    Write-Host "Failed to match $_ using $re "
  }
}

}
