#!/bin/bash
export LC_ALL=""
export LANG="en_US.UTF-8"
SMARTCTL="sudo /usr/sbin/smartctl"
MDADM="sudo /usr/sbin/mdadm"

if [[ ${1} == "list" ]]
	then
		JSON="{\"data\":["
		RESULT=""
		RAIDS=`cat /proc/mdstat | grep " active" | awk -F ':' '// {printf($1"\n")}' | xargs`
		for RAID in ${RAIDS}; do
			if [[ ${RESULT} != "" ]]; then 
				RESULT=${RESULT}","
			fi
			RESULT=${RESULT}"{\"{#RAIDNAME}\":\"/dev/"${RAID}"\"}"
			
		done
		JSON=${JSON}${RESULT}"]}"
		echo -e ${JSON}
elif [[ ${1} == "get" ]]
	then
		RAIDS=`${MDADM} --detail ${3}`
		if [[ "${2}" == "state" ]]; then
			RESULT=`echo "${RAIDS}" | awk -F ':' '/State :/ {printf($2"\n")}' | xargs`
		elif [[ "${2}" == "fdevices" ]]; then
			RESULT=`echo "${RAIDS}" | awk -F ':' '/Failed Devices :/ {printf($2"\n")}' | xargs`
		elif [[ "${2}" == "rdevices" ]]; then
			RESULT=`echo "${RAIDS}" | awk -F ':' '/Raid Devices :/ {printf($2"\n")}' | xargs`
		fi
			echo ${RESULT}
fi