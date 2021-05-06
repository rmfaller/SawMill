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
OLDIFS=$IFS
IFS=","
WS=$(pwd)
MIT=$(date +"%Y%m%d%H%M%S")
x=1
instances="opendj-support-data-20210501-020109_usr1,opendj-support-data-20210501-020221_usr2,opendj-support-data-20210501-020325_usr3,opendj-support-data-20210501-020454_usr4"
echo -n "Operation," >totals.csv
for instance in $instances; do
    echo -n "$instance," >>totals.csv
done
echo "" >>totals.csv
x=4
for attr in $(head -1 combine-ldap.csv | cut -d"," -f4-); do
    echo -n "$attr," >>totals.csv
    for instance in $instances; do
        values=$(tail -n+2 combine-ldap.csv | grep $instance | cut -d"," -f$x)
        IFS=$OLDIFS
        v=0
        c=0
        for value in $values; do
            v=$(echo "$v+$value" | bc -l)
            ((c++))
        done
        if [[ $attr == *.time-op ]]; then
            v=$(echo "scale=2; $v/$c" | bc -l)
        fi
        echo -n "$v," | tr -d " " >>totals.csv
    done
    ((x++))
    echo "" >>totals.csv
    IFS=","
done
IFS=$OLDIFS
head -2 totals.csv >total-ops.csv
head -2 totals.csv >total-time.csv
while read dataset; do
    op=$(echo $dataset | cut -d"," -f1)
    if [[ $op == *.ops ]]; then
        echo $dataset >>total-ops.csv
    fi
    if [[ $op == *.time-op ]]; then
        echo $dataset >>total-time.csv
    fi
done <totals.csv

exit

for instance in $instances; do
    x=4
    head -1 combine-ldap.csv | cut -d"," -f4- | tr -s "," "\n" >attr.txt
    for attr in $(head -1 combine-ldap.csv | cut -d"," -f4-); do
        values=$(tail -n+2 combine-ldap.csv | grep $instance | cut -d"," -f$x)
        IFS=$OLDIFS
        v=0
        for value in $values; do
            v=$(echo "$v+$value" | bc -l)
            #        echo "summed $value"
        done
        echo "$attr,$v," | tr -d " " >>totals.$instance.csv
        ((x++))
        IFS=","
    done
done
IFS=$OLDIFS
