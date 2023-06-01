#1 arg = "list" (of disk) or "get" (smart)
$smartctl = "$Env:Programfiles\zabbix\smartctl.exe"

if ($args[0] -eq "list") {
	write-host "{"
	write-host " `"data`":["
	$smart_scanresults = & $smartctl "--scan-open"
	$disklist = @()
	$result = @()
	$resultcounter = 0
	#filter disks by name
	foreach ($smart_scanresult in $smart_scanresults) {
		$disklist += ($smart_scanresult -split " ")[0]
	}
	#filter disks by second incoming arg
	foreach ($disk in $disklist) {
		$smart = & $smartctl "-a" $disk 
		if ($smart -like "*SMART support is: Available*") {
			$disk_type = ""
			$smart1st = $smart | select-string "Rotation Rate:"
			if ($smart1st -like "*Solid State Device*") {$disk_type = "ssd"}
			elseif ($smart1st -like "*rpm*") {$disk_type = "hdd"}
			else {
				if ($smart | select-string "Spin_" -CaseSensitive){
				$disk_type = "hdd"
				}
				elseif ($smart | select-string "SSD" -CaseSensitive){
					$disk_type = "ssd"
				}
				elseif ($smart | select-string "NVMe" -CaseSensitive){
					$disk_type = "ssd"
				}
				elseif ($smart | select-string "177 Wear_Leveling" -CaseSensitive) {
					$disk_type = "ssd"
				}
				elseif ($smart | select-string "231 SSD_Life_Left" -CaseSensitive) {
					$disk_type = "ssd"
				}
				elseif ($smart | select-string "233 Media_Wearout_" -CaseSensitive) {
					$disk_type = "ssd"
				}
				else {
					$disk_type = "other"
				}
			}
			if ($disk_type -eq $args[1]) {
				$smartserial = $smart | select-string "Serial Number:" 
				if ($result -like $smartserial) {
				} else { 
					$result += $smartserial
					$json = ""
					if ($resultcounter -ne 0) 
					{
						write-host ","
					}
					$json += "`t {`n " +
					"`t`t`"{#DISKNAME}`":`""+$disk+"`""+ ",`n" +
					"`t`t`"{#DISKTYPE}`":`""+$args[1]+"`""+ "`n" +
					"`t }"  		
					write-host $json
					$resultcounter = $resultcounter + 1
				}
			}		
		}			
	}
	write-host " ]"
	write-host "}"
} elseif ($args[0] -eq "get") {
	$smart = & $smartctl "-a" $args[2]
	$json = ""
	foreach ($line in $smart) {
		$json += $line + "`n"
	}		
	write-host $json
} 