$out_result = ""

##Disable PC accounts, unavailable more than 2 month
$date_off=(Get-Date).AddDays(-60)
$AD_list1 = & Get-ADComputer -Filter {enabled -eq "True" -and LastLogonDate -lt $date_off} 
ForEach ($Ad_list1i in $AD_list1) {
    Set-ADComputer -Identity $Ad_list1i -Enabled $false -WhatIf
    $out_result += "PC " + $Ad_list1i.DistinguishedName + " was disabled due to inactivity for 60 days" + "`n"
}
#Remove PC accounts, unavailable more than 4 month
$date_off2=(Get-Date).AddDays(-120)
$AD_list2 = & Get-ADComputer -Filter {enabled -eq "True" -and LastLogonDate -lt $date_off2} 
ForEach ($Ad_list2i in $AD_list2) {
    Remove-ADComputer -Identity $Ad_list2i -Confirm -WhatIf 
    $out_result += "PC " + $Ad_list2i.DistinguishedName + " was removed due to inactivity for 120 days" + "`n"
}

###Move PC accounts to their folder depending on their IP
#Get branches list and subnets from file to array
$branches=Get-Content .\branches.txt | foreach { , ($_ -split ',')}
#Get computers from AD
$Computers = Get-ADComputer -Filter {enabled -eq "True"} -Properties IPv4Address | Where {$_.DistinguishedName -notlike '*Domain Controllers*' -and $_.DistinguishedName -notlike '*Servers*'}
ForEach ($Computer in $Computers) {
    if ($Computer.IPv4Address -ne $null) {
        #next 3 lines transformes IP address to UInt32 for comparison possibilities
        $ip = [System.Net.IPAddress]::Parse($Computer.IPv4Address).GetAddressBytes()
        [array]::Reverse($ip)
        $ip = [System.BitConverter]::ToUInt32($ip, 0)
        foreach ($branch in $branches) {
            $subnet_start = [System.Net.IPAddress]::Parse($branch[1]).GetAddressBytes()
            [array]::Reverse($subnet_start)
            $subnet_start = [System.BitConverter]::ToUInt32($subnet_start, 0)
            $subnet_end = [System.Net.IPAddress]::Parse($branch[2]).GetAddressBytes()
            [array]::Reverse($subnet_end)
            $subnet_end = [System.BitConverter]::ToUInt32($subnet_end, 0)
            $OU_name = "OU=" + $($branch[0]) + "PC,OU=" + $($branch[0]) + ",DC=nibulon,DC=com"
            if ($ip -ge $subnet_start -and $ip -le $subnet_end) {
                if ($Computer.DistinguishedName -notlike "*$($branch[0])*") {
                    Move-ADObject -Identity $Computer -TargetPath $OU_name -WhatIf
                    $out_result += "PC " + $Computer.DistinguishedName + " was moved to " + $OU_name + "`n"
                } 
                break
           }
        }
    }
}


#Disable User accounts, unavailable more than 3 month
$date_off3=(Get-Date).AddDays(-90)
$AD_list3 = & Get-ADUser -Filter {enabled -eq "True" -and LastLogonDate -lt $date_off3 -and Name -notlike "*admin"} | Where {$_.distinguishedName -notlike '*Service*'} 
ForEach ($AD_list3i in $AD_list3) {
    Set-ADUser -Identity $AD_list3i -Enabled $false -WhatIf 
    $out_result += "User account " + $AD_list3i.DistinguishedName + " was disabled due to inactivity for 90 days" + "`n"
}

#Remove User accounts, unavailable more than 6 month
$date_off4=(Get-Date).AddDays(-180)
$AD_list4 = & Get-ADUser -Filter {enabled -eq "True" -and LastLogonDate -lt $date_off4 -and Name -notlike "*admin"} | Where {$_.distinguishedName -notlike '*Service*'} 
ForEach ($AD_list4i in $AD_list4) {
    Remove-ADUser -Identity $AD_list4i -Confirm -WhatIf
    $out_result += "User account " + $Ad_list4i.DistinguishedName + " was removed due to inactivity for 120 days" + "`n"
}

#Send ticket with changes
$OSticket_json = @{
    alert = "true";
    name = "Active Directory";
    email = "prox@nibulon.com.ua";
    source = "API";
    autorespond = "true";
    subject = "AD Changes";
    ip = "192.168.171.121";
    message = $out_result; 
} | ConvertTo-Json
$OSticket_URI = "http://osticket.nibulon.com/api/tickets.json"
$OSticket_API_key = "90E9A9ECB62E4982FCE5D6E47AC98ED0"
$HTTPResponse = Invoke-WebRequest -Uri $OSticket_URI -Headers @{ "X-API-Key" = $($OSticket_API_key) } -Body $OSticket_json -UseDefaultCredentials -Method Post -ContentType "application/json;charset=utf-8" -ErrorAction Stop

if ($HTTPResponse.StatusCode -ne 201) {
    echo $($HTTPResponse.RawContent) >> result.txt
}
