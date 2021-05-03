#!/bin/bash
# arg 1 = file system location to work in (i.e. unzip files, create poi, etc)
# arg 2 = full path on file system to zipped file

BOH="/Users/robert.faller/projects"
JQ="/Users/robert.faller/bin/jq"
BIN="/usr/bin"
JAR="jar"
SAWMILLHOME="$BOH/SawMill"
SCRIPTHOME="$SAWMILLHOME/script"
HTMLHOME="$SAWMILLHOME/html"
SUBSCRIPTIONHOME=/Users/rmfaller
SUBSCRIPTION=$SUBSCRIPTIONHOME/sawmill/$1
FULLFILENAME=$2
FILENAME=${FULLFILENAME%.*}
FILENAMEONLY=${FILENAME##*/}
SERVICEBASE="/Users/rmfaller/projects/BlueOx/build/web"
MIT=$(date +"%Y%m%d%H%M%S")
REPORTLOCATION="report$MIT"
TMPLOCATION="tmp$MIT"
POILOCATION="poi$MIT"
WDIR=$(pwd)
DSEXTRACT=true
ALLLOGS=true
IDASSESS=false
IPASSESS=false
OBJECTASSESS=true
TXIDASSESS=true
LDAPCUT=60000
HTTPCUT=60000

firstrun=false

cd $SUBSCRIPTION
if ! [[ -d $FILENAMEONLY ]]; then
  firstrun=true
  echo "Creating layout."
  mkdir $FILENAMEONLY
  cd $FILENAMEONLY
  mkdir data
  cd data
  echo "Unzipping file."
  $JAR -xf $2
  cd ../..
else
  rm $FILENAMEONLY/tmp
  rm $FILENAMEONLY/report
  rm $FILENAMEONLY/poi
fi

mkdir $FILENAMEONLY/$TMPLOCATION
mkdir $FILENAMEONLY/$REPORTLOCATION
mkdir $FILENAMEONLY/$POILOCATION
ln -s ./$TMPLOCATION $FILENAMEONLY/tmp
ln -s ./$REPORTLOCATION $FILENAMEONLY/report
ln -s ./$POILOCATION $FILENAMEONLY/poi
chmod -R 700 *
DATA="$FILENAMEONLY/data"

echo "<html> <head> <title>Log Report</title> </head> <body>" >$FILENAMEONLY/$REPORTLOCATION/report.html
echo "<h2><b> <font face=\"Arial Unicode MS\"><font color=\"#3333ff\">Log Report</font>" >>$FILENAMEONLY/$REPORTLOCATION/report.html
echo "Report for subscription = $SUBSCRIPTION from file = $FILENAMEONLY</font></b></h2>" >>$FILENAMEONLY/$REPORTLOCATION/report.html

#if $ALLLOGS; then
 # rotatedldaplogs=$(find $DATA -type f \( -name "ldap-access.audit.json.*" -not -name "*.txt" \) -print | sort)
#  ldaplogs="$(echo $rotatedldaplogs)  $(find $DATA -name "ldap-access.audit.json" -print)"
 # rotatedhttplogs=$(find $DATA -type f \( -name "access.audit.json-*" -o -name "http-access.audit.json.*" -not -name "*.txt" \) -print | sort)
  #httplogs="$(echo $rotatedhttplogs) $(find $DATA -type f \( -name "access.audit.json" -o -name "http-access.audit.json" \) -print)"
#else
 # ldaplogs=$(find $DATA -name "ldap-access.audit.json" -print)
  #httplogs=$(find $DATA -type f \( -name "access.audit.json" -o -name "http-access.audit.json" \) -print)
#fi

if $ALLLOGS; then
  rotatedldaplogs=$(find $DATA -type f \( -name "ldap-access.audit.json.*" -a -not -name "*.txt" -a -not -name "*.extended" -a -not -name "*.tmp" \) -print | sort)
  if [ -z "$rotatedldaplogs" ]; then
    ldaplogs="$(find $DATA -name "ldap-access.audit.json" -print)"
  else
    ldaplogs="$(echo $rotatedldaplogs) $(find $DATA -name "ldap-access.audit.json" -print)"
  fi
  rotatedhttplogs=$(find $DATA -type f \( \( -name "access.audit.json-*" -o -name "http-access.audit.json.*" \) -a -not -name "*.txt" \) -print | sort)
  if [ -z "$rotatedhttplogs" ]; then
    httplogs="$(find $DATA -type f \( -name "access.audit.json" -o -name "http-access.audit.json" \) -print)"
  else
    httplogs="$(echo $rotatedhttplogs) $(find $DATA -type f \( -name "access.audit.json" -o -name "http-access.audit.json" \) -print)"
  fi
else
  ldaplogs=$(find $DATA -name "ldap-access.audit.json" -print)
  httplogs=$(find $DATA -type f \( -name "access.audit.json" -o -name "http-access.audit.json" \) -print)
fi

echo -n "Creating poi..."
$SCRIPTHOME/createpoi.sh $FILENAMEONLY
echo "..completed"

if $firstrun; then
  ln -s ./$TMPLOCATION $FILENAMEONLY/firstrun
  if $DSEXTRACT; then
    if [ -d ./$DATA/support-data/config ]; then
      echo "This = $thispwd"
      cd ./$DATA/support-data/config
      echo "Running extractor..."
      $SCRIPTHOME/extractor.sh -r $FILENAMEONLY -h
      echo ""
      echo "Extractor report completed."
      mv $FILENAMEONLY.html $thispwd/$FILENAMEONLY/$REPORTLOCATION/.
      cd $thispwd
      echo "<hr size=\"2\" width=\"100%\"><font face=\"Arial Unicode MS\"><a href=./$FILENAMEONLY.html>Directory Server Extractor Report</a><br></font>" >>$FILENAMEONLY/$REPORTLOCATION/report.html
    fi
  fi
fi

ldaplogcount=0
for log in $ldaplogs; do
  if [ -f $log ]; then
    filesize=$(wc -c $log | awk '{print $1}')
    if (($filesize > 0)); then
      filename=$(echo "$log" | sed "s/.*\///")
      echo -n "Collecting LDAP data points from $log ..."
      printf -v cnt "%05d" $ldaplogcount
      if (($ldaplogcount == 0)); then
        echo "<pre>Operation assessment for $FILENAME</pre>" >$FILENAMEONLY/$TMPLOCATION/$cnt-ldap-operations.html
        /usr/bin/java -jar $SAWMILLHOME/dist/SawMill.jar --cut $LDAPCUT --poi $SUBSCRIPTION/$FILENAMEONLY/$POILOCATION/ldap-poi.json --condense $log >$FILENAMEONLY/$TMPLOCATION/$cnt-ldap-ops.csv &
      else
        /usr/bin/java -jar $SAWMILLHOME/dist/SawMill.jar --cut $LDAPCUT --poi $SUBSCRIPTION/$FILENAMEONLY/$POILOCATION/ldap-poi.json --noheader --condense $log >$FILENAMEONLY/$TMPLOCATION/$cnt-ldap-ops.csv &
      fi
      echo "<pre>Operations from log file $filename</pre>" >$FILENAMEONLY/$TMPLOCATION/$cnt-ldap-operations.html
      /usr/bin/java -jar $SAWMILLHOME/dist/SawMill.jar --poi $SUBSCRIPTION/$FILENAMEONLY/$POILOCATION/ldap-poi.json --totalsonly --condense $log --sla --html >>$FILENAMEONLY/$TMPLOCATION/$cnt-ldap-operations.html &
      if $firstrun; then
        cat $log | $JQ -c '[.response.elapsedTime, .request.operation]' | sed -e 's/\[//g' -e 's/\]//g' -e 's/"//g' >$FILENAMEONLY/$TMPLOCATION/$cnt-ldap-ms.txt &
        cat $log | $JQ -c '[.client.ip,.response.status]' | grep -v null | sed -e 's/\[//g' -e 's/\]//g' -e 's/"//g' >$FILENAMEONLY/$TMPLOCATION/$cnt-ldap-ip.txt &
        cat $log | $JQ -c '[.request.dn, .request.operation]' | grep -v null | sed -e 's/\[//g' -e 's/\]//g' >$FILENAMEONLY/$TMPLOCATION/$cnt-ldap-object-activity.txt &
        cat $log | $JQ -c '[.userId, .request.operation, .response.status]' | sed -e 's/\[//g' -e 's/\]//g' >$FILENAMEONLY/$TMPLOCATION/$cnt-ldap-identity-activity.txt &
      fi
      wait
      echo "...completed"
      ((ldaplogcount++))
    fi
  fi
done

httplogcount=0
for log in $httplogs; do
  if [ -f $log ]; then
    filesize=$(wc -c $log | awk '{print $1}')
    if (($filesize > 0)); then
      filename=$(echo "$log" | sed "s/.*\///")
      echo -n "Collecting HTTP|REST data points from $log ..."
      printf -v cnt "%05d" $httplogcount
      if (($httplogcount == 0)); then
        echo "<pre>Operation assessment for $FILENAME</pre>" >$FILENAMEONLY/$TMPLOCATION/$cnt-rest-operations.html
        /usr/bin/java -jar $SAWMILLHOME/dist/SawMill.jar --cut $HTTPCUT --poi $SUBSCRIPTION/$FILENAMEONLY/$POILOCATION/http-poi.json --cut 10000 --condense $log >$FILENAMEONLY/$TMPLOCATION/$cnt-rest-ops.csv &
      else
        /usr/bin/java -jar $SAWMILLHOME/dist/SawMill.jar --cut $HTTPCUT --poi $SUBSCRIPTION/$FILENAMEONLY/$POILOCATION/http-poi.json --cut 10000 --noheader --condense $log >$FILENAMEONLY/$TMPLOCATION/$cnt-rest-ops.csv &
      fi
      echo "<pre>Operations from log file $filename</pre>" >$FILENAMEONLY/$TMPLOCATION/$cnt-rest-operations.html
      /usr/bin/java -jar $SAWMILLHOME/dist/SawMill.jar --poi $SUBSCRIPTION/$FILENAMEONLY/$POILOCATION/http-poi.json --totalsonly --cut 10000 --condense $log --sla --html >>$FILENAMEONLY/$TMPLOCATION/$cnt-rest-operations.html &
      if $firstrun; then
        cat $log | $JQ -c '[.response.elapsedTime, .http.request.method]' | sed -e 's/\[//g' -e 's/\]//g' -e 's/"//g' >$FILENAMEONLY/$TMPLOCATION/$cnt-rest-ms.txt &
        cat $log | $JQ -c '[.client.ip,.response.status]' | grep -v null | sed -e 's/\[//g' -e 's/\]//g' -e 's/"//g' >$FILENAMEONLY/$TMPLOCATION/$cnt-rest-ip.txt &
        cat $log | $JQ -c '[.http.request.method, .http.request.path]' | grep -v null | sed -e 's/\[//g' -e 's/\]//g' >$FILENAMEONLY/$TMPLOCATION/$cnt-rest-object-activity.txt &
        cat $log | $JQ -c '[.userId, .http.request.method, .response.status]' | sed -e 's/\[//g' -e 's/\]//g' >$FILENAMEONLY/$TMPLOCATION/$cnt-rest-identity-activity.txt &
      fi
      wait
      echo "...completed"
      ((httplogcount++))
    fi
  fi
done

if $firstrun; then
  echo -n "Combining data points..."
  if $IPASSESS; then
    cat $FILENAMEONLY/$TMPLOCATION/*-*-ip.txt | sort | uniq -c | sort -n -k1,1 | sed -e 's/^[ ]*//' | sed -e 's/ /,/' >$FILENAMEONLY/$REPORTLOCATION/ip-activity.csv &
  fi
  if $IDASSESS; then
    cat $FILENAMEONLY/$TMPLOCATION/*-*-identity-activity.txt | sort | uniq -c | sort -n -k1,1 | sed -e 's/^[ ]*//' | sed -e 's/ /,/' >$FILENAMEONLY/$REPORTLOCATION/identity-activity.csv &
  fi
  if $OBJECTASSESS; then
    cat $FILENAMEONLY/$TMPLOCATION/*-*-object-activity.txt | sort | uniq -c | sort -n -k1,1 | sed -e 's/^[ ]*//' | sed -e 's/ /,/' >$FILENAMEONLY/$REPORTLOCATION/object-activity.csv &
  fi
  if [ -n "$ldaplogs" ]; then
    cat $FILENAMEONLY/$TMPLOCATION/*-ldap-ms.txt | sort -k1,1 -n | uniq -c | sort -n -k1,1 | sed -e 's/^[ ]*//' | sed -e 's/ /,/' >$FILENAMEONLY/$REPORTLOCATION/ldap-ms-activity.txt &
  fi
  if [ -n "$httplogs" ]; then
    cat $FILENAMEONLY/$TMPLOCATION/*-rest-ms.txt | sort -n -k1,1 | uniq -c | sort -n -k1,1 | sed -e 's/^[ ]*//' | sed -e 's/ /,/' >$FILENAMEONLY/$REPORTLOCATION/rest-ms-activity.txt &
  fi
  wait
  echo "...completed"
fi

echo "<hr size=\"2\" width=\"100%\"><font face=\"Arial Unicode MS\"><a href=./operation-assessment.html>Operation Assessment</a><br></font><hr size=\"2\" width=\"100%\">" >>$FILENAMEONLY/$REPORTLOCATION/report.html
logs=$(ls $FILENAMEONLY/$TMPLOCATION/*-operations.html)
echo "<html><head></head><body>" >$FILENAMEONLY/$REPORTLOCATION/operation-assessment.html
for log in $logs; do
  echo "<hr size=\"2\" width=\"100%\">" >>$FILENAMEONLY/$REPORTLOCATION/operation-assessment.html
  cat $log >>$FILENAMEONLY/$REPORTLOCATION/operation-assessment.html
done
echo "</body></html>" >>$FILENAMEONLY/$REPORTLOCATION/operation-assessment.html
echo "<table cellspacing=\"2\" cellpadding=\"2\" border=\"1\"><tr><th>File</th><th>Time span</th><th>Epoch time span</th><th>Length of time</th></tr>" >>$FILENAMEONLY/$REPORTLOCATION/report.html
OLDIFS=$IFS
IFS=$'\n'
rows=$(grep 'Operations from log file \|Time span: \|Epoch time: \|Length of time = ' $FILENAMEONLY/$REPORTLOCATION/operation-assessment.html | paste -d" " - - - - | sed 's/pre/td/g')
for row in $rows; do
  echo "<tr><tt>$row</tt></tr>" >>$FILENAMEONLY/$REPORTLOCATION/report.html
done
echo "</table><hr>" >>$FILENAMEONLY/$REPORTLOCATION/report.html
IFS=$OLDIFS


if (($ldaplogcount != 0)); then
  echo -n "Generating LDAP operation graph..."
  cat $FILENAMEONLY/$TMPLOCATION/*ldap-ops.csv >$FILENAMEONLY/$TMPLOCATION/allldapops.csv
  $SCRIPTHOME/chartprep.sh $FILENAMEONLY/$TMPLOCATION/allldapops.csv
  echo "<div id=\"note\"></div>" >$FILENAMEONLY/$REPORTLOCATION/ldapnote.phtml
  if (($ldaplogcount > 1)); then
    echo "<pre><b>Note: </b>More than one log file is being used for the graphs above which <font color=red><b>may</b></font> result in some data discrepancy around (+ or - 1,000ms) these epoch times (shown in milliseconds):</pre>" >>$FILENAMEONLY/$REPORTLOCATION/ldapnote.phtml
  fi
  echo "<table cellspacing=\"2\" cellpadding=\"2\" border=\"1\"><tr><th>File</th><th>Time span</th><th>Epoch time span</th><th>Length of time</th></tr>" >>$FILENAMEONLY/$REPORTLOCATION/ldapnote.phtml
  OLDIFS=$IFS
  IFS=$'\n'
  rows=$(grep 'Operations from log file \|Time span: \|Epoch time: \|Length of time = ' $FILENAMEONLY/$REPORTLOCATION/operation-assessment.html | paste -d" " - - - - | grep ldap | sed 's/pre/td/g')
  for row in $rows; do
    echo "<tr><tt>$row</tt></tr>" >>$FILENAMEONLY/$REPORTLOCATION/ldapnote.phtml
  done
  echo "</table><hr>" >>$FILENAMEONLY/$REPORTLOCATION/ldapnote.phtml
  IFS=$OLDIFS
  cat /Users/robert.faller/projects/SawMill/content/chartheader.phtml $FILENAMEONLY/$TMPLOCATION/opscolumns.data $FILENAMEONLY/$TMPLOCATION/etimescolumns.data $FILENAMEONLY/$TMPLOCATION/ops.data $FILENAMEONLY/$TMPLOCATION/etimes.data /Users/robert.faller/projects/SawMill/content/charttailer.phtml $FILENAMEONLY/$REPORTLOCATION/ldapnote.phtml >$FILENAMEONLY/$REPORTLOCATION/allldapops.html
  echo "</body></html>" >>$FILENAMEONLY/$REPORTLOCATION/allldapops.html
  echo "<font face=\"Arial Unicode MS\"><a href=./allldapops.html>LDAP operations (DS | CTS | Config store)</a><br></font><hr size=\"2\" width=\"100%\">" >>$FILENAMEONLY/$REPORTLOCATION/report.html
  echo "...completed"
fi

if (($httplogcount != 0)); then
  echo -n "Generating HTTP | REST operation graph..."
  cat $FILENAMEONLY/$TMPLOCATION/*rest-ops.csv >$FILENAMEONLY/$TMPLOCATION/allrestops.csv
  $SCRIPTHOME/chartprep.sh $FILENAMEONLY/$TMPLOCATION/allrestops.csv
  echo "<div id=\"note\"></div>" >$FILENAMEONLY/$REPORTLOCATION/restnote.phtml
  if (($httplogcount > 1)); then
    echo "<pre><b>Note: </b>More than one log file is being used for the graphs above which <font color=red><b>may</b></font> result in some data discrepancy around (+ or - 1,000ms) these epoch times (shown in milliseconds):</pre>" >>$FILENAMEONLY/$REPORTLOCATION/restnote.phtml
  fi
  echo "<table cellspacing=\"2\" cellpadding=\"2\" border=\"1\"><tr><th>File</th><th>Time span</th><th>Epoch time span</th><th>Length of time</th></tr>" >>$FILENAMEONLY/$REPORTLOCATION/restnote.phtml
  OLDIFS=$IFS
  IFS=$'\n'
  rows=$(grep 'Operations from log file \|Time span: \|Epoch time: \|Length of time = ' $FILENAMEONLY/$REPORTLOCATION/operation-assessment.html | paste -d" " - - - - | grep -v ldap | sed 's/pre/td/g')
  for row in $rows; do
    echo "<tr><tt>$row</tt></tr>" >>$FILENAMEONLY/$REPORTLOCATION/restnote.phtml
  done
  echo "</table><hr>" >>$FILENAMEONLY/$REPORTLOCATION/restnote.phtml
  IFS=$OLDIFS
  cat /Users/robert.faller/projects/SawMill/content/chartheader.phtml $FILENAMEONLY/$TMPLOCATION/opscolumns.data $FILENAMEONLY/$TMPLOCATION/etimescolumns.data $FILENAMEONLY/$TMPLOCATION/ops.data $FILENAMEONLY/$TMPLOCATION/etimes.data /Users/robert.faller/projects/SawMill/content/charttailer.phtml $FILENAMEONLY/$REPORTLOCATION/restnote.phtml >$FILENAMEONLY/$REPORTLOCATION/allrestops.html
  echo "</body></html>" >>$FILENAMEONLY/$REPORTLOCATION/allrestops.html
  echo "<font face=\"Arial Unicode MS\"><a href=./allrestops.html>REST operations</a><br></font><hr size=\"2\" width=\"100%\">" >>$FILENAMEONLY/$REPORTLOCATION/report.html
  echo "...completed"
fi

if $firstrun; then

  if $IPASSESS; then
    echo -n "Assess IP address activity ..."
    echo "<html><head></head><body>" >$FILENAMEONLY/$REPORTLOCATION/ip-assessment.html
    echo "<table id=\"iptable\" class=\"searchablesortable\" cellpadding=\"1\" border=\"1\">" >>$FILENAMEONLY/$REPORTLOCATION/ip-assessment.html
    echo "<thead><tr><th onclick=\"sortTable(0)\">transactions</th><th onclick=\"sortTable(1)\">IP</th><th onclick=\"sortTable(2)\">status</th></tr></thead><tbody>" >>$FILENAMEONLY/$REPORTLOCATION/ip-assessment.html
    while read INPUT; do
      echo "<tr><td>${INPUT//","/</td><td>}</td></tr>" >>$FILENAMEONLY/$REPORTLOCATION/ip-assessment.html
    done <$FILENAMEONLY/$REPORTLOCATION/ip-activity.csv
    echo "</tbody></table></body></html>" >>$FILENAMEONLY/$REPORTLOCATION/ip-assessment.html
    echo "<a href=./ip-assessment.html>IP Assessment</a><hr>" >>$FILENAMEONLY/$REPORTLOCATION/report.html
    echo "...completed"
  fi

  if $IDASSESS; then
    echo -n "Assess identity activity ..."
    echo "<html><head></head><body>" >$FILENAMEONLY/$REPORTLOCATION/identity-assessment.html
    echo "<table id=\"identitytable\" class=\"searchablesortable\" cellpadding=\"1\" border=\"1\">" >>$FILENAMEONLY/$REPORTLOCATION/identity-assessment.html
    echo "<thead><tr><th onclick=\"sortTable(0)\">transactions</th><th onclick=\"sortTable(1)\">UserId</th><th onclick=\"sortTable(2)\">method</th><th onclick=\"sortTable(3)\">status</th></tr></thead><tbody>" >>$FILENAMEONLY/$REPORTLOCATION/identity-assessment.html
    while read INPUT; do
      echo "<tr><td>${INPUT//,/</td><td>}</td></tr>" >>$FILENAMEONLY/$REPORTLOCATION/identity-assessment.html
    done <$FILENAMEONLY/$REPORTLOCATION/identity-activity.csv
    echo "</tbody></table></body></html>" >>$FILENAMEONLY/$REPORTLOCATION/identity-assessment.html
    echo "<a href=./identity-assessment.html>Identity Assessment</a><hr>" >>$FILENAMEONLY/$REPORTLOCATION/report.html
    echo "...completed"
  fi

fi

#echo "<tr><td><pre><a href=https://ipinfo.io/$ipvalue>$ipvalue</a></pre></td><td><pre>$successful</pre></td><td><pre>$failed</pre></td></tr>" >>./report/ip-assessment.html
#echo "<tr><td><pre><a href=https://ipinfo.io/40.112.181.172>40.112.181.172</a></pre></td><td><pre>SAMPLE</pre></td><td><pre>-</pre></td></tr>" >>./report/ip-assessment.html

exit
#=== left off VVVVVVVV

if $IDASSESS; then
  echo "<html><head></head><body>" >./report/id-assessment.html
  echo "<table id=\"idtable\" class=\"searchablesortable\" cellpadding=\"1\" border=\"1\"><tbody>" >>./report/id-assessment.html
  echo "<tr><td>Id</td><td>Number of SUCCESSFUL operations</td><td>Number of FAILED operations</td><td>success:fail ratio score</td></tr>" >>./report/id-assessment.html
  # echo "<thead><tr><th onclick=\"sortTableID(0)\">ID</th><th onclick=\"sortTableID(1)\">SUCCESSFUL-operations</th><th onclick=\"sortTableID(2)\">FAILED-operations</th><th onclick=\"sortTableID(3)\">Score</th></tr></thead><tbody>" >>./report/report.html
  idvaluecount=0
  while read idvalue; do
    declare -i failed=$(grep -m 1 "$idvalue" ./tmp/all-ids-sorted.txt | grep FAILED | cut -f1 -d" ")
    declare -i successful=$(grep -m 1 "$idvalue" ./tmp/all-ids-sorted.txt | grep SUCCESSFUL | cut -f1 -d" ")
    if (($failed >= 1)); then
      #    ratio=$(echo $successful / $failed | bc -l)
      declare -i totalopcount=$(echo $successful + $failed | bc -l)
      ratio=$(echo $failed / $totalopcount | bc -l)
      printf -v score "%.4f" $ratio
    else
      ratio=$successful
      score="-"
    fi
    headervalue=$(($idvaluecount % 20))
    echo "<tr><td><pre>" >>./report/id-assessment.html
    #  echo "<form id=\"dig_$idvaluecount\" name=\"dig_$idvaluecount\" method=\"POST\" action=\"kestreldig\">" >>./report/report.html
    #  echo "<input id=\"submit_$idvaluecount\" type=\"submit\" value=$idvalue></form>" >>./report/report.html
    #    idonly=$(echo $idvalue | cut -f1 -d",")
    #    echo "$idonly" >>./report/report.html
    echo "$idvalue" >>./report/id-assessment.html
    echo "</pre></td>" >>./report/id-assessment.html
    ((idvaluecount++))
    if (($failed == 0)); then
      echo "<td><pre>$successful</pre></td><td><pre>$failed</pre></td><td><pre>$score</pre></td>" >>./report/id-assessment.html
    else
      if (($successful >= $failed)); then
        echo "<td><pre>$successful</pre></td><td><pre>$failed</pre></td><td bgcolor=\"lightyellow\"><pre>$score</pre></td>" >>./report/id-assessment.html
      else
        if (($successful >= 1)); then
          echo "<td><pre>$successful</pre></td><td><pre>$failed</pre></td><td bgcolor=\"pink\"><pre>$score</pre></td>" >>./report/id-assessment.html
        else
          echo "<td><pre>$successful</pre></td><td><pre>$failed</pre></td><td bgcolor=\"red\"><pre>$score</pre></td>" >>./report/id-assessment.html
        fi
      fi
    fi
    echo "</tr>" >>./report/id-assessment.html
  done <./tmp/all-idsonly.txt
  echo "</tbody></table></pre>" >>./report/id-assessment.html
  cat $SCRIPTHOME/sortTable.js >>./report/id-assessment.html
  echo "</body></html>" >>./report/id-assessment.html
  echo "<a href=./id-assessment.html>ID Assessment</a><hr>" >>./report/report.html
fi
# cat $SCRIPT_HOME/sortTableID.js >>./report/report.html
echo "<hr><pre> --- END OF REPORT --- </body> </html>" >>./report/report.html
echo "</body> </html>" >>./report/report.html

# rm -r tmp
