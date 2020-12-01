#!/bin/bash
#
LOGPREFIX="access.audit.json"
DSLDAPLOGPREFIX="ldap-access.audit.json"
DSHTTPLOGPREFIX="http-access.audit.json"

h0="{ \"timestampformat\":\"yyyy-MM-dd"
h1="'T'"
h2="HH:mm:ss\",\"fielddelimiter\":\"JSON\",\"timestampfield\":\"timestamp\",\"timescale\":\"elapsedTimeUnits\",\"poi\":"
jsonheader=$h0$h1$h2

if [[ $1 ]]; then
  POIHOME=$1
  if [ ! -d $POIHOME ]; then
    echo "$POIHOME does not exist; Please create first."
    exit
  fi
else
  echo "Argument 1 - full path to the file system directory location to place the poi JSON file - not provided"
  exit
fi

if [[ $2 ]]; then
  POISOURCE=$2
  if [ ! -d $POIHOME/$POISOURCE ]; then
    echo "$POISOURCE does not exist; Please correct."
    exit
  fi
else
  echo "Argument 2 - full path to the file system directory to collect poi from i.e. where the JSON log file(s) are - not provided"
  exit
fi

if [[ $3 ]]; then
  LOGTYPE=""
  case $3 in
  am | idm | ig)
    LOGTYPE=$3http
    logs=$(find $POIHOME/$POISOURCE -name "$LOGPREFIX*" -print)
    echo -n >$POIHOME/$POISOURCE/$LOGTYPE-attrs.txt
    for log in $logs; do
      cat $log | $HOME/bin/jq '.http.request.method,.component,.response.status' | paste -d"," - - - | sort | uniq >>$POIHOME/$POISOURCE/$LOGTYPE-attrs.txt
    done
