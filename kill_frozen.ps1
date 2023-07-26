# Скрипт использует 4 двумерных массива [id;working set]
# 1 - текущие данные
# 2 - данные предыдущего прохода (20 сек. назад)
# 3 - если после сравнения данных массива 1 и массива 2 с разницей в 20 секунд количество используемой памяти не поменялось, записываем такие данные в 3 массив
# 4 - если после сравнения данных массива 1 и массива 3 с разницей в 20 секунд количество используемой памяти не поменялось, записываем такие данные в 4 массив
# В следующую итерацию сравниваются массив 1 и массив 4. Если данные в массивах совпадают, значит приложение 60 секунд не использует память. 
# Проверяем по PID нагрузку процесса на процессор, если она больше 1% - значит процесс завис, завершаем процесс.

# инициализируем таблицы
$table1 = @{}
$table2 = @{}
$table3 = @{}
$table4 = @{}
$tabledel = @()
$coresnum = (Get-CimInstance Win32_ComputerSystem).NumberOfLogicalProcessors

while ( $true )
{
	# собираем текущую информацию 
	$inputinfo = Get-CimInstance -classname Win32_PerfformattedData_PerfProc_Process -filter 'name like "itnet2.server.arm%"' -property Name,IDProcess,PercentProcessorTime,WorkingSet | select -property Name,IDProcess,PercentProcessorTime,WorkingSet
	
	# заполняем таблицу 1
	$inputinfo.GetEnumerator() | foreach-object {
		$table1[$_.IDProcess] =  $_.WorkingSet 
	}
	
	# проверяем и удаляем зависшие процессы
	if ($table4.count -gt 0) {
		foreach ($table4key in $table4.keys) {
			$cpuload = (($inputinfo | where-object IDProcess -like $table4key).PercentProcessorTime)/$coresnum
			if ($cpuload -gt 1) {
				$timeout = get-date -format "[yyyy.MM.dd HH:mm:ss]"
				$logfile = $timeout+" Closing process PID "+$table4key
				$outf = Get-WmiObject Win32_Process -Filter "ProcessID LIKE '$table4key'" | Invoke-wmimethod -name terminate
				write-output $logfile >> out.log
			}
		}
	}
		
	# заполняем таблицу 4
	$table4 = @{}
	foreach ($table1key in $table1.keys) {
		if ($table1.$table1key -eq $table3.$table1key) {
			$cpuload = (($inputinfo | where-object IDProcess -like $table1key).PercentProcessorTime)/$coresnum
			if ($cpuload -gt 1) {
				$table4.$table1key = $table1.$table1key
			}
		}
	}
		
	# заполняем таблицу 3
	$table3 = @{}
	foreach ($table1key in $table1.keys) {
		if ($table1.$table1key -eq $table2.$table1key) {
			$cpuload = (($inputinfo | where-object IDProcess -like $table1key).PercentProcessorTime)/$coresnum
			if ($cpuload -gt 1) {
				$table3.$table1key = $table1.$table1key
			}
		}
	}
	
	
	#write-output $table1key " | " $table1.$table1key " | " $table2.$table1key " | " $table3.$table1key " | " $table4.$table1key >> out.log
		
	#write-output "table1: " $table1.count
	#write-output "table2: " $table2.count
	#write-output "table3: " $table3.count
	#write-output "table4: " $table4.count
	$table2 = @{}
	$table2 = $table1
	$table1 = @{}
	#write-output $table1
	
	
	Start-Sleep -s 60
	
}