$url =  "https://api.github.com"

$endpoint = "/gists"

$urlAnon = "$url" + "$endpoint"


$JSON2 = ConvertTo-Json @{
  description  = "the description for this gists";
  public = $true;
  files = @{
    "file1.txt" =@{
      content = "String file contents"
    
    }

  }

}



$token = "92e97d33ab19dab30da23b11624cc1e0a4887585"

$urlSecure = "$urlAnon" + "?access_token=" + "$token"
$gists = Invoke-RestMethod -Method Post -Uri $urlSecure -Body $JSON2


$gists 

$JSON2 = ConvertTo-Json @{
  description  = "monkey fish";
  public = $true;
  files = @{
    "file1.txt" =@{
      content = "im tired"
    
    }

  }

}