#!/bin/bash
backupdir="/backup/mikrotik/"
log_file="/backup/mikrotik/backuplog.log"
routers=(`cat /backup/mikrotik/mikrotik_list.txt`)
privatekey="/root/.ssh/id_rsa"
login="becky"
current_date="`date '+%Y-%m-%d'`"
echo "---------------------------------------" >> ${log_file}
echo "`date '+%Y-%m-%d-%T'` Backup sequence started." >> ${log_file}
for router in ${routers[@]}; do
	mkdir -p /backup/mikrotik/$router
	echo "`date '+%Y-%m-%d-%T'` Starting backup of ${router}" >> ${log_file}
	ssh ${login}@$router -i $privatekey "/system backup save name=${router}-${current_date}.backup" > /dev/null
	ssh ${login}@$router -i $privatekey "/export file=${router}-${current_date}.rsc" > /dev/null
	scp -i $privatekey ${login}@${router}:${router}-${current_date}.backup ${backupdir}/$router/$router-$current_date.backup > /dev/null
	scp -i $privatekey ${login}@${router}:${router}-${current_date}.rsc ${backupdir}/$router/$router-$current_date.rsc > /dev/null
	if [[ -f "${backupdir}/$router/$router-$current_date.backup" ]];
	then
		echo "`date '+%Y-%m-%d-%T'` Backup created successfully on $router" >> ${log_file}
	else
		echo "`date '+%Y-%m-%d-%T'` Backup failed on $router" >> ${log_file}
	fi
	ssh ${login}@$router -i $privatekey "/file remove [find name=\"${router}-${current_date}.backup\"]" > /dev/null
	ssh ${login}@$router -i $privatekey "/file remove [find name=\"${router}-${current_date}.rsc\"]" > /dev/null
done
echo "`date '+%Y-%m-%d-%T'` Backup sequence completed." >> ${log_file}