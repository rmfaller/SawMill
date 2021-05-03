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

create_space() {
    echo "Creating $WS as the workspace."
    mkdir -p $WS
    mkdir $WS/$TMP
    mkdir $WS/$POI
    mkdir $WS/$RPT
    mkdir $WS/data
    DATA="$WS/data"
    ln -s $WS/$TMP $WS/tmp
    ln -s $WS/$POI $WS/poi
    ln -s $WS/$RPT $WS/rpt
    chmod -R 700 *
    firstrun=true
    cd $WS/data
    echo -n "Unzipping file..."
    $JAR -xf $FULLFILENAME
    echo "...completed."
    cd $WS
    ln -s $WS/$TMP $WS/firstrun
}

prep_space() {
    echo "Using $WS/default as the workspace."
    rm -r $WS/tmp
    rm -r $WS/poi
    rm -r $WS/rpt
    mkdir $WS/$TMP
    mkdir $WS/$POI
    mkdir $WS/$RPT
    DATA="$WS/data"
    ln -s $WS/$TMP $WS/tmp
    ln -s $WS/$POI $WS/poi
    ln -s $WS/$RPT $WS/rpt
}

create_ldap_poi() {
    echo -n "Creating LDAP poi..."
    for log in $ldaplogs; do
        cat $log | $JQ -c '[.request.operation, .request.opType, .response.status, .response.statusCode, .response.searchType]' | sort -u >$WS/$POI/$(basename $log)-ldap-ops.txt &
    done
    wait
    cat $WS/$POI/ldap-access.audit.json*-ldap-ops.txt | tr -d "[" | tr -d "]" | sort -u >$WS/$POI/ldap-poi.txt
    etu=$(grep -m 1 elapsedTimeUnits $log | $JQ '.response.elapsedTimeUnits')
    pois=$(cat $WS/$POI/ldap-poi.txt | grep -v UNBIND | tr -d "\"" | tr "," "~" | sort -r | uniq)
    if [[ $pois ]]; then
        echo $JSONHEADER >$WS/$POI/ldap-poi.json
        printf '%s\n' "${pois[@]}" | $JQ -R . | $JQ -s . >>$WS/$POI/ldap-poi.json
        echo "," >>$WS/$POI/ldap-poi.json
        OLDIFS=$IFS
        IFS=$'\n'
        for poi in $pois; do
            operation=$(echo $poi | cut -d"~" -f1)
            opType=$(echo $poi | cut -d"~" -f2)
            if [ "$opType" = "null" ]; then
                opType=""
            fi
            status=$(echo $poi | cut -d"~" -f3)
            if [ "$status" = "null" ]; then
                status=""
            fi
            statuscode=$(echo $poi | cut -d"~" -f4)
            if [ "$statuscode" = "null" ]; then
                statuscode=""
            fi
            searchtype=$(echo $poi | cut -d"~" -f5)
            if [ "$searchtype" = "null" ]; then
                searchtype=""
            fi
            echo "\"$poi\": { \"identifiers\": [ " >>$WS/$POI/ldap-poi.json
            echo -n '"\"operation\":\"' >>$WS/$POI/ldap-poi.json
            echo -n "$operation\\\"\"" >>$WS/$POI/ldap-poi.json
            if [[ $opType ]]; then
                echo "," >>$WS/$POI/ldap-poi.json
                echo -n '"\"opType\":\"' >>$WS/$POI/ldap-poi.json
                echo -n "$opType\\\"\"" >>$WS/$POI/ldap-poi.json
            fi
            if [[ $status ]]; then
                echo "," >>$WS/$POI/ldap-poi.json
                echo -n '"\"status\":\"' >>$WS/$POI/ldap-poi.json
                echo -n "$status\\\"\"" >>$WS/$POI/ldap-poi.json
            fi
            if [[ $statuscode ]]; then
                echo "," >>$WS/$POI/ldap-poi.json
                echo -n '"\"statusCode\":\"' >>$WS/$POI/ldap-poi.json
                echo "$statuscode\\\"\"" >>$WS/$POI/ldap-poi.json
            fi
            if [[ $searchtype ]]; then
                echo "," >>$WS/$POI/ldap-poi.json
                echo -n '"\"searchType\":\"' >>$WS/$POI/ldap-poi.json
                echo "$searchtype\\\"\"" >>$WS/$POI/ldap-poi.json
            fi
            echo '],
  "lapsedtimefield": "elapsedTime",' >>$WS/$POI/ldap-poi.json
            echo "\"timescale\": $etu," >>$WS/$POI/ldap-poi.json
            case $operation in
            ABANDON)
                sla=10
                ;;
            ADD)
                sla=100
                ;;
            BIND)
                sla=10
                ;;
            DELETE)
                sla=300
                ;;
            MODIFY)
                sla=100
                ;;
            MODIFYDN)
                sla=100
                ;;
            SEARCH)
                sla=20
                ;;
            *)
                sla=200
                ;;
            esac
            echo "\"sla\": $sla" >>$WS/$POI/ldap-poi.json
            echo '},' >>$WS/$POI/ldap-poi.json
        done
        echo '"end":{}
         }' >>$WS/$POI/ldap-poi.json
        IFS=$OLDIFS
    fi
    echo "...completed"
}

