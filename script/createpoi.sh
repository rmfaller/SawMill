#!/bin/bash
#
LOGPREFIX="access.audit.json"
DSLDAPLOGPREFIX="ldap-access.audit.json"
DSHTTPLOGPREFIX="http-access.audit.json"

H0="{ \"timestampformat\":\"yyyy-MM-dd"
H1="'T'"
H2="HH:mm:ss\",\"fielddelimiter\":\"JSON\",\"timestampfield\":\"timestamp\",\"timescale\":\"elapsedTimeUnits\",\"poi\":"
JSONHEADER=$H0$H1$H2

if [[ $1 ]]; then
  POIHOME="$1/poi"
  DATA="$1/data"
  if [ ! -d $POIHOME ]; then
    echo "$POIHOME does not exist; Please create first."
    exit
  fi
else
  echo "Argument 1 - file system directory location (instance) to place the poi JSON file - not provided"
  exit
fi

if [[ $2 == "lastlog" ]]; then
  ALLLOGS=false
else
  ALLLOGS=true
fi

if $ALLLOGS; then
  rotatedldaplogs=$(find $DATA -type f \( -name "ldap-access.audit.json.*" -a -not -name "*.txt" -a -not -name "*.extended" -a -not -name "*.tmp" \) -print | sort )
  if [ -z "$rotatedldaplogs" ]; then
    ldaplogs="$(find $DATA -name "ldap-access.audit.json" -print)"
  else
    ldaplogs="$(echo $rotatedldaplogs) $(find $DATA -name "ldap-access.audit.json" -print)"
  fi
  rotatedhttplogs=$(find $DATA -type f \( -name "access.audit.json-*" -o -name "http-access.audit.json.*" -a -not -name "*.txt" \) -print | sort )
  if [ -z "$rotatedhttplogs" ]; then
    httplogs="$(find $DATA -type f \( -name "access.audit.json" -o -name "http-access.audit.json" \) -print)"
  else
    httplogs="$(echo $rotatedhttplogs) $(find $DATA -type f \( -name "access.audit.json" -o -name "http-access.audit.json" \) -print)"
  fi
else
  ldaplogs=$(find $DATA -name "ldap-access.audit.json" -print)
  httplogs=$(find $DATA -type f \( -name "access.audit.json" -o -name "http-access.audit.json" \) -print)
fi

