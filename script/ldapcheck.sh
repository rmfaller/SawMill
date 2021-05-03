#!/bin/bash
echo "From $(pwd)"
fts=$(head -1 $(find . -type f \( \( -name "ldap-access.audit.json.*" \) -a -not -name "*.txt" -a -not -name "*.extended" -a -not -name "*.tmp" \) -print | sort | head -1) | ~/bin/jq -r '.timestamp')
lts=$(tail -1 ldap-access.audit.json | ~/bin/jq -r '.timestamp')
echo "First timestamp = $fts"
echo "Last timestamp  = $lts"
files="./ldap-access.audit.json*"
ops="ABANDON ADD BIND DELETE MODIFY MODIFYDN SEARCH"
status="SUCCESSFUL FAILED"
total=0
for op in $ops; do
    for stat in $status; do
        x=$(grep $op $files | grep $stat | wc -l | tr -d '\n') 
        y=$(grep $op $files | grep $stat | grep "\"opType\":\"sync\"" | wc -l | tr -d '\n') 
        if [ $op = "SEARCH" ]; then
            u=$(grep $op $files | grep $stat | grep "\"additionalItems\":" | grep "\"unindexed\"" | wc -l | tr -d '\n') 
            p=$(grep $op $files | grep $stat | grep "\"additionalItems\":" | grep "\"persistent\"" | wc -l | tr -d '\n') 
        fi
        if [ $op = "SEARCH" ]; then
            printf "%-22s %'.f\n" "$op-$stat =" "$x"
            if [ $u -gt 0 ]; then
                printf "%-22s %'.f\n" "  unindexed =" "$u"
            fi
            if [ $p -gt 0 ]; then
                printf "%-22s %'.f\n" "  persistent =" "$p"
            fi
        else
            if (($y == 0)); then
                printf "%-22s %'.f\n" "$op-$stat =" "$x"
            else
                printf "%-22s %'.f\n" "$op-$stat =" "$x"
                printf "%-22s %'.f\n" "  sync received  =" "$y"
                printf "%-22s %'.f\n" "  replicated out =" "$(($x - $y))"
            fi
        fi
        total=$((total + x))
    done
done
printf "%-22s %'.f\n" "total operations =" "$total"