#    pois=$(cat $POIHOME/$POISOURCE/$LOGTYPE-attrs.txt | sort | uniq | tr -d "\"" | tr "," "~")
    cat $POIHOME/$POISOURCE/$LOGTYPE-attrs.txt | grep  -v '\"DELETE\"\|\"POST\"\|\"PUT\"\|\"PATCH\"\|\"GET\"\|\"HEAD\"' | sort | uniq > $POIHOME/$POISOURCE/$LOGTYPE-unknownverbs.txt
    pois=$(cat $POIHOME/$POISOURCE/$LOGTYPE-attrs.txt | grep  '\"DELETE\"\|\"POST\"\|\"PUT\"\|\"PATCH\"\|\"GET\"\|\"HEAD\"' | tr -d "\"" | tr "," "~" | sort | uniq)
    if [[ $pois ]]; then
      echo $jsonheader >$POIHOME/$POISOURCE/$LOGTYPE-poi.json
      printf '%s\n' "${pois[@]}" | $HOME/bin/jq -R . | $HOME/bin/jq -s . >>$POIHOME/$POISOURCE/$LOGTYPE-poi.json
      echo "," >>$POIHOME/$POISOURCE/$LOGTYPE-poi.json
      OLDIFS=$IFS
      IFS=$'\n'
      for poi in $pois; do
        method=$(echo $poi | cut -d"~" -f1)
        component=$(echo $poi | cut -d"~" -f2)
        status=$(echo $poi | cut -d"~" -f3)
        if [ "$component" = "null" ]; then
          component=""
        fi
        echo "\"$poi\": { \"identifiers\": [ " >>$POIHOME/$POISOURCE/$LOGTYPE-poi.json
        echo -n '"\"method\":\"' >>$POIHOME/$POISOURCE/$LOGTYPE-poi.json
        echo "$method\\\"\"," >>$POIHOME/$POISOURCE/$LOGTYPE-poi.json
        echo -n '"\"component\":\"' >>$POIHOME/$POISOURCE/$LOGTYPE-poi.json
        echo "$component\\\"\"," >>$POIHOME/$POISOURCE/$LOGTYPE-poi.json
        echo -n '"\"status\":\"' >>$POIHOME/$POISOURCE/$LOGTYPE-poi.json
        echo "$status\\\"\"" >>$POIHOME/$POISOURCE/$LOGTYPE-poi.json
        echo '],"lapsedtimefield": "elapsedTime",
        "sla": 200
    },' >>$POIHOME/$POISOURCE/$LOGTYPE-poi.json
      done
      echo '"end":{}
         }' >>$POIHOME/$POISOURCE/$LOGTYPE-poi.json
      IFS=$OLDIFS
    fi
    ;;
  ds | cts | cfg | idr)
    LOGTYPE="$3ldap"
    logs=$(find $POIHOME/$POISOURCE -name "$DSLDAPLOGPREFIX*" -print)
    echo -n >$POIHOME/$POISOURCE/$LOGTYPE-attrs.txt
    for log in $logs; do
      cat $log | $HOME/bin/jq '.request.operation,.request.opType,.response.status,.response.statusCode' | paste -d"," - - - - | sort | uniq >>$POIHOME/$POISOURCE/$LOGTYPE-attrs.txt
    done
    pois=$(cat $POIHOME/$POISOURCE/$LOGTYPE-attrs.txt | grep -v UNBIND | tr -d "\"" | tr "," "~" | sort -r | uniq)
    if [[ $pois ]]; then
      echo $jsonheader >$POIHOME/$POISOURCE/$LOGTYPE-poi.json
      printf '%s\n' "${pois[@]}" | $HOME/bin/jq -R . | $HOME/bin/jq -s . >>$POIHOME/$POISOURCE/$LOGTYPE-poi.json
      echo "," >>$POIHOME/$POISOURCE/$LOGTYPE-poi.json
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
        echo "\"$poi\": { \"identifiers\": [ " >>$POIHOME/$POISOURCE/$LOGTYPE-poi.json
        echo -n '"\"operation\":\"' >>$POIHOME/$POISOURCE/$LOGTYPE-poi.json
        echo -n "$operation\\\"\"" >>$POIHOME/$POISOURCE/$LOGTYPE-poi.json
        if [[ $opType ]]; then
          echo "," >>$POIHOME/$POISOURCE/$LOGTYPE-poi.json
          echo -n '"\"opType\":\"' >>$POIHOME/$POISOURCE/$LOGTYPE-poi.json
          echo -n "$opType\\\"\"" >>$POIHOME/$POISOURCE/$LOGTYPE-poi.json
        fi
        if [[ $status ]]; then
          echo "," >>$POIHOME/$POISOURCE/$LOGTYPE-poi.json
          echo -n '"\"status\":\"' >>$POIHOME/$POISOURCE/$LOGTYPE-poi.json
          echo -n "$status\\\"\"" >>$POIHOME/$POISOURCE/$LOGTYPE-poi.json
          #else
          #                  echo "," >>$POIHOME/$POISOURCE/$LOGTYPE-poi.json
        fi
        if [[ $statuscode ]]; then
          echo "," >>$POIHOME/$POISOURCE/$LOGTYPE-poi.json
          echo -n '"\"statusCode\":\"' >>$POIHOME/$POISOURCE/$LOGTYPE-poi.json
          echo "$statuscode\\\"\"" >>$POIHOME/$POISOURCE/$LOGTYPE-poi.json
          #        else
          #          echo "," >>$POIHOME/$POISOURCE/$LOGTYPE-poi.json
        fi
        echo '],
  "lapsedtimefield": "elapsedTime",
  "sla": 200
    },' >>$POIHOME/$POISOURCE/$LOGTYPE-poi.json
      done
      echo '"end":{}
         }' >>$POIHOME/$POISOURCE/$LOGTYPE-poi.json
      IFS=$OLDIFS
    fi
    #=================
    LOGTYPE="$3http"
    logs=$(find $POIHOME/$POISOURCE -name "$DSHTTPLOGPREFIX*" -print)
    echo -n >$POIHOME/$POISOURCE/$LOGTYPE-attrs.txt
    for log in $logs; do
      cat $log | $HOME/bin/jq '.http.request.method,.response.statusCode,.response.status' | paste -d"," - - - | sort | uniq >>$POIHOME/$POISOURCE/$LOGTYPE-attrs.txt
    done