create_http_poi() {
    echo -n "Creating HTTP poi..."
    for log in $httplogs; do
        cat $log | $JQ -c '[.http.request.method, .http.request.path, .response.status]' | sort -u >$WS/$POI/$(basename $log)-http-ops.txt &
    done
    wait
    cat $WS/$POI/*access.audit.json*-http-ops.txt | tr -d "[" | tr -d "]" | sort -u >$WS/$POI/http-poi.txt
    cat $WS/$POI/http-poi.txt | grep -v '\"DELETE\"\|\"POST\"\|\"PUT\"\|\"PATCH\"\|\"GET\"\|\"HEAD\"' | sort | uniq >$WS/$POI/http-unknownverbs.txt
    pois=$(cat $WS/$POI/http-poi.txt | grep '\"DELETE\"\|\"POST\"\|\"PUT\"\|\"PATCH\"\|\"GET\"' | tr -d "\"" | tr "," "~" | sort | uniq)
    if [[ $pois ]]; then
        echo $JSONHEADER >$WS/$POI/http-poi.json
        printf '%s\n' "${pois[@]}" | $JQ -R . | $JQ -s . >>$WS/$POI/http-poi.json
        echo "," >>$WS/$POI/http-poi.json
        OLDIFS=$IFS
        IFS=$'\n'
        for poi in $pois; do
            method=$(echo $poi | cut -d"~" -f1)
            fullpath=$(echo $poi | cut -d"~" -f2)
            status=$(echo $poi | cut -d"~" -f3)
            if [ "$fullpath" = "null" ]; then
                path=""
            else
                path=$(echo $fullpath)
            fi
            echo "\"$poi\": { \"identifiers\": [ " >>$WS/$POI/http-poi.json
            echo -n '"\"method\":\"' >>$WS/$POI/http-poi.json
            echo "$method\\\"\"," >>$WS/$POI/http-poi.json
            echo -n '"\"path\":\"' >>$WS/$POI/http-poi.json
            echo "$path\\\"\"," >>$WS/$POI/http-poi.json
            echo -n '"\"status\":\"' >>$WS/$POI/http-poi.json
            echo "$status\\\"\"" >>$WS/$POI/http-poi.json
            echo '],"lapsedtimefield": "elapsedTime",' >>$WS/$POI/http-poi.json
            case $method in
            DELETE)
                sla=100
                ;;
            GET)
                sla=10
                ;;
            PATCH)
                sla=150
                ;;
            POST)
                sla=300
                ;;
            PUT)
                sla=200
                ;;
            *)
                sla=200
                ;;
            esac
            echo "\"sla\": $sla" >>$WS/$POI/http-poi.json
            echo '},' >>$WS/$POI/http-poi.json
        done
        echo '"end":{}
         }' >>$WS/$POI/http-poi.json
        IFS=$OLDIFS
    fi
    echo "...completed"
}

create_graph() {
    echo -n "Generating $1 operation graph..."
    cat $WS/$TMP/*$1-ops.csv >$WS/$TMP/all$1ops.csv
    $SCRIPTHOME/chartprep.sh $WS/$TMP/all$1ops.csv
    echo "<div id=\"note\"></div>" >$WS/$RPT/$1note.phtml
    if (($2 > 1)); then
        echo "<pre><b>Note: </b>More than one log file is being used for the graphs above which <font color=red><b>may</b></font> result in some data discrepancy around (+ or - 1,000ms) these epoch times (shown in milliseconds):</pre>" >>$WS/$RPT/$1note.phtml
    fi
    echo "<table cellspacing=\"2\" cellpadding=\"2\" border=\"1\"><tr><th>File</th><th>Time span</th><th>Epoch time span</th><th>Length of time</th></tr>" >>$WS/$RPT/$1note.phtml
    OLDIFS=$IFS
    IFS=$'\n'
    rows=$(grep 'Operations from log file \|Time span: \|Epoch time: \|Length of time = ' $WS/$RPT/operation-assessment.html | paste -d" " - - - - | grep ldap | sed 's/pre/td/g')
    for row in $rows; do
        echo "<tr><tt>$row</tt></tr>" >>$WS/$RPT/$1note.phtml
    done
    echo "</table><hr>" >>$WS/$RPT/$1note.phtml
    IFS=$OLDIFS
    cat $SAWMILLHOME/content/chartheader.phtml $WS/$TMP/opscolumns.data $WS/$TMP/etimescolumns.data $WS/$TMP/ops.data $WS/$TMP/etimes.data $SAWMILLHOME/content/charttailer.phtml $WS/$RPT/$1note.phtml >$WS/$RPT/all$1ops.html
    echo "</body></html>" >>$WS/$RPT/all$1ops.html
    echo "<font face=\"Arial Unicode MS\"><a href=./all$1ops.html>$1 operations</a><br></font><hr size=\"2\" width=\"100%\">" >>$WS/$RPT/report.html
    echo "...completed"
}

# Main script

if [[ -z $1 ]]; then
    echo "No zip file specified; please correct"
    exit
else
    if [[ -f $1 ]]; then
        FULLFILENAME=$1
        FILENAME=${FULLFILENAME%.*}
        FILENAMEONLY=${FILENAME##*/}
        if [[ -z $2 ]]; then
            WS="$SMWORKSPACE/$FILENAMEONLY"
            if [[ -d $WS ]]; then
                prep_space
            else
                create_space
            fi
        else
            WS="$SMWORKSPACE/$2/$FILENAMEONLY"
            if [[ ! -d $WS ]]; then
                create_space
            else
                prep_space
            fi
        fi
    else
        echo "Zip file $1 does not exist."
        exit
    fi
