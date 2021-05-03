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
echo -n > ./object-activity.txt
echo -n > ./identity-activity.txt
for log in $(find . -type f \( -name "access.audit*" -o -name "http-access.audit*" -o -name "ldap-access.audit*" \) -print | sort | cut -d"/" -f1-2 | uniq ); do
   instance="$(echo $log) $(echo $instance)"
done
for i in $(echo "$instance" | tr ' ' '\n' | sort | uniq | tr '\n' ' '); do
    ldaplogs=$(find $i -name "ldap-access.audit*" -print | sort -r)
    httplogs=$(find $i -type f \( -name "access.audit*" -o -name "http-access.audit*" \) -print | sort -r)
    for log in $ldaplogs; do
        echo "Processing $log"
        cat $log | $HOME/bin/jq '.request.operation, .request.dn' | paste -d" " - - | grep -v null  >> ./object-activity.txt
        cat $log | $HOME/bin/jq '.userId, .request.operation, .response.status' | paste -d" " - - - | grep -v null >> ./identity-activity.txt
#        cat $log | $HOME/bin/jq '.request.operation, .request.dn' | paste -d" " - - | grep -v null | sort -k1 | uniq -c | sed -e 's/^[[:space:]]*//' | sort -n -k1 >> ./object-activity.txt
#        cat $log | $HOME/bin/jq '.userId, .request.operation, .response.status' | paste -d" " - - - | grep -v null | sort -k1 | uniq -c | sed -e 's/^[[:space:]]*//' | sort -k2 >> ./identity-activity.txt
    done
    for log in $httplogs; do
        echo "Not processing: $log"
    done
done