#    pois=$(cat $POIHOME/$POISOURCE/$LOGTYPE-attrs.txt | tr -d "\"" | tr "," "~" | sort | uniq | grep 'DELETE\|POST\|PUT\|PATCH\|GET')
    cat $POIHOME/$POISOURCE/$LOGTYPE-attrs.txt | grep  -v '\"DELETE\"\|\"POST\"\|\"PUT\"\|\"PATCH\"\|\"GET\"' | sort | uniq > $LOGTYPE-unknownverbs.txt
    pois=$(cat $POIHOME/$POISOURCE/$LOGTYPE-attrs.txt | grep  '\"DELETE\"\|\"POST\"\|\"PUT\"\|\"PATCH\"\|\"GET\"' | tr -d "\"" | tr "," "~" | sort | uniq)
    if [[ $pois ]]; then
      echo $jsonheader >$POIHOME/$POISOURCE/$LOGTYPE-poi.json
      printf '%s\n' "${pois[@]}" | $HOME/bin/jq -R . | $HOME/bin/jq -s . >>$POIHOME/$POISOURCE/$LOGTYPE-poi.json
      echo "," >>$POIHOME/$POISOURCE/$LOGTYPE-poi.json
      OLDIFS=$IFS
      IFS=$'\n'
      for poi in $pois; do
        method=$(echo $poi | cut -d"~" -f1)
        component=$(echo $poi | cut -d"~" -f2)
        status=$(echo $poi | cut -d"~" -f3)
        if [ "$component" = "null" ]; then
          component=""
        fi
        echo "\"$poi\": { \"identifiers\": [ " >>$POIHOME/$POISOURCE/$LOGTYPE-poi.json
        echo -n '"\"method\":\"' >>$POIHOME/$POISOURCE/$LOGTYPE-poi.json
        echo "$method\\\"\"," >>$POIHOME/$POISOURCE/$LOGTYPE-poi.json
        echo -n '"\"statusCode\":\"' >>$POIHOME/$POISOURCE/$LOGTYPE-poi.json
        echo "$component\\\"\"," >>$POIHOME/$POISOURCE/$LOGTYPE-poi.json
        echo -n '"\"status\":\"' >>$POIHOME/$POISOURCE/$LOGTYPE-poi.json
        echo "$status\\\"\"" >>$POIHOME/$POISOURCE/$LOGTYPE-poi.json
        echo '],"lapsedtimefield": "elapsedTime",
        "sla": 200
    },' >>$POIHOME/$POISOURCE/$LOGTYPE-poi.json
      done
      echo '"end":{}
         }' >>$POIHOME/$POISOURCE/$LOGTYPE-poi.json
      IFS=$OLDIFS
    fi
    ;;
  *)
    echo "Argument 3 = $3 - type of log file(s) - which not correct. Use one of the following: am, ds, cts, cfg, idm, idr, ig"
    exit
    ;;
  esac
else
  echo "Argument 3 - type of log file(s) - not provided. Use one of the following: am, ds, cts, cfg, idm, idr, ig"
  echo "am  = AM JSON logs"
  echo "ds  = DS (User store) JSON logs"
  echo "cts = DS (CTS) JSON logs"
  echo "cfg = DS (config store for AM) JSON logs"
  echo "idm = IDM JSON logs"
  echo "idr = DS (IDM repository) JSON logs"
  echo "ig  = IG JSON logs"
  exit
fi

#logcount=0
#for log in $logs; do
#  if (($logcount == 0)); then
#    java -jar $HOME/projects/SawMill/dist/SawMill.jar --poi $POIHOME/$LOGTYPE-poi.json --totalsonly --condense $log
#  else
#    java -jar $HOME/projects/SawMill/dist/SawMill.jar --poi $POIHOME/$LOGTYPE-poi.json --totalsonly --noheader --condense $log
#  fi
#  ((logcount++))
#done
# REST: for log in $logs; do cat $log | $HOME/bin/jq '.http.request.method,.component,.response.status' | paste -d" " - - - | sort | uniq > summary; done; cat summary | sort | uniq
# LDAP: for log in $logs; do cat $log | $HOME/bin/jq '.request.operation,.request.opType,.response.status' | paste -d" " - - - | sort | uniq > summary; done; cat summary | sort | uniq
# jqstring=".http.request.method,.component,.response.status"
# for log in $logs; do cat $log | $HOME/bin/jq "$jqstring" | paste -d" " - - - | sort | uniq
# for log in $logs; do cat $log | $HOME/bin/jq "$jqstring" | paste -d" " - - - | sort | uniq; done
#  logcount=0
#  for log in $logs; do
#    if (( $logcount == 0)); then
#      java -jar $HOME/projects/SawMill/dist/SawMill.jar --poi ./$AMPOI --totalsonly --condense $log
#    else
#      java -jar $HOME/projects/SawMill/dist/SawMill.jar --poi ./$AMPOI --totalsonly --noheader --condense $log
#    fi
#    ((logcount++))
#  done