if ! [ -z "$ldaplogs" ]; then
  for log in $ldaplogs; do
    if ! [ -f $log.extended ]; then
      cat $log |
        sed 's/\"additionalItems\":{\"persistent\":null}/\"searchType\":\"persistent\",\"additionalItems\":{\"persistent\":null}/' |
        sed 's/\"additionalItems\":{\"unindexed\":null}/\"searchType\":\"unindexed\",\"additionalItems\":{\"unindexed\":null}/' >$log.tmp &
      echo "$(date)" >$log.extended
    fi
  done
  wait
  for log in $ldaplogs; do
    if [ -f $log.tmp ]; then
      mv $log.tmp $log
    fi
    cat $log | ~/bin/jq -c '[.request.operation, .request.opType, .response.status, .response.statusCode, .response.searchType]' | sort -u >$POIHOME/$(basename $log)-ldap-ops.txt &
  done
  wait
  cat $POIHOME/ldap-access.audit.json*-ldap-ops.txt | tr -d "[" | tr -d "]" | sort -u >$POIHOME/ldap-poi.txt
  etu=$(grep -m 1 elapsedTimeUnits $log | $HOME/bin/jq '.response.elapsedTimeUnits')
  pois=$(cat $POIHOME/ldap-poi.txt | grep -v UNBIND | tr -d "\"" | tr "," "~" | sort -r | uniq)
  if [[ $pois ]]; then
    echo $JSONHEADER >$POIHOME/ldap-poi.json
    printf '%s\n' "${pois[@]}" | $HOME/bin/jq -R . | $HOME/bin/jq -s . >>$POIHOME/ldap-poi.json
    echo "," >>$POIHOME/ldap-poi.json
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
      echo "\"$poi\": { \"identifiers\": [ " >>$POIHOME/ldap-poi.json
      echo -n '"\"operation\":\"' >>$POIHOME/ldap-poi.json
      echo -n "$operation\\\"\"" >>$POIHOME/ldap-poi.json
      if [[ $opType ]]; then
        echo "," >>$POIHOME/ldap-poi.json
        echo -n '"\"opType\":\"' >>$POIHOME/ldap-poi.json
        echo -n "$opType\\\"\"" >>$POIHOME/ldap-poi.json
      fi
      if [[ $status ]]; then
        echo "," >>$POIHOME/ldap-poi.json
        echo -n '"\"status\":\"' >>$POIHOME/ldap-poi.json
        echo -n "$status\\\"\"" >>$POIHOME/ldap-poi.json
      fi
      if [[ $statuscode ]]; then
        echo "," >>$POIHOME/ldap-poi.json
        echo -n '"\"statusCode\":\"' >>$POIHOME/ldap-poi.json
        echo "$statuscode\\\"\"" >>$POIHOME/ldap-poi.json
      fi
      if [[ $searchtype ]]; then
        echo "," >>$POIHOME/ldap-poi.json
        echo -n '"\"searchType\":\"' >>$POIHOME/ldap-poi.json
        echo "$searchtype\\\"\"" >>$POIHOME/ldap-poi.json
      fi
      echo '],
  "lapsedtimefield": "elapsedTime",' >>$POIHOME/ldap-poi.json
      echo "\"timescale\": $etu," >>$POIHOME/ldap-poi.json
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
      echo "\"sla\": $sla" >>$POIHOME/ldap-poi.json
      echo '},' >>$POIHOME/ldap-poi.json
    done
    echo '"end":{}
         }' >>$POIHOME/ldap-poi.json
    IFS=$OLDIFS
  fi
fi

if ! [ -z "$httplogs" ]; then
  for log in $httplogs; do
    cat $log | ~/bin/jq -c '[.http.request.method, .http.request.path, .response.status]' | sort -u >$POIHOME/$(basename $log)-http-ops.txt &
  done
  wait
  cat $POIHOME/*access.audit.json*-http-ops.txt | tr -d "[" | tr -d "]" | sort -u >$POIHOME/http-poi.txt
  cat $POIHOME/http-poi.txt | grep -v '\"DELETE\"\|\"POST\"\|\"PUT\"\|\"PATCH\"\|\"GET\"\|\"HEAD\"' | sort | uniq >$POIHOME/http-unknownverbs.txt
  pois=$(cat $POIHOME/http-poi.txt | grep '\"DELETE\"\|\"POST\"\|\"PUT\"\|\"PATCH\"\|\"GET\"' | tr -d "\"" | tr "," "~" | sort | uniq)
  if [[ $pois ]]; then
    echo $JSONHEADER >$POIHOME/http-poi.json
    printf '%s\n' "${pois[@]}" | $HOME/bin/jq -R . | $HOME/bin/jq -s . >>$POIHOME/http-poi.json
    echo "," >>$POIHOME/http-poi.json
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
      echo "\"$poi\": { \"identifiers\": [ " >>$POIHOME/http-poi.json
      echo -n '"\"method\":\"' >>$POIHOME/http-poi.json
      echo "$method\\\"\"," >>$POIHOME/http-poi.json
      echo -n '"\"path\":\"' >>$POIHOME/http-poi.json
      echo "$path\\\"\"," >>$POIHOME/http-poi.json
      echo -n '"\"status\":\"' >>$POIHOME/http-poi.json
      echo "$status\\\"\"" >>$POIHOME/http-poi.json
      echo '],"lapsedtimefield": "elapsedTime",' >>$POIHOME/http-poi.json
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
      echo "\"sla\": $sla" >>$POIHOME/http-poi.json
      echo '},' >>$POIHOME/http-poi.json
    done
    echo '"end":{}
         }' >>$POIHOME/http-poi.json
    IFS=$OLDIFS
  fi
fi