fi

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

#echo "LDAP logs = $ldaplogs"
#echo "HTTP logs = $httplogs"

for log in $ldaplogs; do
    if [ ! -f $log.extended ]; then
        cat $log | sed 's/\"additionalItems\":{\"persistent\"/\"searchType\":\"persistent\",\"additionalItems\":{\"persistent\"/' |
            sed 's/\"additionalItems\":\"persistent\"/\"searchType\":\"persistent\",\"additionalItems\":\"persistent\"/' |
            sed 's/\"additionalItems\":{\"unindexed\"/\"searchType\":\"unindexed\",\"additionalItems\":{\"unindexed\"/' |
            sed 's/\"additionalItems\":\"unindexed\"/\"searchType\":\"unindexed\",\"additionalItems\":\"unindexed\"/' >$log.extended
        mv $log.extended $log
        echo "$(date)" >$log.extended
    fi
done

echo "<html> <head> <title>Log Report</title> </head> <body>" >$WS/$RPT/report.html
echo "<h2><b> <font face=\"Arial Unicode MS\"><font color=\"#3333ff\">Log Report</font>" >>$WS/$RPT/report.html
echo "Report for $WS from file $FILENAMEONLY</font></b></h2>" >>$WS/$RPT/report.html

if [ "$CREATESUMMARY" = true ]; then
    echo "<html> <head> <title>Summary for $FILENAMEONLY</title> </head> <body><pre>Summary for $FILENAMEONLY</pre>" >$WS/$RPT/summary.html
    if [ ! -z "$ldaplogs" ]; then
        echo -n "Creating LDAP summary..."
        if [ "$ALLLOGS" = true ]; then
            fts=$(head -1 $(find $DATA -type f \( \( -name "ldap-access.audit.json.*" \) -a -not -name "*.txt" -a -not -name "*.extended" -a -not -name "*.tmp" \) -print | sort | head -1) | ~/bin/jq -r '.timestamp')
        else
            fts=$(head -1 $(find $DATA -name "ldap-access.audit.json" -print) | ~/bin/jq -r '.timestamp')
        fi
        lts=$(tail -1 $(find $DATA -name "ldap-access.audit.json" -print) | ~/bin/jq -r '.timestamp')
        echo "<pre>LDAP Summary</pre>" >>$WS/$RPT/summary.html
        echo "<pre>First LDAP timestamp = $fts" >>$WS/$RPT/summary.html
        echo "Last LDAP timestamp  = $lts" >>$WS/$RPT/summary.html
        ops="ABANDON ADD BIND DELETE MODIFY MODIFYDN SEARCH"
        status="SUCCESSFUL FAILED"
        total=0
        echo "<pre>" >>$WS/$RPT/summary.html
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
                    printf "%-22s %'.f\n" "$op-$stat =" "$x" >>$WS/$RPT/summary.html
                    if [ $u -gt 0 ]; then
                        printf "%-22s %'.f\n" "  unindexed =" "$u" >>$WS/$RPT/summary.html
                    fi
                    if [ $p -gt 0 ]; then
                        printf "%-22s %'.f\n" "  persistent =" "$p" >>$WS/$RPT/summary.html
                    fi
                else
                    if (($y == 0)); then
                        printf "%-22s %'.f\n" "$op-$stat =" "$x" >>$WS/$RPT/summary.html
                    else
                        printf "%-22s %'.f\n" "$op-$stat =" "$x" >>$WS/$RPT/summary.html
                        printf "%-22s %'.f\n" "  sync received  =" "$y" >>$WS/$RPT/summary.html
                        printf "%-22s %'.f\n" "  replicated out =" "$(($x - $y))" >>$WS/$RPT/summary.html
                    fi
                fi
                total=$((total + x))
            done
        done
        printf "%-22s %'.f\n" "total operations =" "$total" >>$WS/$RPT/summary.html
        echo "</pre><hr>" >>$WS/$RPT/summary.html
        #        echo "<iframe src=./summary.html" title="LDAP Summary" width="100%" height="32%" style="border:none;></iframe>" >>$WS/$RPT/report.html
        echo "...completed"
    fi
    if [ ! -z "$httplogs" ]; then
        echo -n "Creating HTTP summary..."
        echo "<pre>HTTP | REST Summary</pre>" >>$WS/$RPT/summary.html
        if [ "$ALLLOGS" = true ]; then
            fts=$(head -1 $(find $DATA -type f \( \( -name "access.audit.json-*" -o -name "http-access.audit.json.*" \) -a -not -name "*.txt" -a -not -name "*.tmp" \) -print | sort | head -1) | ~/bin/jq -r '.timestamp')
        else
            fts=$(head -1 $(find $DATA -type f \( -name "access.audit.json" -o -name "http-access.audit.json" \) -print) | ~/bin/jq -r '.timestamp')
        fi
        lts=$(tail -1 $(find $DATA -type f \( -name "access.audit.json" -o -name "http-access.audit.json" \) -print) | ~/bin/jq -r '.timestamp')
        echo "<pre>First HTTP timestamp = $fts" >>$WS/$RPT/summary.html
        echo "Last HTTP timestamp  = $lts" >>$WS/$RPT/summary.html
        ops="DELETE GET PATCH POST PUT"
        status="SUCCESSFUL FAILED"
        total=0
        echo "<pre>" >>$WS/$RPT/summary.html
        for op in $ops; do
            echo -n ".for $op ..."
            for stat in $status; do
                x=$(grep $op $httplogs | grep $stat | wc -l | tr -d '\n')
                printf "%-22s %'.f\n" "$op-$stat =" "$x" >>$WS/$RPT/summary.html
                total=$((total + x))
            done
        done
        printf "%-22s %'.f\n" "total operations =" "$total" >>$WS/$RPT/summary.html
        echo "</pre>" >>$WS/$RPT/summary.html
        echo "...completed"
    fi
    echo "<hr><pre>Note the timestamps shown above are the actual timestamps from the logs. " >>$WS/$RPT/summary.html
    echo "The timestamps shown in the following report are adjusted to reflect the timezone in which the report was created.</pre>" >>$WS/$RPT/summary.html
    echo "</body></html>" >>$WS/$RPT/summary.html
    echo "<hr size=\"2\" width=\"100%\"><font face=\"Arial Unicode MS\"><a href=./summary.html>Summary</a><br></font>" >>$WS/$RPT/report.html
