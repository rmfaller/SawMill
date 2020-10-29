#!/bin/bash
date
# files="/mnt/opt/opendj/logs/ldap-access.audit.json*"
files="./ldap-access.audit.json*"
ops="ABANDON ADD BIND DELETE MODIFY MODIFYDN SEARCH"
status="SUCCESSFUL FAILED"
total=0
for op in $ops; do
    for stat in $status; do
        x=$(grep $op $files | grep $stat | wc -l | tr -d '\n')
        y=$(grep $op $files | grep $stat | grep "\"opType\":\"sync\"" | wc -l | tr -d '\n')
        #       x=$(grep $op $files  | wc -l | tr -d '\n')
        if (($y == 0)); then
            printf "%-22s %'.f\n" "$op-$stat =" "$x"
        else
            printf "%-22s %'.f\n" "$op-$stat =" "$x"
            printf "%-22s %'.f\n" "  sync received  =" "$y"
            printf "%-22s %'.f\n" "  replicated out =" "$(($x - $y))"
        fi
        total=$((total + x))
    done
done
printf "%-22s %'.f\n" "total operations =" "$total"
