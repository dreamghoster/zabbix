#!/bin/bash
export LC_ALL=""
export LANG="en_US.UTF-8"
MEGACLI="sudo /usr/bin/megacli"

if [[ ${1} == "list" ]]
	then
		if [[ ${2} == "virt" ]]
			then
			DRIVES=`${MEGACLI} -LDInfo -LAll -aall -NoLog | awk '/Virtual Drive:/ {printf("VirtualDrive%d\n", $3)}'`
			if [[ -n ${DRIVES} ]]
				then
				JSON="{ \"data\":["
				SEP=""
				for DRIVE in ${DRIVES}; do
					JSON=${JSON}"$SEP{\"{#VIRTDRIVE}\":\"${DRIVE}\"}"
					SEP=", "
				done
				JSON=${JSON}"]}"
				echo ${JSON}
			fi
		elif [[ ${2} == "phys" ]]
			then
			DRIVES=`${MEGACLI} -PDlist -aall -NoLog | awk 'BEGIN {RS="Device ID"; FS=": "} /Slot Number:/ {$2 = cut $2 -f1 -d""; $3 = cut $3 -f1 -d""; printf("DriveSlot" $2 "." $3 "\n")}'`
			if [[ -n ${DRIVES} ]]
				then
				JSON="{ \"data\":["
				SEP=""
				for DRIVE in ${DRIVES}; do
					JSON=${JSON}"$SEP{\"{#PHYSDRIVE}\":\"${DRIVE}\"}"
					SEP=", "
				done
				JSON=${JSON}"]}"
				echo ${JSON}
			fi
		elif [[ ${2} == "adp" ]]
			then
			JSON="{ \"data\":["
			SEP=""
			ADPS=`${MEGACLI} -adpcount -NoLog | grep "Controller Count" | sed -e 's/Controller Count://g' -e 's/\.//g' | xargs`
			for ((i=1; i <= ${ADPS} ; i++))
				do
					JSON=${JSON}"$SEP{\"{#ADPNUMBER}\":\"$(($i-1))\"}"
					SEP=", "
			done
			JSON=${JSON}"]}"
			echo ${JSON}
		fi	
elif [[ ${1} == "get" ]]
	then
		if [[ ${2} == "virt" ]]
			then
				DRIVE=`echo ${3} | sed s/VirtualDrive//g | xargs`
				RESULT=`${MEGACLI} -LDInfo -L${DRIVE} -aall -NoLog`				
				echo "${RESULT}"		
		elif [[ ${2} == "phys" ]]
			then
				DRIVE=`echo ${3} | sed -e s/DriveSlot//g -e 's/\./:/g' | xargs`
				RESULT=`${MEGACLI} -PDInfo -PhysDrv [${DRIVE}] -aall -NoLog`
				echo "${RESULT}"
		elif [[ ${2} == "adp" ]]
			then
				RESULT=`${MEGACLI} -adpallinfo -a${3} -NoLog`				
				echo "${RESULT}"
		elif [[ ${2} == "bbu" ]]
			then
				RESULT=`${MEGACLI} -adpbbucmd -a${3} -NoLog`				
				echo "${RESULT}"	
				
		fi
fi