fi

if [ ! -z "$ldaplogs" ]; then
    create_ldap_poi
    echo -n "Collecting LDAP data points ..."
    ldaplogcount=0
    for log in $ldaplogs; do
        if [ -f $log ]; then
            filesize=$(wc -c $log | awk '{print $1}')
            if (($filesize > 0)); then
                filename=$(echo "$log" | sed "s/.*\///")
                printf -v cnt "%05d" $ldaplogcount
                if (($ldaplogcount == 0)); then
                    echo "<pre>Operation assessment for $FILENAME</pre>" >$WS/$TMP/$cnt-ldap-operations.html
                    java -jar $SAWMILLHOME/dist/SawMill.jar --cut $LDAPCUT --poi $WS/$POI/ldap-poi.json --condense $log >$WS/$TMP/$cnt-ldap-ops.csv &
                else
                    java -jar $SAWMILLHOME/dist/SawMill.jar --cut $LDAPCUT --poi $WS/$POI/ldap-poi.json --noheader --condense $log >$WS/$TMP/$cnt-ldap-ops.csv &
                fi
                echo "<pre>Operations from log file $filename</pre>" >$WS/$TMP/$cnt-ldap-operations.html
                java -jar $SAWMILLHOME/dist/SawMill.jar --poi $WS/$POI/ldap-poi.json --totalsonly --condense $log --sla --html >>$WS/$TMP/$cnt-ldap-operations.html &
                if $firstrun; then
                    cat $log | $JQ -c '[.response.elapsedTime, .request.operation]' | sed -e 's/\[//g' -e 's/\]//g' -e 's/"//g' >$WS/$TMP/$cnt-ldap-ms.txt &
                    cat $log | $JQ -c '[.client.ip,.response.status]' | grep -v null | sed -e 's/\[//g' -e 's/\]//g' -e 's/"//g' >$WS/$TMP/$cnt-ldap-ip.txt &
                    cat $log | $JQ -c '[.request.dn, .request.operation]' | grep -v null | sed -e 's/\[//g' -e 's/\]//g' >$WS/$TMP/$cnt-ldap-object-activity.txt &
                    cat $log | $JQ -c '[.userId, .request.operation, .response.status]' | sed -e 's/\[//g' -e 's/\]//g' >$WS/$TMP/$cnt-ldap-identity-activity.txt &
                fi
                wait
                ((ldaplogcount++))
            fi
        fi
    done
    if [ "$firstrun" = true ]; then
        cat $WS/$TMP/*-ldap-ms.txt | sort -k1,1 -n | uniq -c | sort -n -k1,1 | sed -e 's/^[ ]*//' | sed -e 's/ /,/' >$WS/$RPT/ldap-ms-activity.txt
    fi
    echo "...completed"
