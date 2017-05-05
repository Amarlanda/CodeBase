Get-EC2Image -Owners amazon -Filters @{Name = 'name'
 Values = 'Windows_Server-2012-R2*English*'} | Select-Object -Property imageid,name | Format-Table -AutoSize

$AMI = 'ami-dd9eb6ae'

new-EC2Instance -ImageId $AMI -MinCount 1 -MaxCount 1 -KeyName PuppetAccess -SecurityGroups default -InstanceType t2.micro 

