function build-FTAudit{
  
  [CmdLetBinding()]
  param(

    #[Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    $VMwareArray,

    #[Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    $ADArray,

    #[Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    $AWSArray
    
  )
  
  ##GLOBAL 
  $script:Allservers = New-Object -TypeName System.Collections.ArrayList     # Declare $Allservers = New-Object System.Collections.ArrayList
    
  ##FUNCTION  - to make the Array names more friendly    
  function rename-Arry {
  
  $returnArry = New-Object -TypeName System.Collections.ArrayList
             
    $Array = $args[0]
    $expression = $args[1]
    $propertyName =$args[2]
    $Array | ForEach-Object -process {
      $currentitem = $_
      $serverProperties = $($currentitem.PSObject.Properties)

      for ($i = 0; $i -lt $($serverProperties.count) ;$i++){
                                                                           
        $currentitem = $currentitem | Select-Object -Property *,                                 #  loop through the properties and append to the current object "
        @{n="$propertyName $($serverProperties[$i].Name)";e={$($serverProperties[$i].value)}}
      } 
      
      $currentitem = $currentitem | Select-Object -Property *,
      @{n="MachineType";e={$expression}}
      $returnArry += $currentitem # end of for
  
    }#end of args
    return $returnArry | select name, "$($propertyName)*"
  }

  $OutterSwingArray = $ADArray    # need to populate the swing arrays     

  if ($VMwareArray){
    rename-arry $VMwareArray "VMware" "VI - "
  }
  
  if ($ADArray){
    rename-arry $ADArray "ADobj" "AD - "
  }
  
  if ($AWSArray){
    rename-arry $ADArray  "AWS" "AWS - "
  }
}   

Clear-Host

$base = $(Import-Clixml -Path "C:\Amar\Modified_vmdata.xml")
$bla = $(Import-Clixml -Path "C:\Amar\Modified_ADObjects.xml")


 build-FTAudit -ADArray $bla[0..2] -VMwareArray $base[0..2] 