fi

if [ ! -z "$httplogs" ]; then
    create_http_poi
    echo -n "Collecting HTTP|REST data points ..."
    httplogcount=0
    for log in $httplogs; do
        if [ -f $log ]; then
            filesize=$(wc -c $log | awk '{print $1}')
            if (($filesize > 0)); then
                filename=$(echo "$log" | sed "s/.*\///")
                printf -v cnt "%05d" $httplogcount
                if (($httplogcount == 0)); then
                    echo "<pre>Operation assessment for $FILENAME</pre>" >$WS/$TMP/$cnt-rest-operations.html
                    /usr/bin/java -jar $SAWMILLHOME/dist/SawMill.jar --cut $HTTPCUT --poi $WS/$POI/http-poi.json --condense $log >$WS/$TMP/$cnt-rest-ops.csv &
                else
                    /usr/bin/java -jar $SAWMILLHOME/dist/SawMill.jar --cut $HTTPCUT --poi $WS/$POI/http-poi.json --noheader --condense $log >$WS/$TMP/$cnt-rest-ops.csv &
                fi
                echo "<pre>Operations from log file $filename</pre>" >$WS/$TMP/$cnt-rest-operations.html
                /usr/bin/java -jar $SAWMILLHOME/dist/SawMill.jar --poi $WS/$POI/http-poi.json --totalsonly --cut 10000 --condense $log --sla --html >>$WS/$TMP/$cnt-rest-operations.html &
                if $firstrun; then
                    cat $log | $JQ -c '[.response.elapsedTime, .http.request.method]' | sed -e 's/\[//g' -e 's/\]//g' -e 's/"//g' >$WS/$TMP/$cnt-rest-ms.txt &
                    cat $log | $JQ -c '[.client.ip,.response.status]' | grep -v null | sed -e 's/\[//g' -e 's/\]//g' -e 's/"//g' >$WS/$TMP/$cnt-rest-ip.txt &
                    cat $log | $JQ -c '[.http.request.method, .http.request.path]' | grep -v null | sed -e 's/\[//g' -e 's/\]//g' >$WS/$TMP/$cnt-rest-object-activity.txt &
                    cat $log | $JQ -c '[.userId, .http.request.method, .response.status]' | sed -e 's/\[//g' -e 's/\]//g' >$WS/$TMP/$cnt-rest-identity-activity.txt &
                fi
                wait
                ((httplogcount++))
            fi
        fi
    done
    if [ "$firstrun" = true ]; then
        cat $WS/$TMP/*-rest-ms.txt | sort -n -k1,1 | uniq -c | sort -n -k1,1 | sed -e 's/^[ ]*//' | sed -e 's/ /,/' >$WS/$RPT/rest-ms-activity.txt
    fi
    echo "...completed"
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

