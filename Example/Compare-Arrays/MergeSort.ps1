$t=Get-Process #Property to match ProcessName
$t2=Get-Service #Property to match Name
$t.ForEach({
        $n=$psitem.ProcessName
        $t2.where({$psitem.name -like (“*{0}*” -f $n)})
})
Now lets measure that.
$loopLikeTime=Measure-Command { #loop in loop
    $t.ForEach({
        $n=$psitem.ProcessName
        $t2.where({$psitem.name -like (“*{0}*” -f $n)})
    })
}
Ticks             : 6269272
And just to be fair lets measure -eq
$loopTime=Measure-Command { #loop in loop
    $t.ForEach({
        $n=$psitem.ProcessName
        $t2.where({$psitem.name -eq $n})
    })
}
Ticks             : 3954131
Okey we have a winner. But what did we just do? We looped through the processes and for each process we looped through all the services.
$t.Length
$t2.Length
In my case 103 processes and 203 services, lets do some simple math 103 * 203 = 20909 loops in just 651ms.
But when when you have big arrays this will be somewhat time consuming. Imagine two 20000 row arrays, 20k times 20k is 400M loops. My calculator says 3,4Hours!!!
What you need to do to speed this up, is to index one of the arrays. Normally the array is indexed from zero to the end of the array. $t[0], $t[1], $t[2..20] and so on. Somewhere in there vi have a process named iexplore but we don’t know where. So lets turn this around, lets move the index to the property and move the name property to the index
“$t[23].value -> iexplore” into “$t[‘iexplore’].value -> 23”. Therefore we can now access the index without searching for the property name and then be able to use the index on the original variable to get all the properties in no time.
$indexTime=Measure-Command { #index time
    $i=0
    $id=@{}
    $t2.ForEach({
        $id[“$($psitem.name)“]=$i #Create $var[name]=index
        $i++
    })
}
$LoopIndexTime=Measure-Command { #Loop index (on Jon Jander drogs)
    $t.ForEach({
        try{$t2[($id[$psitem.ProcessName])]} catch {}
    })
}
Now we have.
$indexTime + $LoopIndexTime
Ticks             : 979612
It’s a lot faster. Lets build a 20000 row big object index.
[object[]]$Proof=$null
$Proof=(0..20000).foreach{
    $temp=New-Object System.Object
    $temp | Add-Member -MemberType NoteProperty -Name Name -Value ([guid]::NewGuid())
    $temp | Add-Member -MemberType NoteProperty -Name Secret  -Value (Get-Random -Maximum 100 -Minimum 0)
    return $temp
}
$20000Time=Measure-Command { #Index 20000 rows
    $i=0
    $Proofid=@{} #Index Proof
    $Proof.ForEach({
        $Proofid[“$($psitem.Name)“]=$i #Create $var[name]=index
        $i++
    })
}
Less than 1sec. 🙂
But it doesn’t do anything?!?!
Thats right, here’s the complete code of my super fast way to show all running processes and services in one object array.
$t=Get-Process #Property to match ProcessName
$t2=Get-Service #Property to match Name
$i=0
$id=@{}
$t2.ForEach({
    $id[“$($psitem.name)“]=$i #Create $var[name]=index
    $i++
})
$t.ForEach({
    $this=$psitem
    $r = New-Object System.Object
    $temp=$null
    try{
        $temp=$t2[($id[$psitem.ProcessName])]
    }
    catch {}
    finally {
        $r | Add-Member -MemberType NoteProperty -Name status -Value $temp.Status
        $r | Add-Member -MemberType NoteProperty -Name DisplayName -Value $temp.DisplayName
        $r | Add-Member -MemberType NoteProperty -Name Name -Value $this.Name
        $r | Add-Member -MemberType NoteProperty -Name Handles -Value $this.Handles
    }
    return $r
}) | sort status | select -Last 30