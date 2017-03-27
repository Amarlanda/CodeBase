$ParamsRootFolder = "C:\Users\-oper-rminnis\Downloads\param_files"

$SIDs = @{
	AdobeDoc = @{
		Prod = "PAL"
		Staging = "SAE"
	}
	CRM = @{
		Prod = "PCL"
		Staging = "SCE"
	}
	ECC = @{
		Prod = "PEL"
		Staging = "SEE"
	}
	Mobility = @{
		Prod = "PML"
		Staging = "SME"
	}
	EP = @{
		Prod = "PPL"
		Staging = "SPE"
	}
	ProcessIntg = @{
		Prod = "PXL"
		Staging = "SXE"
	}
}

$SIDs.GetEnumerator() | ForEach-Object {
	$SID = $_
	$SID.Value | ForEach-Object {
		$Prod = $_.Prod
		$Staging = $_.Staging
		If (Test-Path ($ParamsRootFolder + "\" + $Prod)) {
			Copy-Item -Path ($ParamsRootFolder + "\" + $Prod) -Destination ($ParamsRootFolder + "\" + $Staging).ToLower() -Container -Recurse
		}
		Set-Location -Path ($ParamsRootFolder + "\" + $Staging)
		Get-ChildItem -Recurse | Where-Object {$_.PSIsContainer -eq $False} | ForEach-Object {
			(Get-Content $_.FullName) | ForEach-Object {$_ -replace $Prod, $Staging} | Set-Content $_.FullName
		}
	}
}