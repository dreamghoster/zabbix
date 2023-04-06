#1 arg = "list" (of disk) or "get" (smart)
$megacli = "$Env:Programfiles\zabbix\megacli.exe"

$json = ""

if ($args[0] -eq "list") {
	if ($args[1] -eq "virt") {
		$drives = & $megacli "-LDInfo -LAll -aall -NoLog" | select-string -pattern "Virtual Drive:" | % {$_ -replace 'Virtual Drive:(.*)\((.*)', '$1'} | % {$_.trim()}
		if ($drives.count -gt 0) {
			$json = "{ `"data`":["
			$sep = ""
			foreach ($drive in $drives) {
				$json = $json + $sep + "{`"{#VIRTDRIVE}`":`"VirtualDrive" + $drive + "`"}"
				$sep = ", "
			}
			$json = $json + "]}"
			write-host $json
		}
	} elseif ($args[1] -eq "phys") {
		$drives = & $megacli "-PDlist -aall -NoLog" | select-string -pattern '^(Enclosure Device)|(Slot Number)' | % {$_ -replace '^.*:(.*)', '$1'} | % {$_.trim()}
		$check = 0
		$result = ""
		$json = "{ `"data`":["
		$sep = ""
		foreach ($drive in $drives) {
			if ($check -eq 0) {
				$result = $drive
				$check = 1
			} else {
				$result = $result + "." + $drive
				$check = 0
				$json = $json + $sep + "{`"{#PHYSDRIVE}`":`"DriveSlot" + $result + "`"}"
				$sep = ", "
			}
		}
		$json = $json + "]}"
		write-host $json
	} elseif ($args[1] -eq "adp") {
		$adps = & $megacli "-adpcount -NoLog" | select-string -pattern 'Controller Count' | % {$_ -replace '^.*:.*(\d+)\.', '$1'} | % {$_.trim()}
		$json = "{ `"data`":["
		$sep = ""
		for ($i=0; $i -lt $adps; $i++) {
			$json = $json + $sep + "{`"{#ADPNUMBER}`":`"" + $i + "`"}"
			$sep = ", "
		}
		$json = $json + "]}"
		write-host $json
	}	

} elseif ($args[0] -eq "get") {
	if ($args[1] -eq "virt") {
		$drive = $args[2] -replace 'VirtualDrive(.*)','$1'
		$result = & $megacli "-LDInfo -L"$drive "-aall -NoLog"
	} elseif ($args[1] -eq "phys") {
		$drive = $args[2] -replace 'DriveSlot(.*)\.(.*)','$1:$2'
		$result = & $megacli "-PDInfo -PhysDrv ["$drive"] -aall -NoLog"
	} elseif ($args[1] -eq "adp") {
		$result = & $megacli "-adpallinfo -a"$args[2] "-NoLog"
	} elseif ($args[1] -eq "bbu") {
		$result = & $megacli "-adpbbucmd -a"$args[2] "-NoLog"
	}
	foreach ($line in $result) {
		$json += $line + "`n"
	}
	write-host $json
} 