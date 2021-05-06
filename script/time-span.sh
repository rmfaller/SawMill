#!/bin/bash
#
# DISCLAIMER: The sample code described herein is provided on an "as is" basis,
# without warranty of any kind, to the fullest extent permitted by law.
# ForgeRock does not warrant or guarantee the individual success developers may
# have in implementing the sample code on their development platforms or
# in production configurations.
#
# ForgeRock does not warrant, guarantee or make any representations regarding the
# use, results of use, accuracy, timeliness or completeness of any data or
# information relating to the sample code. ForgeRock disclaims all warranties,
# expressed or implied, and in particular, disclaims all warranties of merchantability,
# and warranties related to the code, or any service or software related thereto.
#
# ForgeRock shall not be liable for any direct, indirect or consequential damages or
# costs of any type arising out of any action taken by you or others related to the sample code.
#

for log in $(find . -type f \( \( -name "access.audit*" -o -name "http-access.audit*" -o -name "ldap-access.audit*" \) -a -not -name "*.txt" -a -not -name "*.extended" -a -not -name "*.tmp" \) -print | sort | cut -d"/" -f1-2 | uniq ); do
   echo $log
   instance="$(echo $log) $(echo $instance)"
#done
#for i in $(echo "$log" | tr ' ' '\n' | sort | uniq | tr '\n' ' '); do
    ldaplogs=$(find . -type f \( \( -name "ldap-access.audit*" \) -a -not -name "*.txt" -a -not -name "*.extended" -a -not -name "*.tmp" \) -print | sort -r)
    firstldaplog=$(echo "$ldaplogs" | tr ' ' '\n' | head -1)
    lastldaplog=$(echo "$ldaplogs" | tr ' ' '\n' | tail -1)
    httplogs=$(find . -type f \( \( -name "access.audit*" -o -name "http-access.audit*" \) -a -not -name "*.txt" -a -not -name "*.extended" -a -not -name "*.tmp" \) -print | sort -r)
    firsthttplog=$(echo "$httplogs" | tr ' ' '\n' | head -1)
    lasthttplog=$(echo "$httplogs" | tr ' ' '\n' | tail -1)
    logs="$firstldaplog $firsthttplog"
    for log in $logs; do
        echo "Last time stamp: $log -> $(tail -1 $log | ~/bin/jq '.timestamp')"
        fts="$(tail -1 $log | ~/bin/jq '.timestamp') $(echo $fts)"
    done
    for log in $logs; do
        echo "First time stamp: $log -> $(head -1 $log | ~/bin/jq '.timestamp')"
        lts="$(head -1 $log | ~/bin/jq '.timestamp') $(echo $lts)"
    done
    logs="$lastldaplog $lasthttplog"
   echo "--------------------------" 
done
ifts="$(echo $fts | tr ' ' '\n' | sort -r | head -1)"
ilts="$(echo $lts | tr ' ' '\n' | sort -r | head -1)"
echo "Inclusive last time stamp  = $ifts"
echo "Inclusive first time stamp = $ilts"
