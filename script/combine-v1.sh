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

SAWMILLHOME="$HOME/projects/SawMill"
SCRIPTHOME="$SAWMILLHOME/script"
SMWORKSPACE="$HOME/sawmill"
JAR="jar"
JQ="$HOME/bin/jq"
H0="{ \"timestampformat\":\"yyyy-MM-dd"
H1="'T'"
H2="HH:mm:ss\",\"fielddelimiter\":\"JSON\",\"timestampfield\":\"timestamp\",\"timescale\":\"elapsedTimeUnits\",\"poi\":"
JSONHEADER=$H0$H1$H2
MIT=$(date +"%Y%m%d%H%M%S")
RPT="rpt$MIT"
TMP="tmp$MIT"
POI="poi$MIT"
firstrun=false
FILENAME=${FULLFILENAME%.*}
FILENAMEONLY=${FILENAME##*/}

CREATESUMMARY=true
CREATEGRAPH=true
ALLLOGS=true
DSEXTRACT=true
IDASSESS=true
IPASSESS=true
OBJECTASSESS=true
TXIDASSESS=false
LDAPCUT=60000
HTTPCUT=60000
WS=$(pwd)
DATA="$WS"

create_graph() {
    echo -n "Generating $1 operation graph..."
    files=$(find $WS -name all$1ops.csv -print)
    java -jar $SAWMILLHOME/dist/SawMill.jar --laminate $files >$WS/all$1.csv
    $SCRIPTHOME/chartprep.sh $WS/all$1.csv
    cat $SAWMILLHOME/content/chartheader.phtml $WS/opscolumns.data $WS/etimescolumns.data $WS/ops.data $WS/etimes.data $SAWMILLHOME/content/charttailer.phtml >$WS/all$1.html
    echo "</body></html>" >>$WS/all$1.html
    echo "...completed"
}

# Main script

if [ "$ALLLOGS" = true ]; then
    rotatedldaplogs=$(find $DATA -type f \( -name "ldap-access.audit.json.*" -a -not -name "*.txt" -a -not -name "*.extended" -a -not -name "*.tmp" \) -print | sort)
    if [ -z "$rotatedldaplogs" ]; then
        ldaplogs="$(find $DATA -name "ldap-access.audit.json" -print)"
    else
        onelog=$(find $DATA -name "ldap-access.audit.json" -print)
        ldaplogs="$(echo $rotatedldaplogs $onelog)"
    fi
    rotatedhttplogs=$(find $DATA -type f \( \( -name "access.audit.json-*" -o -name "http-access.audit.json.*" \) -a -not -name "*.txt" \) -print | sort)
    if [ -z "$rotatedhttplogs" ]; then
        httplogs="$(find $DATA -type f \( -name "access.audit.json" -o -name "http-access.audit.json" \) -print)"
    else
        onelog=$(find $DATA -type f \( -name "access.audit.json" -o -name "http-access.audit.json" \) -print)
        httplogs="$(echo $rotatedhttplogs $onelog)"
    fi
else
    ldaplogs=$(find $DATA -name "ldap-access.audit.json" -print)
    httplogs=$(find $DATA -type f \( -name "access.audit.json" -o -name "http-access.audit.json" \) -print)
fi

if [ "$CREATESUMMARY" = true ]; then
    echo "<html> <head> <title>Summary for $FILENAMEONLY</title> </head> <body><pre>Summary for $FILENAMEONLY</pre>" >$WS/summary.html
    if [ ! -z "$ldaplogs" ]; then
        echo "LDAP logs = $ldaplogs"
        echo "Creating LDAP summary..."
        echo "<pre>LDAP Summary</pre>" >>$WS/summary.html
        echo "<pre>First LDAP timestamp = $fts" >>$WS/summary.html
        echo "Last LDAP timestamp  = $lts" >>$WS/summary.html
        ops="ABANDON ADD BIND DELETE MODIFY MODIFYDN SEARCH"
        status="SUCCESSFUL FAILED"
        total=0
        echo "<pre>" >>$WS/summary.html
        # C02C11RXMD6W:logs robert.faller$ time cat ldap-access.audit.json.20210430004759 | ~/bin/jq -r '.request.operation, .response.status, .response.additionalItems' | paste -d" " - - - | grep SEARCH | grep -v null | grep unindexed
        for op in $ops; do
            echo -n ".for $op ..."
            for stat in $status; do
                x=$(grep $op $ldaplogs | grep $stat | wc -l | tr -d '\n')
                y=$(grep $op $ldaplogs | grep $stat | grep "\"opType\":\"sync\"" | wc -l | tr -d '\n')
                if [ $op = "SEARCH" ]; then
                    u=$(grep $op $ldaplogs | grep $stat | grep "\"additionalItems\":" | grep "\"unindexed\"" | wc -l | tr -d '\n')
                    p=$(grep $op $ldaplogs | grep $stat | grep "\"additionalItems\":" | grep "\"persistent\"" | wc -l | tr -d '\n')
                fi
                if [ $op = "SEARCH" ]; then
                    printf "%-22s %'.f\n" "$op-$stat =" "$x" >>$WS/summary.html
                    if [ $u -gt 0 ]; then
                        printf "%-22s %'.f\n" "  unindexed =" "$u" >>$WS/summary.html
                    fi
                    if [ $p -gt 0 ]; then
                        printf "%-22s %'.f\n" "  persistent =" "$p" >>$WS/summary.html
                    fi
                else
                    if (($y == 0)); then
                        printf "%-22s %'.f\n" "$op-$stat =" "$x" >>$WS/summary.html
                    else
                        printf "%-22s %'.f\n" "$op-$stat =" "$x" >>$WS/summary.html
                        printf "%-22s %'.f\n" "  sync received  =" "$y" >>$WS/summary.html
                        printf "%-22s %'.f\n" "  replicated out =" "$(($x - $y))" >>$WS/summary.html
                    fi
                fi
                total=$((total + x))
            done
        done
        printf "%-22s %'.f\n" "total operations =" "$total" >>$WS/summary.html
        echo "</pre><hr>" >>$WS/summary.html
        #        echo "<iframe src=./summary.html" title="LDAP Summary" width="100%" height="32%" style="border:none;></iframe>" >>$WS/$RPT/report.html
        echo "...completed"
    fi
    if [ ! -z "$httplogs" ]; then
        echo -n "Creating HTTP summary..."
        echo "<pre>HTTP | REST Summary</pre>" >>$WS/summary.html
        if [ "$ALLLOGS" = true ]; then
            fts=$(head -1 $(find $DATA -type f \( \( -name "access.audit.json-*" -o -name "http-access.audit.json.*" \) -a -not -name "*.txt" -a -not -name "*.tmp" \) -print | sort | head -1) | ~/bin/jq -r '.timestamp')
        else
            fts=$(head -1 $(find $DATA -type f \( -name "access.audit.json" -o -name "http-access.audit.json" \) -print) | ~/bin/jq -r '.timestamp')
        fi
        lts=$(tail -1 $(find $DATA -type f \( -name "access.audit.json" -o -name "http-access.audit.json" \) -print) | ~/bin/jq -r '.timestamp')
        echo "<pre>First HTTP timestamp = $fts" >>$WS/summary.html
        echo "Last HTTP timestamp  = $lts" >>$WS/summary.html
        ops="DELETE GET PATCH POST PUT"
        status="SUCCESSFUL FAILED"
        total=0
        echo "<pre>" >>$WS/summary.html
        for op in $ops; do
            echo -n ".for $op ..."
            for stat in $status; do
                x=$(grep $op $httplogs | grep $stat | wc -l | tr -d '\n')
                printf "%-22s %'.f\n" "$op-$stat =" "$x" >>$WS/summary.html
                total=$((total + x))
            done
        done
        printf "%-22s %'.f\n" "total operations =" "$total" >>$WS/summary.html
        echo "</pre>" >>$WS/summary.html
        echo "...completed"
    fi
    echo "</body></html>" >>$WS/summary.html
fi

if [ "$firstrun" = true ]; then
    echo -n "Combining data points..."
    if [ "$IPASSESS" = true ]; then
        echo -n ".. for IP..."
        cat $WS/$TMP/*-*-ip.txt | sort | uniq -c | sed -e 's/^[ ]*//' | sed -e 's/ /,/' | sed -e 's/null,/"null",/g' -e 's/,null/,"null"/g' | sort -t"," -k2 >$WS/$RPT/ip-activity.csv &
    fi
    if [ "$IDASSESS" = true ]; then
        echo -n ".. for Identity..."
        cat $WS/$TMP/*-*-identity-activity.txt | sort | uniq -c | sed -e 's/^[ ]*//' -e 's/ /,/' -e 's/null,/"null",/g' -e 's/,null/,"null"/g' -e 's/,/~/g' -e 's/"~"/,/g' -e 's/~"/,/g' -e 's/ //g' -e 's/\(.*\)"/\1/' >$WS/$RPT/identity-activity.csv &
    fi
    if [ "$OBJECTASSESS" = true ]; then
        echo -n ".. for Objects..."
        cat $WS/$TMP/*-*-object-activity.txt | sort | uniq -c | sed -e 's/^[ ]*//' | sed -e 's/ /,/' | sort -t"," -k2 >$WS/$RPT/object-activity.csv &
    fi
    wait
    echo "...completed"
fi

if [ "$CREATEGRAPH" = true ]; then
    if [ ! -z "$ldaplogs" ]; then
        create_graph "ldap" ldaplogcount
    fi
    if [ ! -z "$httplogs" ]; then
        create_graph "rest" httplogcount
    fi
else
    echo "Creating graphs skipped"
fi

if [ "$firstrun" = true ] && [ "$IPASSESS" = true ]; then
    echo -n "Assess IP address activity ..."
    echo "<html><head></head><body>" >$WS/$RPT/ip-assessment.html
    echo "<table id=\"iptable\" class=\"searchablesortable\" cellpadding=\"1\" border=\"1\">" >>$WS/$RPT/ip-assessment.html
    echo "<thead><tr><th onclick=\"sortTable(0)\">Transactions</th><th onclick=\"sortTable(1)\">IP Address</th><th onclick=\"sortTable(2)\">Status</th></tr></thead><tbody>" >>$WS/$RPT/ip-assessment.html
    while read ipvalue; do
        echo "<tr><td>${ipvalue//,/</td><td>}</td></tr>" >>$WS/$RPT/ip-assessment.html
        # echo "<tr><td><pre><a href=https://ipinfo.io/$ipvalue>$ipvalue</a></pre></td><td><pre>$successful</pre></td><td><pre>$failed</pre></td></tr>" >>$WS/$RPT/ip-assessment.html
    done <$WS/$RPT/ip-activity.csv
    echo "</tbody></table>" >>$WS/$RPT/ip-assessment.html
    cat $SCRIPTHOME/sortTable.js >>$WS/$RPT/ip-assessment.html
    echo "</body></html>" >>$WS/$RPT/ip-assessment.html
    echo "<a href=./ip-assessment.html>IP Assessment</a><hr>" >>$WS/$RPT/report.html
    echo "...completed"
fi

if [ "$firstrun" = true ] && [ "$IDASSESS" = true ]; then
    echo -n "Assess identity activity ..."
    echo "<html><head></head><body>" >$WS/$RPT/identity-assessment.html
    echo "<table id=\"identitytable\" class=\"searchablesortable\" cellpadding=\"1\" border=\"1\">" >>$WS/$RPT/identity-assessment.html
    echo "<thead><tr><th onclick=\"sortTable(0)\">transactions</th><th onclick=\"sortTable(1)\">UserId</th><th onclick=\"sortTable(2)\">method</th><th onclick=\"sortTable(3)\">status</th></tr></thead><tbody>" >>$WS/$RPT/identity-assessment.html
    while read idvalue; do
        echo "<tr><td>${idvalue//,/</td><td>}</td></tr>" >>$WS/$RPT/identity-assessment.html
    done <$WS/$RPT/identity-activity.csv
    echo "</tbody></table>" >>$WS/$RPT/identity-assessment.html
    cat $SCRIPTHOME/sortTable.js >>$WS/$RPT/identity-assessment.html
    echo "</body></html>" >>$WS/$RPT/identity-assessment.html
    echo "<a href=./identity-assessment.html>Identity Assessment</a><hr>" >>$WS/$RPT/report.html
    echo "...completed"
fi

# END OF assess.sh
