#!/bin/bash
export LC_ALL=""
export LANG="en_US.UTF-8"
SMARTCTL="sudo /usr/sbin/smartctl"

if [[ ${1} == "list" ]]
	then
		JSON="{ \"data\":["
		DRIVES=`${SMARTCTL} --scan-open | awk '// {printf($1"\n")}'`
		RESULT=""
		for DRIVE in ${DRIVES}; do
			SMART=`${SMARTCTL} -a ${DRIVE}`
			if [[ "$SMART" == *"SMART support is: Available"* ]]; then
				DISK_TYPE=""
				SMART1ST=`echo "${SMART}" | awk -F ':' '/Rotation Rate:/ {printf($2)}' | xargs` 
				if [[ "$SMART1ST" == *"Solid State Device"* ]]; then
					DISK_TYPE="ssd"
				elif [[ "$SMART1ST" == *"rpm"* ]]; then
					DISK_TYPE="hdd"
				elif [[ "$SMART" == *"Spin_"* ]]; then 
					DISK_TYPE="hdd"
				elif [[ "$SMART" == *"SSD"* ]]; then 
					DISK_TYPE="ssd"
				elif [[ "$SMART" == *"NVMe"* ]]; then 
					DISK_TYPE="ssd"
				elif [[ "$SMART" == *"177 Wear_Leveling"* ]]; then 
					DISK_TYPE="ssd"
				elif [[ "$SMART" == *"231 SSD_Life_Left"* ]]; then 
					DISK_TYPE="ssd"
				elif [[ "$SMART" == *"233 Media_Wearout_"* ]]; then 
					DISK_TYPE="ssd"
				else 
					DISK_TYPE="other"
				fi
				
				
				if [[ "$DISK_TYPE" == ${2} ]]; then
					flag=0
					SMARTSERIAL=`echo "${SMART}" | awk -F ':' '/Serial Number:/ {printf($2)}' | xargs` 
					for rescount in ${RESULT[@]}
					do
						if [[ "${rescount}" == "${SMARTSERIAL}" ]]; then
							flag=1
						fi
					done
					if [[ ${flag} == "0" ]]; then
						if [[ ${#RESULT[*]} != "1" ]]; then 
							JSON=${JSON}","
						fi
						RESULT+=(${SMARTSERIAL})
						JSON=${JSON}"{\"{#DISKNAME}\":\""${DRIVE}"\",\"{DISKTYPE}\":\""${DISK_TYPE}"\"}"
					fi
				fi
			fi
		done
		JSON=${JSON}"]}"
		echo -e ${JSON}
elif [[ ${1} == "get" ]]
	then
		SMART=`${SMARTCTL} -a ${3}`
		echo "${SMART}"
fi