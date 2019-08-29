#!/bin/bash
SAWMILL_HOME="$HOME/projects/SawMill"
logs=`ls -tr $1*`
firstlog=0
for log in $logs 
do
  if (( $firstlog == 0 ))
  then
    firstlog=1
    java -jar $SAWMILL_HOME/dist/SawMill.jar --poi $SAWMILL_HOME/poi/$2 --cut 100000 --condense $log > $log.csv &
#    java -jar $SAWMILL_HOME/dist/SawMill.jar --poi $SAWMILL_HOME/poi/$2 --cut 1000000 --totals --condense $log > $log.csv &
  else
    java -jar $SAWMILL_HOME/dist/SawMill.jar --poi $SAWMILL_HOME/poi/$2 --cut 100000 --noheader --condense $log > $log.csv &
#    java -jar $SAWMILL_HOME/dist/SawMill.jar --poi $SAWMILL_HOME/poi/$2 --cut 1000000 --totals --noheader --condense $log > $log.csv &
  fi
done
wait
for log in $logs
do
  cat $log.csv >> all.csv
done