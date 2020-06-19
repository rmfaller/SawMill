#!/bin/bash
SAWMILL_HOME="$HOME/projects/SawMill"
logs=`ls -tr $1*`
firstlog=0
for log in $logs 
do
  if (( $firstlog == 0 ))
  then
    firstlog=1
   java -jar $SAWMILL_HOME/dist/SawMill.jar --poi $SAWMILL_HOME/poi/$2 --cut 1000 --filltimegap --condense $log > $log.csv &
#   java -jar $SAWMILL_HOME/dist/SawMill.jar --poi $SAWMILL_HOME/poi/$2 --cut 3000000 --sla --totals --condense $log > $log.csv &
  else
   java -jar $SAWMILL_HOME/dist/SawMill.jar --poi $SAWMILL_HOME/poi/$2 --cut 1000 --noheader --filltimegap --condense $log > $log.csv &
#   java -jar $SAWMILL_HOME/dist/SawMill.jar --poi $SAWMILL_HOME/poi/$2 --cut 3000000 --sla --totals --noheader --condense $log > $log.csv &
# java -jar ./dist/SawMill.jar --poi ./poi/ldap-json.json --totalsonly --condense /Users/rmfaller/accounts/carnival/cts-az1-support-data/logs/ldap-access.audit.json.20190918011955 --sla --html > $HOME/tmp/out.html
  fi
done
wait
for log in $logs
do
  cat $log.csv >> all.csv
done