if [ "$firstrun" = true ] && [ "$DSEXTRACT" = true ] && [ -d $DATA/support-data/config ]; then
    cd $DATA/support-data/config
    echo -n "Running extractor..."
    $SCRIPTHOME/extractor.sh -r $FILENAMEONLY -h >/dev/null
    echo "...completed."
    mv $FILENAMEONLY.html $WS/$RPT/.
    cd $WS
    echo "<hr size=\"2\" width=\"100%\"><font face=\"Arial Unicode MS\"><a href=./$FILENAMEONLY.html>Directory Server Extractor Report</a><br></font>" >>$WS/$RPT/report.html
fi

echo "<hr size=\"2\" width=\"100%\"><font face=\"Arial Unicode MS\"><a href=./operation-assessment.html>Operation Assessment</a><br></font><hr size=\"2\" width=\"100%\">" >>$WS/$RPT/report.html
logs=$(ls $WS/$TMP/*-operations.html)
echo "<html><head></head><body>" >$WS/$RPT/operation-assessment.html
for log in $logs; do
    echo "<hr size=\"2\" width=\"100%\">" >>$WS/$RPT/operation-assessment.html
    cat $log >>$WS/$RPT/operation-assessment.html
done
echo "</body></html>" >>$WS/$RPT/operation-assessment.html
echo "<table cellspacing=\"2\" cellpadding=\"2\" border=\"1\"><tr><th>File</th><th>Time span</th><th>Epoch time span</th><th>Length of time</th></tr>" >>$WS/$RPT/report.html
OLDIFS=$IFS
IFS=$'\n'
rows=$(grep 'Operations from log file \|Time span: \|Epoch time: \|Length of time = ' $WS/$RPT/operation-assessment.html | paste -d" " - - - - | sed 's/pre/td/g')
for row in $rows; do
    echo "<tr><tt>$row</tt></tr>" >>$WS/$RPT/report.html
done
echo "</table><hr>" >>$WS/$RPT/report.html
IFS=$OLDIFS

if [ "$CREATEGRAPH" = true ]; then
    if (($ldaplogcount > 0)); then
        create_graph "ldap" ldaplogcount
    fi
    if (($httplogcount > 0)); then
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
