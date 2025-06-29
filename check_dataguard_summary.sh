#!/bin/bash

. /home/oracle/.bashrc

getInfo_dgmgrl(){
  while read -a line;
  do
    if [[ "${line[2]}" == *"Primary"* ]]; 
    then
      echo "${line[0]}"
    elif [[ "${line[2]}" == *"Physical"* ]];
    then
      echo "${line[0]}"
    fi
  done <<< $1
}

check_output=$(getInfo_dgmgrl "`dgmgrl -silent /  "show configuration"`")

set ${check_output}
PRY=$1
STB=$2

LAG=`dgmgrl -silent /  "show configuration lag" | grep -ie 'transport' -ie 'apply' | sed 's/^[[:space:]]*//'`
STATUS=`dgmgrl -silent /  "show configuration" | grep -i status | awk 'END{print}'  | sed 's/^[[:space:]]*//' | awk '{printf $1}'`

SUMMARY_DATAGUARD=`
   dgmgrl -silent /  "show database '${PRY}' 'StatusReport'" | grep ORA | awk -F"ERROR|WARNING" '{ print $2 }' | \
   awk -v primary="${PRY}" '
   {
            printf "Primary database: " primary "\n"
	    printf "Errores encontrados:"
            if ( $0 != "") {
             printf $0
            } else {
             printf "sin errores"
            }
            printf "\n\n"
   }
' &&
   dgmgrl -silent /  "show database '${STB}' 'StatusReport'" | grep ORA | awk -F"ERROR|WARNING" '{ print $2 }' | \
   awk -v standby="${STB}" '
   {
            printf "Standby database: " standby "\n"
            printf "Errores encontrados:"
            if ( $0 != "") {
             printf $0
            } else {
             printf "sin errores"
            }

   }
'`

if [[ ! "${STATUS}" =~ "SUCCESS" ]]; then
printf "Resumen de errores Dataguard\n\nFecha de Inicio=$(date '+%d-%m-%Y %H:%M:%S')\n\nStatus=${STATUS}\n\n${SUMMARY_DATAGUARD}\n\n${LAG}" | mailx -s "[${ORACLE_UNQNAME}] Summary Dataguard" ${EMAIL}
fi
