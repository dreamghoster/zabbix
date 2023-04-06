#!/bin/bash
export LC_ALL=""
export LANG="en_US.UTF-8"
IFS=$'\n'
result=`cat /etc/asterisk/pjsip.endpoint.conf | awk '/callerid=/ {gsub("callerid=",""); gsub(">",""); print($0"\n")}'`

output=$"<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
output+='\n'
output+='<AddressBook>\n'
for line in ${result[@]}
do
  namevar=${line%<*} 
  numbervar=${line##*<}
  output+='\t<Contact>\n'
  output+='\t\t<LastName>'${namevar%.*}.'</LastName>\n'
  output+='\t\t<FirstName></FirstName>\n'
  output+='\t\t<Phone>\n'
  output+='\t\t\t<phonenumber>'${numbervar}'</phonenumber>\n'
  output+='\t\t\t<accountindex>1</accountindex>\n'
  output+='\t\t</Phone>\n'
  output+='\t</Contact>\n'
done
output+='</AddressBook>'
echo -e "$output" > /var/www/prov/phonebook/phonebook.xml