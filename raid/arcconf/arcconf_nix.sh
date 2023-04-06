#!/bin/bash
export LC_ALL=""
export LANG="en_US.UTF-8"
ARCCONF="sudo /usr/Arcconf/arcconf"

if [[ ${1} == "list" ]]
	then
		if [[ ${2} == "virt" ]]
			then
			ADPS=`${ARCCONF} getconfig nologs | grep "Controllers found" | sed -e 's/Controllers found://g' -e 's/\.//g' | xargs`
			for ((i=1; i <= ${ADPS} ; i++))
				do
					DRIVES=`${ARCCONF} GETCONFIG ${ADPS} LD nologs | awk '/Logical Device number/ {printf("VirtualDrive%d\n", $4)}'`
					if [[ -n ${DRIVES} ]]
						then
							JSON="{ \"data\":["
							SEP=""
							for DRIVE in ${DRIVES}; do
								JSON=${JSON}"$SEP{\"{#VIRTDRIVE}\":\"${DRIVE}:${ADPS}\"}"
								SEP=", "
							done
					fi
			done
			JSON=${JSON}"]}"
			echo ${JSON}		
		elif [[ ${2} == "phys" ]]
			then
			ADPS=`${ARCCONF} getconfig nologs | grep "Controllers found" | sed -e 's/Controllers found://g' -e 's/\.//g' | xargs`
			for ((i=1; i <= ${ADPS} ; i++))
				do
					DRIVES=`${ARCCONF} GETCONFIG ${ADPS} PD nologs | awk 'BEGIN {RS="Device #"} {if ($0 ~ /NCQ/) print $0}' | sed 's/([0-9].*//g' | awk '/Reported Channel,Device/ {printf ("DriveSlot%s\n", $4)}' | sed 's/\,/\./g' `
					if [[ -n ${DRIVES} ]]
						then
							JSON="{ \"data\":["
							SEP=""
							for DRIVE in ${DRIVES}; do
								JSON=${JSON}"$SEP{\"{#PHYSDRIVE}\":\"${DRIVE}:${ADPS}\"}"
								SEP=", "
							done
					fi
			done
			JSON=${JSON}"]}"
			echo ${JSON}
		elif [[ ${2} == "adp" ]]
			then
			JSON="{ \"data\":["
			SEP=""
			ADPS=`${ARCCONF} getconfig nologs | grep "Controllers found" | sed -e 's/Controllers found://g' -e 's/\.//g' | xargs`
			for ((i=1; i <= ${ADPS} ; i++))
				do
					JSON=${JSON}"$SEP{\"{#ADPNUMBER}\":\"$i\"}"
					SEP=", "
			done
			JSON=${JSON}"]}"
			echo ${JSON}
		fi	
elif [[ ${1} == "get" ]]
	then
		if [[ ${2} == "virt" ]]
			then
				DRIVE=`echo ${3} | sed -E -e 's/VirtualDrive//g' -e 's/:.+//g'`
				ADAPTER=`echo ${3} | sed -E 's/.+://g'`
				RESULT=`${ARCCONF} getconfig ${ADAPTER} LD ${DRIVE} nologs`				
				echo "${RESULT}"		
		elif [[ ${2} == "phys" ]]
			then
				DRIVE=`echo ${3} | sed -E -e 's/DriveSlot/channel=\"/g' -e 's/\./\" id=\"/g' -e 's/:.+//g' -e 's/$/\"/g' -e 's/^/<PhysicalDriveSmartStats /g'`
				ADAPTER=`echo ${3} | sed -E 's/.+://g'`
				DRIVE1=`echo ${3} | sed -E -e 's/DriveSlot//g' -e 's/:.+//g' -e 's/\./,/g' -e 's/$/[(]/g'`
				RESULT=`${ARCCONF} getconfig ${ADAPTER} PD nologs | awk -v pat="${DRIVE1}" 'BEGIN {RS="Device #"} {if (($0 ~ /NCQ/) && ($0 ~ pat)) print $0}'`
				RESULT+=`${ARCCONF} getsmartstats ${ADAPTER} nologs | sed -n "/${DRIVE}/, /<\/PhysicalDriveSmartStats>/p"`
				echo "${RESULT}"
		elif [[ ${2} == "adp" ]]
			then
				RESULT=`${ARCCONF} getconfig ${3} ad nologs`
				echo "${RESULT}"
		elif [[ ${2} == "bbu" ]]
			then
				RESULT=`${ARCCONF} getconfig ${3} ad nologs | sed -n "/Controller Battery Information/, //p"`				
				echo "${RESULT}"
		fi
fi