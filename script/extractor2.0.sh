#!/bin/sh
# extractor 2.0
#
# Created by Lee Trujillo (lee.trujillo@forgerock.com)
#
# CDDL HEADER START
#
# The contents of this file are subject to the terms of the
# Common Development and Distribution License, Version 1.0 only
# (the "License").  You may not use this file except in compliance
# with the License.
#
# You can obtain a copy of the license at
# trunk/opends/resource/legal-notices/OpenDS.LICENSE
# or https://OpenDS.dev.java.net/OpenDS.LICENSE.
# See the License for the specific language governing permissions
# and limitations under the License.
#
# When distributing Covered Code, include this CDDL HEADER in each
# file and include the License file at
# trunk/opends/resource/legal-notices/OpenDS.LICENSE.  If applicable,
# add the following below this CDDL HEADER, with the fields enclosed
# by brackets "[]" replaced with your own identifying information:
#      Portions Copyright [yyyy] [name of copyright owner]
#
# CDDL HEADER END
#
#       Copyright 2018-2019 ForgeRock AS.

version="2.0"
tab=0
btab=0
printedbackend=0
totaldbcache=0
totalentries=0
totalconnectioncount=0
currentbase=""
alert=""
longestIndexType=0
longestStorageSchemeName=0
heavySchemeAlertDisplay=""
entryLimitAlert=0
highCpuThreadsFound=0
debugindex=1
displayall=$2
kbas=""
healthScores=""

# the version to start EOSL checks
minimumEoslVersion="3"

# Index Types
ctsIndexes='coreToken|etag'
amCfgIndexes='sunxmlkeyvalue|iplanet-am-user-federation-info-key|sun-fm-saml2-nameid-infokey'
defaultIndexes='ds-cfg-attribute=aci|ds-cfg-attribute=cn|ds-cfg-attribute=givenName|ds-cfg-attribute=mail,|ds-cfg-attribute=member,|ds-cfg-attribute=memberof,|ds-cfg-attribute=objectClass|ds-cfg-attribute=sn|ds-cfg-attribute=telephoneNumber|ds-cfg-attribute=uid|ds-cfg-attribute=uniqueMember'
systemIndexes='ds-sync-conflict|ds-sync-hist|ds-cfg-attribute=entryUUID'

# Section Header summary information
serverinfo="Basic server information including Connection Handlers, Ports and Current Connection counts."
backendinfo="Displays all backends and the most relevant configuration. Also displays alerts when bad configuration is encountered."
indexinfo="Displays all index definitions, types and alerts when Excessive Index Limits are found and whether the index is default, system, custom or a cts index."
replicationinfo="Displays replica type, replication domain and configured RS's. Also displays connected DS's and RS's."
passwordpolicyinfo="Displays all password policies, password attributes, storage schemes and alerts when heavy weight policies are found."
certificateinfo="Displays each connection handlers certificate and their expiration date. Warns of expiring certificates."
jvminfo="Displays Java version, memory used, cpu's and all JVM based parameters. Alerts when tuning is needed"
otherinfo="Displays miscellaneous information found"
cpuusageinfo="Displays a range of CPU % for all threads used per stack as well as the overall total CPU % used."
processinfo="Displays if the process is changing over time, based on the jstacks captured."
healthstatusinfo="Displays basic health which may indicate if elements within a section need addressing"

# Knowledge Base Indexes
# Note any Doc links for DS 5.0 must be prefaced by a 40 instead of a 50, below.
kburl='https://backstage.forgerock.com/knowledge/kb/article/'
jurl='https://bugster.forgerock.org/jira/browse/'

# SERVER INFO
KBI000="a18529200#DS DS/OpenDJ release and EOSL dates"

# Connections Handers

# BACKEND INFO
KBI100="a70365000 How do I tune DS/OpenDJ (All versions) process sizes: JVM heap and database cache?"
KBI101="a28635900#high High index entry limits"
KBI102="OPENDJ-5137 Reading compressed or encrypted entries fails to close the InflaterInputStream"
KBI103="a49979000 How do I tune the DS/OpenDJ (All versions) database file cache?"
KBI104="a91168317 How do I check if a backend is online in DS/OpenDJ (All versions)?"
KBI105="shared-cache JE Shared Cache Enabled"
KBI105URL65="https://backstage.forgerock.com/docs/ds/6.5/configref/#objects-global-je-backend-shared-cache-enabled"

# INDEX INFO
KBI200="a28635900#high High index entry limits"
KBI201="a46097400 How do I rebuild indexes in DS/OpenDJ (All versions)?"
KBI202="xxxxxxxxx Reserved for MISSING SYSTEM INDEX alerts"

# REPLICATION INFO
KBI300="Replication-Stopped Replication Stopped"
KBI300URL30="https://backstage.forgerock.com/docs/opendj/3/admin-guide/#stop-repl-tmp"
KBI300URL35="https://backstage.forgerock.com/docs/opendj/3.5/admin-guide/#stop-repl-tmp"
KBI300URL50="https://backstage.forgerock.com/docs/ds/5/admin-guide/#stop-repl-tmp"
KBI300URL55="https://backstage.forgerock.com/docs/ds/5.5/admin-guide/#stop-repl-tmp"
KBI300URL60="https://backstage.forgerock.com/docs/ds/6/admin-guide/#stop-repl-tmp"
KBI300URL65="https://backstage.forgerock.com/docs/ds/6.5/admin-guide/#stop-repl-tmp"

KBI301="a37856549 How do I find replication conflicts in DS/OpenDJ (All versions)?"

KBI302="changelog-enabled The changelog is disabled and is not available to clients."
KBI302URL65="https://backstage.forgerock.com/docs/ds/6.5/configref/#objects-replication-server-changelog-enabled"

# PASSWORD POLICY INFO
KBI400="Password-Storage-Warning Password Storage Warning"
KBI400URL40="https://backstage.forgerock.com/docs/ds/5/admin-guide/#configure-pwd-storage"
KBI400URL55="https://backstage.forgerock.com/docs/ds/5.5/admin-guide/#configure-pwd-storage"
KBI400URL60="https://backstage.forgerock.com/docs/ds/6/admin-guide/#configure-pwd-storage"
KBI400URL65="https://backstage.forgerock.com/docs/ds/6.5/admin-guide/#configure-pwd-storage"
KBI400URL70="https://backstage.forgerock.com/docs/ds/6.5/admin-guide/#configure-pwd-storage"

# CERTIFICATE INFO
KBI500="#chap-change-certs Changing Server Certificates"
KBI500URL26="https://backstage.forgerock.com/docs/opendj/2.6/admin-guide/#chap-change-certs"
KBI500URL30="https://backstage.forgerock.com/docs/opendj/3/admin-guide/#chap-change-certs"
KBI500URL35="https://backstage.forgerock.com/docs/opendj/3.5/admin-guide/#chap-change-certs"
KBI500URL40="https://backstage.forgerock.com/docs/ds/5/admin-guide/#chap-change-certs"
KBI500URL55="https://backstage.forgerock.com/docs/ds/5.5/admin-guide/#chap-change-certs"
KBI500URL60="https://backstage.forgerock.com/docs/ds/6/admin-guide/#chap-change-certs"
KBI500URL65="https://backstage.forgerock.com/docs/ds/6.5/admin-guide/#chap-change-certs"
KBI500URL70="https://backstage.forgerock.com/docs/ds/6.5/admin-guide/#chap-change-certs"

# JVM ARGS and SYSTEM INFO
KBI600="a80553100 FAQ: DS/OpenDJ performance and tuning"

KBI601="prerequisites-processors Choosing a Processor Architecture"
KBI601URL40="https://backstage.forgerock.com/docs/ds/5/install-guide/#prerequisites-processors"
KBI601URL55="https://backstage.forgerock.com/docs/ds/5.5/install-guide/#prerequisites-processors"
KBI601URL60="https://backstage.forgerock.com/docs/ds/6/install-guide/#prerequisites-processors"
KBI601URL65="https://backstage.forgerock.com/docs/ds/6.5/install-guide/#prerequisites-processors"
KBI601URL70="https://backstage.forgerock.com/docs/ds/6.5/install-guide/#prerequisites-processors"

KBI602="a54695000 How do I enable Garbage Collector (GC) Logging for DS/OpenDJ"

KBI609="a50989482 How do I disable TLS 1.3 when running DS 6.5 with Java 11?"
KBI610="OPENDJ-5260 Grizzly pre-allocates a useless MemoryManager"

# Other Info

usage()
{
	clear
        printf "%-80s\n" "--------------------------------------------------------------------------------" 
        printf "%-62s %s\n" "FR Extractor ${version}" "Extract Extractor" 
        printf "%-80s\n" "--------------------------------------------------------------------------------"
	printf "%s\n" "Usage: $0 [-f | -c | -e | -H]"
	printf "%s\n" ""
	printf "%s\n" "The Extractor us used to create a report on various critical and non-critical aspects from a DJ Support Extract"
	printf "%s\n" ""
	printf "%s\n" "-f, {config file}"
	printf "\t%s\n" "The full path to, and including the config.ldif file name."
	printf "\t%s\n" "Not required if used from within the config directory of an uncompressed DJ Extract"
	printf "%s\n" ""
	printf "%s\n" "-c, {display colors}"
	printf "\t%s\n" "Display all errors using easy to identify colors"
	printf "%s\n" ""
	printf "%s\n" "-e, {display experimental options}"
	printf "\t%s\n" "Display experimental sections"
	printf "%s\n" ""
	printf "%s\n" "-H, {display this help}"
	printf "%s\n" ""
	exit
}

debug()
{
	if [ "${debug}" = "1" ]; then
		date=`date "+%y%m%d-%H%M%S"`
		label=$1 # the main text label to display
		printf "%-7s\t%-13s\t%s\n" "${green}DEBUG${debugindex}${nocolor}" "${green}${date}${nocolor}" "${label}"
		debugindex=`expr ${debugindex} + 1`
	fi
}


while getopts f:cdeH w
do
    case $w in
    f) configFile=$OPTARG;;
    c) colorDisplay=1;;
    d) debug=1;;
    e) experimental=1;;
    H|?) usage; exit 1 ;;
    esac
done

debug "Checking for config files"
if [ "${configFile}" != "" ]; then
	configfile=${configFile}
	configFilePath=`dirname ${configfile}`
	cd ${configFilePath}
elif [ -r config/config.ldif ]; then
        configfile="./config.ldif"
	cd config/
elif [ -r ./config.ldif ]; then
        configfile="./config.ldif"
elif [ -r ../config.ldif ]; then
        configfile="../*config*/config.ldif"
	cd ../config/
else
        printf "%s\n" "No config.ldif files found"
	exit
fi
if [ "${colorDisplay}" = "1" ]; then
	red=`tput setaf 1`
	green=`tput setaf 2`
	yellow=`tput setaf 3`
	nocolor=`tput sgr0`
else
	red=''
	green=''
	yellow=''
	nocolor=''
fi
debug "Checking for monitor files"
if [ -s ../monitor/monitor.ldif ]; then
	monitorfile='../monitor/monitor.ldif'
debug "grepping majorVersion - begin"
	majorVersion=`grep "majorVersion" ${monitorfile} | sed "s/majorVersion: //"`
debug "grepping majorVersion - done"
	# Convert Windows CRLF files to pure ASCII
	# Look to use iconv
	# iconv -f UTF-16LE monitor.ldif > lee
	tr -d '\r' < ${monitorfile} > ${monitorfile}.ascii
	mv ${monitorfile}.ascii ${monitorfile}
elif [ -s ./monitor.ldif ]; then
	monitorfile='./monitor.ldif'
	majorVersion=`grep "majorVersion" ${monitorfile} | sed "s/majorVersion: //"`
	# Convert Windows CRLF files to pure ASCII
	tr -d '\r' < ${monitorfile} > ${monitorfile}.ascii
	mv ${monitorfile}.ascii ${monitorfile}
else
        printf "%s\n" "No cn=monitor files found"
fi

debug "Checking for profile files"
if [ -s ../config/profiles.version ]; then
	profilesfile='../config/profiles.version'
	# Convert Windows CRLF files to pure ASCII
	# Look to use iconv
	# iconv -f UTF-16LE monitor.ldif > lee
	tr -d '\r' < ${profilesfile} > ${profilesfile}.ascii
	mv ${profilesfile}.ascii ${profilesfile}
	dsprofiles=`cat ${profilesfile}`
elif [ -s ./profiles.version ]; then
	profilesfile='./profiles.version'
	# Convert Windows CRLF files to pure ASCII
	tr -d '\r' < ${profilesfile} > ${profilesfile}.ascii
	mv ${profilesfile}.ascii ${profilesfile}
	dsprofiles=`cat ${profilesfile}`
else
        printf "%s\n" "No profiles.version files found"
fi

debug "Checking for profile files - done"

if [ -s ../config/data.version ]; then
	dataversion=`cat ../config/data.version`
fi
if [ -s ./data.version ]; then
	dataversion=`cat ../config/data.version`
fi
if [ -s ../var/data.version ]; then
	dataversion=`cat ../var/data.version`
fi

format()
{
	# A simple method to format data gathered in the same way
	label=$1 # the main text label to display
	lvalue=$2 # the value for the label
	lelsevalue=$3 # if lvalue is null, then display the else value
	ldefault=$4 # a default value

	if [ "${ldefault}" != "" -a "${lvalue}" != "${ldefault}" -a "${lvalue}" != "NA" ]; then
		ldefault="(default is ${ldefault})"
	else
		ldefault=""
	fi

	calcLen2 "$1"; dl=${btab}
	if [ "${lvalue}" = "" ]; then
		printf "\t%-25s\t%-12s\t\t%s\n" "${label}" "${lelsevalue}" "${ldefault}" | log
	else
		printf "\t%-25s\t%-12s\t\t%s\n" "${label}" "${lvalue}" "${ldefault}" | log
	fi
}

log()
{
	if [ "${colorDisplay}" = "1" ]; then
		tee -ai /dev/null
	else
		tee -ai extract-report.log
	fi
}

addKB()
{
	thisKBID=$1
	for kba in ${kbas}; do
		if [ "${kba}" = "${thisKBID}" ]; then
			kbidFound=1
		fi
	done
	if [ "${kbidFound}" = "" ]; then
		debug "Added KBA ${thisKBID}"
		kbas="${kbas} ${thisKBID}"
	else
		debug "Rejected add of KBA ${thisKBID} to list -> ${kbas}"
	fi
	kbidFound=""
}

healthScore()
{
	if [ "${experimental}" = "" ]; then
		return
	fi
	thisSection=$1
	thisScore=$2
	for score in ${healthScores}; do
		if [ "${score}" = "${thisSection}=${thisScore}" -o "${score}" = "${thisSection}=RED" -o "${score}" = "${thisSection}=YELLOW" ]; then
			hsFound=1
		fi
	done
	if [ "${hsFound}" = "" ]; then
		debug "Added Health Score -> ${thisSection} ${thisScore}"
		healthScores="${healthScores} ${thisSection}=${thisScore}"
		eval "${thisSection}=${thisScore}"
		debug "${thisSection}=${thisScore}"
	else
		debug "Rejected add of Score ${thisSection}=${thisScore} to list -> ${healthScores}"
	fi
	hsFound=""
}

header()
{
clear

        printf "%-80s\n" "--------------------------------------------------------------------------------" | log
        printf "%-62s %s\n" "FR Extractor ${version}" "Extract Extractor" | log
        printf "%-80s\n" "--------------------------------------------------------------------------------" | log
	if [ -s ../supportextract.log ]; then
		extractverfull=`grep -i "VERSION:" ../supportextract.log | awk -F" " '{print $NF}'`
		extractvertype=`grep -i "VERSION:" ../supportextract.log | awk -F" " '{print $NF}' | sed "s/-/ /" | awk '{print $2}'`
		extractdate=`head -1 ../supportextract.log | awk '{print $1 " " $2}'`
		if [ "${extractverfull}" = '3.0' ]; then
			extractverfull="${extractverfull}-java"
		fi
		printf "\n" | log
		printf "\t%s\t\t%s %s\n" "Extract version:" "${extractverfull}" | log
		printf "\t%s\t\t\t%s\n" "Extract date:" "${extractdate}" | log
	else
		printf "\n\t%s\t\t%s\n" "Extract version:" "NA" | log
	fi
	if [ "${configfile}" = "" ]; then
		printf "%s\n" "The config.ldif file was not found"
		printf "%s\n" "Either supply a config file paramter $0 <pathto>/config.ldif or change into the config directory of a Suport Extract"
		exit 1
	fi
	printf "\n"
	if [ "${monitorfile}" = "" ]; then
		printf "\n\t%-11s\t\t\t%s\n" "Data check:" "monitor.ldif not available" | log
	fi
	if [ "${profilesfile}" = "" ]; then
		printf "\t%-11s\t\t\t%s\n" "Data check:" "profiles.version not available" | log
	if [ "${dataversion}" = "" ]; then
		printf "\t%-11s\t\t\t%s\n" "Data check:" "data.version not available" | log
	fi
	fi
}

sighdlr()
{
        date=`date "+%y%m%d-%H%M%S"`
        echo
        printf "%s\n" "Stopped   - $date"
        exit
}

trap sighdlr INT

printKey()
{

echo "
Key (Backend config)

BackendID:  	See: backend-id
BaseDN:  	See: base-dn
Db-Cache:  	See: db-cache-percent
Enabled:  	See: enabled
iLimit:  	See: index-entry-limit
LG-Cache:  	See: db-log-filecache-size
Type:  		See: java-class aka Backend Type [JE|PDB|local]
Encryption: 	See: confidentiality-enabled
Cmprs: 		See: ds-cfg-entries-compressed
" | log
}

getEntry()
{
	entry=$1
	ldifFile=$2
	parameter=$3
	variable=$4
	sed -n "/${entry}/,/^ *$/p" ${ldifFile}
	baseDn=`sed -n "/${domain}/,/^ *$/p" ${configfile} | grep "ds-cfg-base-dn:" | sed "s/ds-cfg-base-dn: //"`
}

getBackendEntries()
{
	entries=''
	entriesaddin=''
	thisbackend="${backend}"
	thisbase="${thisbase}"

	# Use cn=monitor if available
	if [ "${monitorfile}" != "" ]; then
		if [ "${shortbaseversion}" != "6" -a "${baseversion}" != "7" ]; then
			entries=`sed -n "/dn: cn=${thisbackend} Backend,cn=monitor/,/^ *$/p" ${monitorfile} | grep "ds-base-dn-entry-count:.*${thisbase}$" | awk '{print $2}'`
		else
			thisEscapedBase=`echo ${thisbase} | sed 's/,/.*/g'`
			entries=`sed -n "/dn: ds-mon-base-dn=${thisEscapedBase},ds-cfg-backend-id=${thisbackend},cn=backends,cn=monitor/,/^ *$/p" ${monitorfile} | grep "ds-mon-base-dn-entry-count: " | awk '{print $2}'`
		fi

		# Capture the extact number of jdb files from the new extract versions log.
		if [ -s ../supportextract.log ]; then
			jdbFiles=`grep " ${backend}: total jdb files" ../supportextract.log | awk -F" " '{print $NF}'`
		fi

		# monitor.ldif is from an RS or the backend is shutdown
		if [ "${jdbFiles}" != "" ]; then
			if [ "${shortbaseversion}" -ge "6" -a "${jdbFiles}" -gt "200" ]; then
				alerts="${alerts} Backends:${backend}~has~more~than~200~jdb~files~(${jdbFiles}).~db-log-filecache-size~is~set~to~low.KBI103"
				addKB "KBI103"
				backendAlert="The ${backend} backend has more than 200 jdb files (${jdbFiles}). db-log-filecache-size is set to low"
			fi
			if [ "${jdbFiles}" -gt "100" -a "${shortbaseversion}" -le "5" ]; then
				alerts="${alerts} Backends:${backend}~has~more~than~100~jdb~files~(${jdbFiles}).~db-log-filecache-size~is~set~to~low.KBI103"
				addKB "KBI103"
				backendAlert="The ${backend} backend has more than 100 jdb files (${jdbFiles}). db-log-filecache-size is set to low"
			fi
		elif [ "${entries}" != "" ]; then
			if [ "${entries}" -gt "9500000" -a "${logcache}" = "100" -a "${shortbaseversion}" -le "5" ]; then
				entriesaddin="*"
				alerts="${alerts} Backends:${backend}~has~more~than~9.5~million~entries.~db-log-filecache-size~is~set~to~low.KBI103"
				addKB "KBI103"
				backendAlert="The ${backend} backend has more than 9.5 million entries. db-log-filecache-size is set to low"
				logcache="${logcache} *"
			elif [ "${entries}" -gt "100000000" -a "${logcache}" = "200" -a "${shortbaseversion}" -ge "6" ]; then
				entriesaddin="*"
				alerts="${alerts} Backends:${backend}~has~more~than~100~million~entries.~db-log-filecache-size~is~set~to~low.KBI103"
				addKB "KBI103"
				backendAlert="The ${backend} backend has more than 100 million entries. db-log-filecache-size is set to low"
				logcache="${logcache} *"
			elif [ "${entries}" = "0" ]; then
				entriesaddin="*"
			elif [ "${entries}" -lt "0" ]; then
				entriesaddin="*"
				alerts="${alerts} Backends:${backend}~entry~count~is~negative.~The~backend~may~have~encountered~an~exception.KBI104"
				addKB "KBI104"
				backendAlert="The ${backend} entry count is negative. The backend may have encountered an exception"
				backendException=`sed -n "/dn: cn=${thisbackend} JE Database,cn=monitor/,/^ *$/p" ${monitorfile} | grep "JEInfo: "` 
				healthScore "Backends" "RED"
			else
				entries="${entries}"
			fi
		fi
	fi

	# Use server.out if we fall through from the above
	if [ "${entries}" = "" ]; then
		if [ -s ../logs/server.out ]; then
		entries=`grep "msg=The database backend ${thisbackend} containing" ../logs/server.out | tail -1 | awk '{print $11}'`
		if [ "${entries}" != "" ]; then
			if [ "${entries}" -gt "9500000" -a "${logcache}" = "100" ]; then
				entriesaddin="*"
				alerts="${alerts} Backends:${backend}~has~more~than~9.5~million~entries.~db-log-filecache-size~is~set~to~low.KBI103"
				addKB "KBI103"
				logcache="${logcache} *"
			fi
		fi
		fi
	fi 

	# Use NA (Not Available) if we fall all this way
	if [ "${entries}" = "" ]; then
		entries="NA"
 	fi
}

checkCRLF()
{
	# remove any CRLF linefeeds
	linefeedtest=`file ${configfile} | grep CRLF`
	if [ $? = 0 ]; then
		perl -pi -e 's/\r\n|\n|\r/\n/g' ${configfile}
	fi

	# remove any  control characters
	controlHtest=`grep '' ${configfile}`
	if [ $? = 0 ]; then
		fatalalerts="${fatalalerts} Config:Control-H~(^H)~characters~found~in~the~config.ldif~file.~Can~cause~issues."
		tr -d '' < ${configfile} > ${configfile}.ascii
		mv ${configfile}.ascii ${configfile}
	fi
	if [ -s ../supportextract.log ]; then
		# Convert Windows CRLF files to pure ASCII
		tr -d '\r' < ../supportextract.log > ../supportextract.log.ascii
		mv ../supportextract.log.ascii ../supportextract.log
	fi
	keystoreFileTest=`ls -1 ./security/ | grep -i store | head -1`
	if [ -s security/${keystoreFileTest} ]; then
		keystoreFiles=`ls security/*`
		for keystoreFile in ${keystoreFiles}; do
			tr -d '\r' < ${keystoreFile} > ${keystoreFile}.ascii
			mv ${keystoreFile}.ascii ${keystoreFile}
		done
	fi
	if [ -s ../monitor/monitor.ldif ]; then
		perl -p0e 's/\n //g' ${monitorfile} > ${monitorfile}.unwrapped
		mv ${monitorfile}.unwrapped ${monitorfile}
	fi
	if [ -s ./java.properties ]; then
		tr -d '\r' < ./java.properties > ./java.properties.ascii
		mv ./java.properties.ascii ./java.properties
	fi
}


checkCRLF

backends=`grep ds-cfg-backend-id: $configfile | awk '{print $2}' | grep -vE 'rootUser|replicationChanges|adminRoot|ads-truststore|backup|config|monitor|schema|tasks'`

calcLen()
{
        mylen=`expr "$1" : '.*'`
	mylen=${#1}
	if [ "$mylen" -gt "$tab" ]; then
		tab=${mylen}
	fi
}

calcLen2()
{
	# Get the length of the basedn
	# Loop incase there is more than
	# one base in this backend

	for base in $1; do
        # mylen=`expr "$base" : '.*'`
	# below is more efficient than the above string len finder
	mylen=${#base}
	if [ "$mylen" -gt "$btab" ]; then
		btab=${mylen}
	fi
	done
}

getDashes()
{
	dashes=''
	myi=0
	dashlen=$1
	while [ "$myi" -lt "$dashlen" ]; do
		dashes="${dashes}-"
		myi=`expr ${myi} + 1`
	done
}

getCurrConnections()
{
	debug "In getCurrConnections()"
	if [ "${monitorfile}" ]; then
		vertest=`echo ${baseversion} | grep -E '^6.*|^7.*'`
		if [ $? = 0 ]; then
			debug "vertest = $vertest and baseversion = $baseversion"
			adminportconns=`sed -n "/dn: cn=Administration Connector,cn=monitor/,/^ *$/p" ${monitorfile} | grep ds-mon-active-connections-count: | awk '{print $2}' | head -1`
			debug "adminportconns1='${adminportconns}'"
			ldapportconns=`sed -n "/dn: cn=LDAP,cn=connection handlers,cn=monitor/,/^ *$/p" ${monitorfile} | grep ds-mon-active-connections-count: | awk '{print $2}' | head -1`
			ldapsportconns=`sed -n "/dn: cn=LDAPS,cn=connection handlers,cn=monitor/,/^ *$/p" ${monitorfile} | grep ds-mon-active-connections-count: | awk '{print $2}' | head -1`
			ldappsearches=`sed -n "/dn: cn=LDAP,cn=connection handlers,cn=monitor/,/^ *$/p" ${monitorfile} | grep ds-mon-active-persistent-searches: | awk '{print $2}' | head -1`

			# psearches
			ldappsearches=`sed -n "/dn: cn=LDAP,cn=connection handlers,cn=monitor/,/^ *$/p" ${monitorfile} | grep ds-mon-active-persistent-searches: | awk '{print $2}' | head -1`
			ldapspsearches=`sed -n "/dn: cn=LDAPS,cn=connection handlers,cn=monitor/,/^ *$/p" ${monitorfile} | grep ds-mon-active-persistent-searches: | awk '{print $2}' | head -1`

                # JDK 11 check
		ttlsv13mon=`sed -n "/dn: cn=jvm,cn=monitor/,/^ *$/p" ${monitorfile} | grep "ds-mon-jvm-supported-tls-protocols: TLSv1.3" | awk '{print $2}'`

			httpportconns=`sed -n "/cn=HTTP,cn=connection handlers,cn=monitor/,/^ *$/p" ${monitorfile} | grep ds-mon-active-connections-count: | awk '{print $2}' | head -1`
			httpsportconns=`sed -n "/cn=HTTPS,cn=connection handlers,cn=monitor/,/^ *$/p" ${monitorfile} | grep ds-mon-active-connections-count: | awk '{print $2}' | head -1`

			# Fallback to the old way if this is an upgraded instance
			if [ "${ldapportconns}" = "" -o "${ldapsportconns}" = "" ]; then
				ldapportconns=`sed -n "/dn: cn=LDAP Connection Handler,cn=[Cc]onnection [Hh]andlers,cn=monitor/,/^ *$/p" ${monitorfile} | grep ds-mon-active-connections-count: | awk '{print $2}' | head -1`
				ldapsportconns=`sed -n "/dn: cn=LDAPS Connection Handler,cn=[Cc]onnection [Hh]andlers,cn=monitor/,/^ *$/p" ${monitorfile} | grep ds-mon-active-connections-count: | awk '{print $2}' | head -1`
				ldappsearches=`sed -n "/dn: cn=LDAP Connection Handler,cn=[Cc]onnection [Hh]andlers,cn=monitor/,/^ *$/p" ${monitorfile} | grep ds-mon-active-persistent-searches: | awk '{print $2}' | head -1`
				ldapspsearches=`sed -n "/dn: cn=LDAPS Connection Handler,cn=[Cc]onnection [Hh]andlers,cn=monitor/,/^ *$/p" ${monitorfile} | grep ds-mon-active-persistent-searches: | awk '{print $2}' | head -1`
				httpportconns=`sed -n "/cn=HTTP Connection Handler,cn=[Cc]onnection [Hh]andlers,cn=monitor/,/^ *$/p" ${monitorfile} | grep ds-mon-active-connections-count: | awk '{print $2}' | head -1`
				httpsportconns=`sed -n "/cn=HTTPS Connection Handler,cn=[Cc]onnection [Hh]andlers,cn=monitor/,/^ *$/p" ${monitorfile} | grep ds-mon-active-connections-count: | awk '{print $2}' | head -1`
			fi
		else
			adminportconns=`sed -n "/dn: cn=Administration Connector 0.0.0.0 port ${adminport},cn=monitor/,/^ *$/p" ${monitorfile} | grep ds-connectionhandler-num-connections: | awk '{print $2}' | head -1`
			debug "adminportconns2='${adminportconns}'"
			ldapportconns=`sed -n "/dn: cn=LDAP Connection Handler 0.0.0.0 port ${ldapport},cn=monitor/,/^ *$/p" ${monitorfile} | grep ds-connectionhandler-num-connections: | awk '{print $2}' | head -1`
			ldapsportconns=`sed -n "/dn: cn=LDAPS Connection Handler 0.0.0.0 port ${ldapsport},cn=monitor/,/^ *$/p" ${monitorfile} | grep ds-connectionhandler-num-connections: | awk '{print $2}' | head -1`
			httpportconns=`sed -n "/dn: cn=HTTP Connection Handler 0.0.0.0 port ${httpport},cn=monitor/,/^ *$/p" ${monitorfile} | grep ds-connectionhandler-num-connections: | awk '{print $2}' | head -1`
			httpsportconns=`sed -n "/dn: cn=HTTPS Connection Handler 0.0.0.0 port ${httpsport},cn=monitor/,/^ *$/p" ${monitorfile} | grep ds-connectionhandler-num-connections: | awk '{print $2}' | head -1`
			jmxportconns=`sed -n "/dn: cn=JMX Connection Handler ${jmxport},cn=monitor/,/^ *$/p" ${monitorfile} | grep ds-connectionhandler-num-connections: | awk '{print $2}' | head -1`
			ldappsearches='NA'
			ldapspsearches='NA'
		fi
	else
			adminportconns='NA'
			ldapportconns='NA'
			ldapsportconns='NA'
			ldappsearches='NA'
			ldapspsearches='NA'
			httpportconns='NA'
			httpsportconns='NA'
	fi

	allconnectioncounts="${adminportconns} ${ldapportconns} ${ldapsportconns} ${httpportconns} ${httpsportconns} ${jmxportconns}"
	for connectioncount in ${allconnectioncounts}; do
		if [ ${connectioncount} != "" -a "${connectioncount}" != "NA" ]; then
			totalconnectioncount=`expr ${totalconnectioncount} + ${connectioncount}`
		fi
	done
}

getAdminPort()
{
	localBackCheck=`grep "objectClass: ds-cfg-local-backend" ${configfile} | uniq`
	baseversion=`grep "ds-cfg-version: " ${configfile} | awk '{print $2}' | cut -c1-5 | sed "s/-SNAPSHOT//"`
	if [ "${baseversion}" != "" ]; then
		shortbaseversion=`echo ${baseversion} | cut -c1`
	elif [ -s ./buildinfo ]; then
		baseversion=`cut -c1-5 ./buildinfo | sed "s/-SNAPSHOT//"`
		shortbaseversion=`cut -c1 ./buildinfo`
	elif [ -s ./config.version ]; then
		baseversion=`cut -c1-5 ./config.version | sed "s/-SNAPSHOT//"`
		shortbaseversion=`cut -c1 ./config.version`
	elif [ "${localBackCheck}" != "" ]; then
		shortbaseversion='4'
	elif [ "${majorVersion}" != "" ]; then
		shortbaseversion=${majorVersion}
	else
		shortbaseversion=3
	fi

	# check for 6x+ instances
	if [ "${monitorfile}" != "" -a "${baseversion}" = "" ]; then
		baseversion=`grep -E "ds-mon-full-version: |fullVersion: " ${monitorfile} | awk -F" " '{print $NF}' | sed "s/-SNAPSHOT//"`
		shortbaseversion=`echo ${baseversion} | cut -c1`
	fi

	# remove the "." dots from the version for a numerical version number check
	if [ "${baseversion}" != "" ]; then
		compactversion=`echo ${baseversion} | sed "s/\.//g"`
	else
		compactversion="0"
	fi

	vertest=`echo ${baseversion} | grep -E '^6.*|^7.*'`
	if [ $? = 0 ]; then
		debug "vertest = $vertest and baseversion = $baseversion"
# FIXME 2019
        	adminport=`sed -n '/dn: cn=Administration Connector,cn=config/,/^ *$/p' ${configfile} | grep ds-cfg-listen-port: | awk '{print $2}'`
		ldapport=`sed -n '/dn: cn=LDAP,cn=[Cc]onnection [Hh]andlers,cn=config/,/^ *$/p' ${configfile} | grep ds-cfg-listen-port: | awk '{print $2}'`
		ldapporttls=`sed -n '/cn=LDAP,cn=[Cc]onnection [Hh]andlers,cn=config/,/^ *$/p' ${configfile} | grep ds-cfg-allow-start-tls: | awk '{print $2}'`
		ldapsport=`sed -n '/cn=LDAPS,cn=[Cc]onnection [Hh]andlers,cn=config/,/^ *$/p' ${configfile} | grep ds-cfg-listen-port: | awk '{print $2}'`
		ldapsporttls=`sed -n '/cn=LDAPS,cn=[Cc]onnection [Hh]andlers,cn=config/,/^ *$/p' ${configfile} | grep ds-cfg-allow-start-tls: | awk '{print $2}'`

		# JDK 11 check
		ldapporttlsv13=`sed -n '/cn=LDAP,cn=[Cc]onnection [Hh]andlers,cn=config/,/^ *$/p' ${configfile} | grep "ds-cfg-ssl-protocol: TLSv1.3" | awk '{print $2}'`
		ldapsporttlsv13=`sed -n '/cn=LDAPS,cn=[Cc]onnection [Hh]andlers,cn=config/,/^ *$/p' ${configfile} | grep "ds-cfg-ssl-protocol: TLSv1.3" | awk '{print $2}'`

		ldapportenabled=`sed -n '/dn: cn=LDAP,cn=[Cc]onnection [Hh]andlers,cn=config/,/^ *$/p' ${configfile} | grep ds-cfg-enabled: | awk '{print $2}'`
		ldapsportenabled=`sed -n '/cn=LDAPS,cn=[Cc]onnection [Hh]andlers,cn=config/,/^ *$/p' ${configfile} | grep ds-cfg-enabled: | awk '{print $2}'`

		httpport=`sed -n '/dn: cn=HTTP,cn=connection handlers,cn=config/,/^ *$/p' ${configfile} | grep ds-cfg-listen-port: | awk '{print $2}'`
		httpsport=`sed -n '/dn: cn=HTTPS,cn=connection handlers,cn=config/,/^ *$/p' ${configfile} | grep ds-cfg-listen-port: | awk '{print $2}'`

		httpportenabled=`sed -n '/dn: cn=HTTP,cn=connection handlers,cn=config/,/^ *$/p' ${configfile} | grep ds-cfg-enabled: | awk '{print $2}'`
		httpsportenabled=`sed -n '/dn: cn=HTTPS,cn=connection handlers,cn=config/,/^ *$/p' ${configfile} | grep ds-cfg-enabled: | awk '{print $2}'`

		jmxdn=`tail -r ${configfile} | sed -n "/ds-cfg-java-class: org.opends.server.protocols.jmx.JmxConnectionHandler/,/dn: /p" | tail -1`
		if [ "${jmxdn}" != "" ]; then
			jmxport=`sed -n "/${jmxdn}/,/^ *$/p" ${configfile} | grep ds-cfg-listen-port: | awk '{print $2}'`
			jmxportenabled=`sed -n "/${jmxdn}/,/^ *$/p" ${configfile} | grep ds-cfg-enabled: | awk '{print $2}'`
		fi
	else
        	adminport=`sed -n '/dn: cn=Administration Connector,cn=config/,/^ *$/p' ${configfile} | grep ds-cfg-listen-port: | awk '{print $2}'`
		ldapport=`sed -n '/dn: cn=LDAP Connection Handler,cn=[Cc]onnection [Hh]andlers,cn=config/,/^ *$/p' ${configfile} | grep ds-cfg-listen-port: | awk '{print $2}'`
		ldapporttls=`sed -n '/dn: cn=LDAP Connection Handler,cn=[Cc]onnection [Hh]andlers,cn=config/,/^ *$/p' ${configfile} | grep ds-cfg-allow-start-tls: | awk '{print $2}'`
		ldapsport=`sed -n '/dn: cn=LDAPS Connection Handler,cn=[Cc]onnection [Hh]andlers,cn=config/,/^ *$/p' ${configfile} | grep ds-cfg-listen-port: | awk '{print $2}'`
		ldapsporttls=`sed -n '/dn: cn=LDAPS Connection Handler,cn=[Cc]onnection [Hh]andlers,cn=config/,/^ *$/p' ${configfile} | grep ds-cfg-allow-start-tls: | awk '{print $2}'`

		ldapportenabled=`sed -n '/dn: cn=LDAP Connection Handler,cn=[Cc]onnection [Hh]andlers,cn=config/,/^ *$/p' ${configfile} | grep ds-cfg-enabled: | awk '{print $2}'`
		ldapsportenabled=`sed -n '/dn: cn=LDAPS Connection Handler,cn=[Cc]onnection [Hh]andlers,cn=config/,/^ *$/p' ${configfile} | grep ds-cfg-enabled: | awk '{print $2}'`

		# JDK 11 check
		ldapporttlsv13=`sed -n '/dn: cn=LDAP Connection Handler,cn=[Cc]onnection [Hh]andlers,cn=config/,/^ *$/p' ${configfile} | grep "ds-cfg-ssl-protocol: TLSv1.3" | awk '{print $2}'`
		ldapsporttlsv13=`sed -n '/dn: cn=LDAPS Connection Handler,cn=[Cc]onnection [Hh]andlers,cn=config/,/^ *$/p' ${configfile} | grep "ds-cfg-ssl-protocol: TLSv1.3" | awk '{print $2}'`

		httpport=`sed -n '/dn: cn=HTTP Connection Handler,cn=connection handlers,cn=config/,/^ *$/p' ${configfile} | grep ds-cfg-listen-port: | awk '{print $2}'`
		httpsport=`sed -n '/dn: cn=HTTPS Connection Handler,cn=connection handlers,cn=config/,/^ *$/p' ${configfile} | grep ds-cfg-listen-port: | awk '{print $2}'`

		httpportenabled=`sed -n '/dn: cn=HTTP Connection Handler,cn=connection handlers,cn=config/,/^ *$/p' ${configfile} | grep ds-cfg-enabled: | awk '{print $2}'`
		httpsportenabled=`sed -n '/dn: cn=HTTPS Connection Handler,cn=connection handlers,cn=config/,/^ *$/p' ${configfile} | grep ds-cfg-enabled: | awk '{print $2}'`

		jmxport=`sed -n '/dn: cn=JMX Connection Handler,cn=[Cc]onnection [Hh]andlers,cn=config/,/^ *$/p' ${configfile} | grep ds-cfg-listen-port: | awk '{print $2}'`
		jmxportenabled=`sed -n '/dn: cn=JMX Connection Handler,cn=[Cc]onnection [Hh]andlers,cn=config/,/^ *$/p' ${configfile} | grep ds-cfg-enabled: | awk '{print $2}'`
	fi
	# Fallback to using the old style connection handlers if this was an upgrade from X to 6.x

	   if [ "${ldapport}" = "" -o "${ldapportenabled}" = "" ]; then
        	adminport=`sed -n '/dn: cn=Administration Connector,cn=config/,/^ *$/p' ${configfile} | grep ds-cfg-listen-port: | awk '{print $2}'`
		ldapport=`sed -n '/dn: cn=LDAP Connection Handler,cn=[Cc]onnection [Hh]andlers,cn=config/,/^ *$/p' ${configfile} | grep ds-cfg-listen-port: | awk '{print $2}'`
		ldapporttls=`sed -n '/dn: cn=LDAP Connection Handler,cn=[Cc]onnection [Hh]andlers,cn=config/,/^ *$/p' ${configfile} | grep ds-cfg-allow-start-tls: | awk '{print $2}'`
		ldapportenabled=`sed -n '/dn: cn=LDAP Connection Handler,cn=[Cc]onnection [Hh]andlers,cn=config/,/^ *$/p' ${configfile} | grep ds-cfg-enabled: | awk '{print $2}'`

		# JDK 11 check
		ldapporttlsv13=`sed -n '/dn: cn=LDAP Connection Handler,cn=[Cc]onnection [Hh]andlers,cn=config/,/^ *$/p' ${configfile} | grep "ds-cfg-ssl-protocol: TLSv1.3" | awk '{print $2}'`
		ldapsporttlsv13=`sed -n '/dn: cn=LDAPS Connection Handler,cn=[Cc]onnection [Hh]andlers,cn=config/,/^ *$/p' ${configfile} | grep "ds-cfg-ssl-protocol: TLSv1.3" | awk '{print $2}'`

		httpport=`sed -n '/dn: cn=HTTP Connection Handler,cn=connection handlers,cn=config/,/^ *$/p' ${configfile} | grep ds-cfg-listen-port: | awk '{print $2}'`
		httpportenabled=`sed -n '/dn: cn=HTTP Connection Handler,cn=connection handlers,cn=config/,/^ *$/p' ${configfile} | grep ds-cfg-enabled: | awk '{print $2}'`

		jmxport=`sed -n '/dn: cn=JMX Connection Handler,cn=[Cc]onnection [Hh]andlers,cn=config/,/^ *$/p' ${configfile} | grep ds-cfg-listen-port: | awk '{print $2}'`
		jmxportenabled=`sed -n '/dn: cn=JMX Connection Handler,cn=[Cc]onnection [Hh]andlers,cn=config/,/^ *$/p' ${configfile} | grep ds-cfg-enabled: | awk '{print $2}'`
	   fi

	   if [ "${ldapsport}" = "" -o "${ldapsportenabled}" = "" ]; then
		adminport=`sed -n '/dn: cn=Administration Connector,cn=config/,/^ *$/p' ${configfile} | grep ds-cfg-listen-port: | awk '{print $2}'`
		ldapsport=`sed -n '/dn: cn=LDAPS Connection Handler,cn=[Cc]onnection [Hh]andlers,cn=config/,/^ *$/p' ${configfile} | grep ds-cfg-listen-port: | awk '{print $2}'`
		ldapsporttls=`sed -n '/dn: cn=LDAPS Connection Handler,cn=[Cc]onnection [Hh]andlers,cn=config/,/^ *$/p' ${configfile} | grep ds-cfg-allow-start-tls: | awk '{print $2}'`

		ldapsportenabled=`sed -n '/dn: cn=LDAPS Connection Handler,cn=[Cc]onnection [Hh]andlers,cn=config/,/^ *$/p' ${configfile} | grep ds-cfg-enabled: | awk '{print $2}'`

		httpsport=`sed -n '/dn: cn=HTTPS Connection Handler,cn=connection handlers,cn=config/,/^ *$/p' ${configfile} | grep ds-cfg-listen-port: | awk '{print $2}'`

		httpsportenabled=`sed -n '/dn: cn=HTTPS Connection Handler,cn=connection handlers,cn=config/,/^ *$/p' ${configfile} | grep ds-cfg-enabled: | awk '{print $2}'`

		jmxport=`sed -n '/dn: cn=JMX Connection Handler,cn=[Cc]onnection [Hh]andlers,cn=config/,/^ *$/p' ${configfile} | grep ds-cfg-listen-port: | awk '{print $2}'`
		jmxportenabled=`sed -n '/dn: cn=JMX Connection Handler,cn=[Cc]onnection [Hh]andlers,cn=config/,/^ *$/p' ${configfile} | grep ds-cfg-enabled: | awk '{print $2}'`
	   fi

		getCurrConnections

	if [ "${ldapportenabled}" = "true" -o "${ldapportenabled}" = "TRUE" ]; then
		ldapportenabled="enabled"
	else
		ldapport="-"
		ldapportenabled="disabled"
		ldapportconns='NA'
	fi
	if [ "${ldapsportenabled}" = "true" -o "${ldapsportenabled}" = "TRUE" ]; then
		ldapsportenabled="enabled"
	else
		ldapsport="-"
		ldapsportenabled="disabled"
		ldapsportconns='NA'
	fi
	# HTTP Connector
	if [ "${httpportenabled}" = "true" -o "${httpportenabled}" = "TRUE" ]; then
		httpportenabled="enabled"
	else
		httpport="-"
		httpportenabled="disabled"
		httpportconns='NA'
	fi
	# HTTPS Connector
	if [ "${httpsportenabled}" = "true" -o "${httpsportenabled}" = "TRUE" ]; then
		httpsportenabled="enabled"
	else
		httpsport="-"
		httpsportenabled="disabled"
		httpsportconns='NA'
	fi
	# JMX Connector
	if [ "${jmxportenabled}" = "true" -o "${jmxportenabled}" = "TRUE" ]; then
		jmxportenabled="enabled"
	else
		jmxport="----"
		jmxportenabled="disabled"
		jmxportconns='NA'
	fi
	hostname=`grep ds-cfg-server-fqdn: ${configfile} | awk '{print $2}'`
	rootdn=`grep ds-cfg-alternate-bind-dn: ${configfile} | sed "s/ds-cfg-alternate-bind-dn: //"`

	# Check if we're using DS6 +
	if [ "${ldapport}" = "" ]; then
		ldapport=`sed -n '/dn: cn=LDAP,cn=connection handlers,cn=config/,/^ *$/p' ${configfile} | grep ds-cfg-listen-port: | awk '{print $2}'`
	fi

	if [ "${ldapport}" != "" -a "${debug}" = "1" ]; then
		debug "Version: $baseversion"
		debug "LDAP: $ldapport" "$ldapporttls"
		debug "LDAPS: $ldapsport"
		debug "Admin: $adminport"
		debug "Host: $hostname"
		debug "Root: $rootdn"
	fi
}       

printServerInfo()
{

# print the FQDN
fqdn=`grep ds-cfg-server-fqdn $configfile | awk '{print $2}'`
printf "\n%s\n" "---------------------------------------" | log
printf "%s\n" "SERVER INFORMATION:" | log
printf "\n%s\n" "${serverinfo}" | log
printf "%s\n\n" "---------------------------------------" | log
printf "\t%-25s\t%s\n" "Install FQDN (Hostname):" "$fqdn" | log
  	if [ -s ../node/networkInfo ]; then
		localhost=`grep 'Local Host:' ../node/networkInfo | awk '{print $3}'`
		runtimeaddress=`grep IP: ../node/networkInfo | grep ${localhost} | sed "s/IP: //"`
		printf "\t%-25s\t%s\n" "Runtime IP (Hostname):" "$runtimeaddress" | log
	fi

		getAdminPort
		printf "\n\t%-25s\t%-5s\t%-11s\n" "Admin Port (enabled)" "${adminport}" "conns:${adminportconns}" | log
		printf "\t%-25s\t%-5s\t%-11s\t%-12s\t%s\n" "LDAP Port  (${ldapportenabled})" "${ldapport}" "conns:${ldapportconns}" "psearch:${ldappsearches}" "starttls:${ldapporttls}" | log
		printf "\t%-25s\t%-5s\t%-11s\t%-12s\t%s\n" "LDAPS Port (${ldapsportenabled})" "${ldapsport}" "conns:${ldapsportconns}" "psearch:${ldapspsearches}" "starttls:${ldapsporttls}" | log
		if [ "${httpport}" != "" -a "${httpportenabled}" != "" ]; then
			printf "\t%-25s\t%-5s\t%-11s\t\t\t%s\n" "HTTP Port (${httpportenabled})" "${httpport}" "conns:${httpportconns}" "starttls:${ldapsporttls}" | log
		fi
		if [ "${httpsport}" != "" -a "${httpsportenabled}" != "" ]; then
			printf "\t%-25s\t%-5s\t%-11s\t\t\t%s\n" "HTTPS Port (${httpsportenabled})" "${httpsport}" "conns:${httpsportconns}" "starttls:${ldapsporttls}" | log
		fi
		if [ "${jmxportenabled}" != "" ]; then
			printf "\t%-25s\t%-5s\t%s\t%s\n" "JMX Port (${jmxportenabled})" "${jmxport}" "conns:${jmxportconns}" "" | log
		fi

		calcLen "total:${totalconnectioncount}"
		getDashes "${mylen}"
		printf "\t%-25s\t%-5s\t%-11s\t%-12s\t%s\n" "" "" "${dashes}" "" "" | log
		printf "\t%-25s\t%-5s\t%-11s\t%-12s\t%s\n\n" "" "" "total:${totalconnectioncount}" "" "" | log

		if [ "${httpport}" = "" -a "${httpportenabled}" = "" -a "${httpsport}" = "" -a "${httpsportenabled}" = "" ]; then
			printf "\n"
		fi

	if [ "${shortbaseversion}" -le "${minimumEoslVersion}" ]; then
		eoslAlertDisplay="${red}Version is EOSL${nocolor} *"
		alerts="${alerts} Version:This~OpenDJ~version~past~the~EOSL~date,KBI000"
		addKB "KBI000"
	fi
	format "Base version:" "${baseversion} ${eoslAlertDisplay}" "Build info not available"

if [ "${monitorfile}" != "" ]; then
	format "Full version:" "`grep -iE "fullVersion|ds-mon-full-version" ${monitorfile} | sed "s/fullVersion: //" | sed "s/ds-mon-full-version: //"`"
	format "Installation Directory:" "`grep -iE "installPath|ds-mon-install-path" ${monitorfile} | awk -F" " '{print $NF}'`"
	format "Instance Directory:" "`grep -iE "instancePath|ds-mon-instance-path" ${monitorfile} | awk -F" " '{print $NF}'`"

	format "" "" ""
	format "Start time:" "`grep -iE "startTime: |ds-mon-start-time: " ${monitorfile} | awk -F" " '{print $NF}'`" "NA"
	format "Current time:" "`grep -iE "currentTime: |ds-mon-current-time: " ${monitorfile} | awk -F" " '{print $NF}'`" "NA"
elif [ -s ../logs/server.out ]; then
	fullversion=`grep "starting up" ../logs/server.out | sed "s/.*msg=//" | sed "s/ starting up//"`
	if [ "${fullversion}" = "" ]; then
		fullversion="NA"
	fi
	installDir=`grep "msg=Installation Directory" ../logs/server.out | awk -F" " '{print $NF}'`
	if [ "${installDir}" = "" ]; then
		installDir="NA"
	fi
	instanceDir=`grep "msg=Instance Directory" ../logs/server.out | awk -F" " '{print $NF}'`
	if [ "${instanceDir}" = "" ]; then
		instanceDir="NA"
	fi

	printf "\t%-25s\t%s\n" "Full version:" "${fullversion}" | log
	printf "\t%-25s\t%s\n" "Installation Directory:" "${installDir}" | log
	printf "\t%-25s\t%s\n" "Instance Directory:" "${instanceDir}" | log
else
	printf "\t%-25s\t%s\n" "Full version:" "NA" | log
	printf "\t%-25s\t%s\n" "Installation Directory:" "NA" | log
	printf "\t%-25s\t%s\n" "Instance Directory:" "NA" | log
fi

	# basic cn=config info
	format "Size Limit:" "`grep -iE "ds-cfg-size-limit:" ${configfile} | awk -F" " '{print $NF}'`" "NA" "1000"
	format "Time Limit:" "`grep -iE "ds-cfg-time-limit:" ${configfile} | sed "s/ds-cfg-time-limit: //"`" "NA" "60 seconds"
	format "Look Through Limit:" "`grep -iE "ds-cfg-lookthrough-limit:" ${configfile} | awk -F" " '{print $NF}'`" "NA" "5000"
	format "Writability Mode:" "`sed -n "/cn=config/,/^ *$/p" ${configfile} | grep -iE "ds-cfg-writability-mode: " | head -1 | awk -F" " '{print $NF}'`" "NA" "enabled"
	format "Cursor Limit:" "`grep -iE "ds-cfg-cursor-entry-limit:" ${configfile} | awk -F" " '{print $NF}'`" "NA" "100000"
	format "Idle Time Limit:" "`grep -iE "ds-cfg-idle-time-limit:" ${configfile} | sed "s/ds-cfg-idle-time-limit: //"`" "NA" "0 seconds"
	format "Etime Resolution:" "`grep -iE "ds-cfg-etime-resolution:" ${configfile} | awk -F" " '{print $NF}'`" "NA" "milliseconds"
	format "Max Client Connections:" "`grep -iE "ds-cfg-max-allowed-client-connections:" ${configfile} | awk -F" " '{print $NF}'`" "NA" "0"
	format "Max Persistent Searches:" "`grep -iE "ds-cfg-max-psearches:" ${configfile} | awk -F" " '{print $NF}'`" "NA" "-1"
	format "Backend Shared Cache:" "`grep -iE "ds-cfg-je-backend-shared-cache-enabled:" ${configfile} | awk -F" " '{print $NF}'`" "true" ""
	format "Trust Txn IDs:" "`grep -iE "ds-cfg-trust-transaction-ids:" ${configfile} | awk -F" " '{print $NF}'`" "NA" ""
	if [ "${compactversion}" -ge "650" ]; then
	  format "Server ID:" "`grep -iE "ds-cfg-server-id:" ${configfile} | head -1 | awk -F" " '{print $NF}'`" "NA" ""
	fi
	format "Work Queue:" "`sed -n "/dn: cn=Work Queue,cn=config/,/^ *$/p" ${configfile} | grep -iE "ds-cfg-max-work-queue-capacity: " | awk -F" " '{print $NF}'`" "NA" "1000"
	format "" "" ""

	if [ "${ServerInfo}" != "RED" -o "${ServerInfo}" != "YELLOW" ]; then
		healthScore "ServerInfo" "GREEN"
	fi
}

printIndexes()
{

printf "%s\n" "---------------------------------------" | log
printf "%s\n" "INDEX INFORMATION:" | log
printf "\n%s\n" "${indexinfo}" | log
printf "%s\n\n" "---------------------------------------" | log
if [ "${backends}" = "" ]; then
	printf "\t%s\n\t%s" "No Backends available...system could be a Replication Server" "See below." | log
	ctsIndexCount=0
	amCfgIndexCount=0
	return
fi
printf "%s\t%s\n" "Note:" "Excessive index-entry-limit's flagged at 50,000+" | log

	# Get the len for all index names
	indexNames=`grep 'ds-cfg-attribute: ' ${configfile} | awk '{print $2}'`
	indexNames="${indexNames} ${backends}"

	longestIndexName=0
	for indexName in ${indexNames}; do
		thisLen=${#indexName}
		if [ "${thisLen}" -gt "${longestIndexName}" ]; then
			longestIndexName=${thisLen}
		fi
	done

	# Get the initial size for the index-type to display dashes
for backend in $backends; do
	indexes=`sed -n "/cn=Index,ds-cfg-backend-id=${backend},cn=Backends,cn=config/,/^ *$/p" ${configfile} | grep "dn: " | awk '{print $2}'`
	for index in $indexes; do
		thisLen=`sed -n "/dn: ${index}/,/^ *$/p" ${configfile} | grep "ds-cfg-index-type" | awk '{print $2}' | perl -p -e 's/\r\n|\n|\r/\n/g' | wc | awk '{print $3}'`
		if [ "${thisLen}" -gt "${longestIndexType}" ]; then
			longestIndexType=${thisLen}
		fi
	done
done

	longestIndexName=`expr ${longestIndexName} + 2`; getDashes "${longestIndexName}"; idash1=${dashes}
	longestIndexType=`expr ${longestIndexType} + 1`; getDashes "${longestIndexType}"; idash2=${dashes}

for backend in $backends; do
	printf "\n%-${longestIndexName}s: %-${longestIndexType}s: %-20s: %-33s: %-24s: %-11s\n" "Backend: ${backend}" "index-type" "index-entry-limit" "index-extensible-matching-rule" "confidentiality-enabled" "Index type" | log
	printf "%-${longestIndexName}s:%-${longestIndexType}s:%-20s:%-33s:%-24s:%-11s\n" "${idash1}" "${idash2}-" "---------------------" "----------------------------------" "-------------------------" "----------" | log
	indexes=`sed -n "/cn=Index,ds-cfg-backend-id=${backend},cn=Backends,cn=config/,/^ *$/p" ${configfile} | grep "dn: " | grep -iv 'dn: cn=Index' | awk '{print $2}'`
	indexCount=1
	ctsIndexCount=0
	amCfgIndexCount=0
	customIndexCount=0
	ttlEnabledIndexCount=0
	systemIndexCount=0
	systemIndexesFound=""
	ocIndexFound=""
	xmlIndexFound=""

	for index in $indexes; do
		attrName=`sed -n "/dn: ${index}/,/^ *$/p" ${configfile} | grep -E "ds-cfg-attribute:" | awk '{print $2}'`
		indexType=`sed -n "/dn: ${index}/,/^ *$/p" ${configfile} | grep -E "ds-cfg-index-type" | awk '{print $2}' | perl -p -e 's/\r\n|\n|\r/\n/g'`
		indexType=`echo ${indexType} | perl -p -e 's/\r\n|\n|\r/\n/g'`
		entryLimit=`sed -n "/dn: ${index}/,/^ *$/p" ${configfile} | grep -E "ds-cfg-index-entry-limit" | awk '{print $2}'`
		matchingRule=`sed -n "/dn: ${index}/,/^ *$/p" ${configfile} | grep -E "ds-cfg-index-extensible-matching-rule" | awk '{print $2}'`
		confidentiality=`sed -n "/dn: ${index}/,/^ *$/p" ${configfile} | grep -E "ds-cfg-confidentiality-enabled" | awk '{print $2}'`
		ttlenabled=`sed -n "/dn: ${index}/,/^ *$/p" ${configfile} | grep -E "ds-cfg-ttl-enabled" | awk '{print $2}'`

		if [ "${entryLimit}" = "" -a "${attrName}" != "" ]; then
			entryLimit="4000"
		fi
		if [ "${entryLimit}" != "" -a "${entryLimit}" -gt "50000" ]; then
			entryLimitAlertDisplay="*"
				alertcheck=`echo ${alerts} | grep 'Excessive*Index*Limits'`
				if [ $? = 1 -a "${entryLimitAlert}" = "0" ]; then
					alerts="${alerts} Indexes:Excessive~Index~Limits.KBI200"
					addKB "KBI200"
					entryLimitAlert=1
				fi
		fi
		if [ "${matchingRule}" = "" ]; then
			matchingRule="-"
		fi
		if [ "${confidentiality}" = "" -a "${attrName}" != "" ]; then
			confidentiality="false"
		else
			prodModeCheck2="1"
		fi
		if [ "${attrName}" = "sunxmlkeyvalue" ]; then
			xmlIndexFound=1
		fi
		if [ "${attrName}" = "objectClass" -o "${attrName}" = "objectclass" ]; then
			ocIndexFound=1
		fi
		if [ "${attrName}" = "objectClass" ]; then
			for iType in ${indexType}; do
				if [ "${iType}" = "presence" -o "${iType}" = "substring" ]; then
					ocTypeAlertDisplay=" *"
					alerts="${alerts} Indexes:objectClass~Index~Bad-type~found~(${iType})~for~backend~${backend}"
					iTypes="${iTypes} ${iType}"
					badIndexTypeAlert=1
				else
					ocTypeAlertDisplay=""
				fi
			done
		else
			ocTypeAlertDisplay=""
		fi

		if [ "${ttlenabled}" != "" ]; then
			ttlEnabledAddin="ttl"
			ttlEnabledIndexCount=`expr ${ttlEnabledIndexCount} + 1`
			ttlEnabledIndexes="${attrName} ${ttlEnabledIndexes}"
		fi

	# Check for Default, System, CTS, and Custom indexes
	ctsIndexCheck=`echo ${index} | grep -iE "${ctsIndexes}"`
	amCfgIndexCheck=`echo ${index} | grep -iE "${amCfgIndexes}"`
	defaultIndexCheck=`echo ${index} | grep -iE "${defaultIndexes}"`
	systemIndexCheck=`echo ${index} | grep -iE "${systemIndexes}"`

	if [ "${defaultIndexCheck}" != "" ]; then
		indexAlertDisplay="default"
	elif [ "${systemIndexCheck}" != "" ]; then
		indexAlertDisplay="system"
		systemIndexCount=`expr ${systemIndexCount} + 1`
		if [ "${systemIndexesFound}" = "" ]; then
			systemIndexesFound="${attrName}"
		else
			systemIndexesFound="${systemIndexesFound} ${attrName}"
		fi
	elif [ "${ctsIndexCheck}" != "" ]; then
		ctsIndexCount=`expr ${ctsIndexCount} + 1`
		indexAlertDisplay="cts"
	elif [ "${amCfgIndexCheck}" != "" ]; then
		amCfgIndexCount=`expr ${amCfgIndexCount} + 1`
		indexAlertDisplay="amcfg"
	else
		indexAlertDisplay="custom"
		customIndexCount=`expr ${customIndexCount} + 1`
	fi

	printf "%-${longestIndexName}s: %-${longestIndexType}s: %-20s: %-33s: %-25s: %-11s\n" "${attrName}${ocTypeAlertDisplay}" "${indexType} ${ttlEnabledAddin}" "${entryLimit} ${entryLimitAlertDisplay}" "${matchingRule}" "${confidentiality}" "${indexAlertDisplay}" | log
	entryLimitAlertDisplay=''
	indexAlertDisplay=''
	ttlEnabledAddin=''
	indexCount=`expr ${indexCount} + 1`
	done

	if [ "${systemIndexCount}" -lt "3" ]; then
		systemIndexAlertDisplay=" *"
	fi

	# DS 6.5 profiles omit the coreTokenMultiString03 index now and removed the etag index (not needed)
	vertest=`echo ${baseversion} | grep -E '^6.5|^7.*'`
	if [ "${vertest}" != "" ]; then
		expectedCtsIndexes='23'
	else
		expectedCtsIndexes='24'
	fi

	ttlEnabledIndexes=`echo ${ttlEnabledIndexes} | sed "s/ //g"`

	if [ "${ttlEnabledIndexes}" = "" ]; then
		ttlEnabledIndexes="NA"
	fi

	printf "\n\t%-23s\t%s\n" "Total Indexes: " "${indexCount}" | log
	printf "\t%-23s\t%s\t%s\n" "Total AM Indexes: " "${amCfgIndexCount}" "(expected 3 -  for an AM configStore)" | log
	printf "\t%-23s\t%s\t%s\n" "Total CTS Indexes: " "${ctsIndexCount}" "(expected ${expectedCtsIndexes} - for an AM ctsStore)" | log
	printf "\t%-23s\t%s\n" "Total Custom Indexes: " "${customIndexCount}" | log
	printf "\t%-23s\t%s\t%s\n\n" "Total TTL Indexes: " "${ttlEnabledIndexCount}" "(${ttlEnabledIndexes})" | log
	printf "\t%-23s\t%s\t%s\n\n" "Total System Indexes: " "${systemIndexCount}" "(expected 3)${systemIndexAlertDisplay}" | log

	if [ "${ttlEnabledIndexes}" != "NA" ]; then
		alerts="${alerts} Indexes:TTL~Indexes~found~(${ttlEnabledIndexes})"
	fi

	# Check monitor for indexes that need to be rebuilt
	if [ "${monitorfile}" != "" ]; then
		needReindex=`grep -E 'need-reindex|ds-mon-backend-degraded-index:' ${monitorfile} | awk '{print $2}'`
	fi
	if [ "${monitorfile}" != "" -a "${needReindex}" != "" ]; then
		for reindex in ${needReindex}; do
			printf "\t%-23s\t%s\n" "Indexes need rebuild: " "${reindex}" | log
			alerts="${alerts} Indexes:Warning~Index~needs~rebuilding~${reindex}.KBI201"
			addKB "KBI201"
			healthScore "Indexes" "YELLOW"
		done
	fi

	if [ "${ctsIndexCount}" = "0" ]; then
		alerts="${alerts} Indexes:${ctsIndexCount}~CTS~indexes~configured~for~backend~${backend}~(expected~24,~is~this~a~ctsStore?)"
	fi
	if [ "${amCfgIndexCount}" = "0" ]; then
		alerts="${alerts} Indexes:${amCfgIndexCount}~AMconfig~indexes~configured~for~backend~${backend}~(expected~3,~is~this~a~configStore?)"
	fi
	if [ "${xmlIndexFound}" = "" ]; then
		printf "\t%s\n" "${yellow}Alert: sunxmlkeyvalue not found for backend ${backend}, is this an AM configStore?${nocolor}" | log
		alerts="${alerts} Indexes:sunxmlkeyvalue~not~found~for~backend~${backend},~is~this~an~AM~configStore?${systemIndex}"
	fi
	if [ "${customIndexCount}" != "0" ]; then
		alerts="${alerts} Indexes:${customIndexCount}~Custom~indexes~configured~for~backend~${backend}"
	fi

	if [ "${entryLimitAlert}" = "1" ]; then
		printf "\t%s\n" "${red}Alert: Excessive Index Limits in use${nocolor}" | log
	fi
	if [ "${badIndexTypeAlert}" = "1" ]; then
		iTypes=`echo ${iTypes} | sed "s/^ //"`
		printf "\t%s\n" "${red}Alert: Bad objectClass index type(s) found (${iTypes})${nocolor}" | log
	fi
	if [ "${systemIndexCount}" -lt "3" ]; then
		systemIndexes=`echo ${systemIndexes} | sed "s/|/ /g"`
		for systemIndex in ${systemIndexes}; do
			systemIndexCheck=`echo ${systemIndexesFound} | grep -iE "${systemIndex}"`
			if [ "${systemIndexCheck}" = "" ]; then
				systemIndex=`echo ${systemIndex} | sed "s/ds-cfg-attribute=//"`
				printf "\t%s" "${red}Fatal: MISSING SYSTEM INDEX (${systemIndex})${nocolor}" | log
				fatalalerts="${fatalalerts} Indexes:Fatal~Error:~Missing~System~Index~${systemIndex}.KBI202"
			fi
		done
	fi
	if [ "${ocIndexFound}" = "" ]; then
		printf "\t%s\n" "${red}Fatal: MISSING INDEX (objectClass)${nocolor}" | log
		fatalalerts="${fatalalerts} Indexes:Fatal~Error:~Missing~objectClass~Index~${systemIndex}"
	fi
	entryLimitAlert=0
	indexCount=1
	badIndexTypeAlert=0
	iTypes=''
done
	if [ "${Indexes}" != "RED" -o "${Indexes}" != "YELLOW" ]; then
		healthScore "Indexes" "GREEN"
	fi
}

printReplicaInfo()
{

printf "\n\n%s\n" "---------------------------------------" | log
printf "%s\n" "REPLICATION INFORMATION:" | log
printf "\n%s\n" "${replicationinfo}" | log
printf "%s\n\n" "---------------------------------------" | log

	# Check to see how many cn=domains this server has
	domainCount=`grep "cn=domains,cn=Multimaster Synchronization,cn=Synchronization Providers,cn=config" ${configfile} | grep -vE "dn: cn=domains|dn: cn=external changelog" | wc -l | awk '{print $1}'`
	if [ "${domainCount}" -gt "1" ]; then
		dstype="DS"
	fi
	rscount=`grep "dn: cn=replication server,cn=Multimaster Synchronization,cn=Synchronization Providers,cn=config" ${configfile} | wc -l | awk '{print $1}'`
	if [ "${rscount}" = "1" ]; then
		rstype="RS"
	fi
	if [ "${dstype}" = "DS" -a "${rstype}" = "RS" ]; then
		serverType="Directory Server + Replication Server (DS+RS)"
	elif [ "${dstype}" = "DS" -a "${rstype}" = "" ]; then
		serverType="Directory Server (DS only)"
	elif [ "${dstype}" = "" -a "${rstype}" = "RS" ]; then
		serverType="Replication Server (RS only)"
	else
		serverType="Stand Alone/Not replicated"
	fi

	printf "\t%s\t%s\n\n" "Replica type:" "${serverType}" | log
	# FIXME Don't display the following when the server type is "Stand Alone/Not replicated"
	printf "%s\t%s\n\n" "Directory Server Config:" | log

	# Calculate the longest ds-cfg-replication-server string for printf formatting
	longestRsName=`grep ds-cfg-replication-server: ${configfile} | sed "s/ds-cfg-replication-server: //" | awk '{ print length($0) " " $0; }' | sort -u -n | cut -d ' ' -f 2- | tail -1 | awk '{ print length($0) " " $0}' | awk '{print $1}'`

		# FIXME
		if [ "${longestRsName}" != "" ]; then
			if [ "${longestRsName}" != "" -a "${longestRsName}" -lt "22" ]; then
				longestRsName=22
			fi
		fi

  if [ "${serverType}" != "Stand Alone/Not replicated" ]; then
	# Get all DS cn=domains and sort them by longest to shorted (for display)
	replicaDomain=`grep 'cn=domains,cn=Multimaster Synchronization,cn=Synchronization Providers,cn=config' ${configfile} | grep -vE "dn: cn=domains|dn: cn=external changelog" | sed "s/ /~/g" | awk '{ print length($0) " " $0; }' | sort -r -n | cut -d ' ' -f 2-`

	# calculate $dashes to be displayed
	for domain in ${replicaDomain}; do
		getDashes "${longestRsName}"; d2=${dashes}

		domain=`echo ${domain} | sed "s/~/ /g" | sed "s/\\\\\/\./g"`
		baseDn=`sed -n "/${domain}/,/^ *$/p" ${configfile} | grep "ds-cfg-base-dn:" | sed "s/ds-cfg-base-dn: //"`
		calcLen2 "$baseDn"; dl=${btab}
			if [ "${btab}" -lt "19" ]; then
				btab="19"
				dl="19"
			fi
		getDashes "${dl}"; d1=${dashes}

	done

	printf "%-${btab}s\t%-5s\t\t%-${longestRsName}s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" "Replication Domain" "DS ID" "Replication Server(s)" "Conflict Purge" | log
	printf "%-${btab}s\t%-5s\t\t%-${longestRsName}s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" "${d1}" "-----" "${d2}" "--------------" | log
	for domain in ${replicaDomain}; do
		domain=`echo ${domain} | sed "s/~/ /g" | sed "s/\\\\\/\./g"`
		baseDn=`sed -n "/${domain}/,/^ *$/p" ${configfile} | grep "ds-cfg-base-dn:" | sed "s/ds-cfg-base-dn: //"`
		serverId=`sed -n "/${domain}/,/^ *$/p" ${configfile} | grep "ds-cfg-server-id:" | sed "s/ds-cfg-server-id: //"`
		replServers=`sed -n "/${domain}/,/^ *$/p" ${configfile} | grep "ds-cfg-replication-server:" | sed "s/ds-cfg-replication-server: //"`
		conflictPurge=`sed -n "/${domain}/,/^ *$/p" ${configfile} | grep "ds-cfg-conflicts-historical-purge-delay:" | sed "s/ds-cfg-conflicts-historical-purge-delay: //"`
			if [ "${conflictPurge}" = "" ]; then
				conflictPurge="1 d"
			fi

		printedbackend=0
		currentbase=""
	for thisbase in $replServers; do
		if [ "$printedbackend" = "0" -a "$currentbase" = "$thisbase" ]; then
			printf "%-${btab}s\t%-5s\t\t%-${longestRsName}s\t%s\t%s\t%s\t%s\t%s\n" "${baseDn}" "${serverId}" "${replServers}" "${conflictPurge}" | log
		
			printedbackend=1
			currentbase=$thisbase
		elif [ "$printedbackend" = "1" -a "$currentbase" != "$thisbase" ]; then
			printf "%-${btab}s\t%-5s\t\t%-${longestRsName}s\t%s\t%s\t%s\t%s\t%s\n" "" "" "${thisbase}" "${conflictPurge}" | log
			printedbackend=1
		else
			printf "%-${btab}s\t%-5s\t\t%-${longestRsName}s\t%s\t%s\t%s\t%s\t%s\n" "${baseDn}" "${serverId}" "${thisbase}" "${conflictPurge}" | log
			printedbackend=1
			currentbase=$thisbase
		fi
	done
			printedbackend=0
	done

	# Get the cn=replication server info
	replicaDomain=`grep 'cn=domains,cn=Multimaster Synchronization,cn=Synchronization Providers,cn=config' ${configfile} | grep -vE "dn: cn=domains|dn: cn=external changelog" | sed "s/ /~/g" | awk '{ print length($0) " " $0; }' | sort -r -n | cut -d ' ' -f 2-`

	# calculate $dashes to be displayed
	for domain in ${replicaDomain}; do
		domain=`echo ${domain} | sed "s/~/ /g" | sed "s/\\\\\/\./g"`
		baseDn=`sed -n "/${domain}/,/^ *$/p" ${configfile} | grep "ds-cfg-base-dn:" | sed "s/ds-cfg-base-dn: //"`
		calcLen2 "$baseDn"; dl=${btab}
			if [ "${btab}" -lt "19" ]; then
				btab="19"
			fi
		getDashes "${dl}"
	done

		baseDn=`sed -n "/${domain}/,/^ *$/p" ${configfile} | grep "ds-cfg-base-dn:" | sed "s/ds-cfg-base-dn: //"`

	if [ "${serverType}" = "Directory Server + Replication Server (DS+RS)" -o "${serverType}" = "Replication Server (RS only)" ]; then
		printf "\n%s\t%s\n\n" "Replication Server Config:" | log

		rsid=`sed -n "/dn: cn=replication server,cn=Multimaster Synchronization,cn=Synchronization Providers,cn=config/,/^ *$/p" ${configfile} | grep "ds-cfg-replication-server-id:" | sed "s/ds-cfg-replication-server-id: //"`
		grpid=`sed -n "/dn: cn=replication server,cn=Multimaster Synchronization,cn=Synchronization Providers,cn=config/,/^ *$/p" ${configfile} | grep "group-id:" | sed "s/group-id: //"`
		replicationport=`sed -n "/dn: cn=replication server,cn=Multimaster Synchronization,cn=Synchronization Providers,cn=config/,/^ *$/p" ${configfile} | grep "ds-cfg-replication-port:" | sed "s/ds-cfg-replication-port: //"`
		replicationservers=`sed -n "/dn: cn=replication server,cn=Multimaster Synchronization,cn=Synchronization Providers,cn=config/,/^ *$/p" ${configfile} | grep "ds-cfg-replication-server:" | sed "s/ds-cfg-replication-server: //"`
			for rs in ${replicationservers}; do
				if [ "${replservers}" = "" ]; then
					replservers="${rs}"
				else
					replservers="${replservers} ${rs}"
				fi
			done
		if [ "${compactversion}" -ge "650" ]; then
			computechangenumber=`sed -n "/dn: cn=replication server,cn=Multimaster Synchronization,cn=Synchronization Providers,cn=config/,/^ *$/p" ${configfile} | grep "ds-cfg-changelog-enabled:" | sed "s/ds-cfg-changelog-enabled: //"`
			changenumberindexerattr="ds-cfg-changelog-enabled"
			computechangenumber=`echo ${computechangenumber} | tr [:upper:] [:lower:]`
		else
			computechangenumber=`sed -n "/dn: cn=replication server,cn=Multimaster Synchronization,cn=Synchronization Providers,cn=config/,/^ *$/p" ${configfile} | grep "ds-cfg-compute-change-number:" | sed "s/ds-cfg-compute-change-number: //"`
			changenumberindexerattr="ds-cfg-compute-change-number"
		fi
		replicationpurgedelay=`sed -n "/dn: cn=replication server,cn=Multimaster Synchronization,cn=Synchronization Providers,cn=config/,/^ *$/p" ${configfile} | grep "ds-cfg-replication-purge-delay:" | sed "s/ds-cfg-replication-purge-delay: //"`
		sourceaddress=`sed -n "/dn: cn=replication server,cn=Multimaster Synchronization,cn=Synchronization Providers,cn=config/,/^ *$/p" ${configfile} | grep "ds-cfg-source-address:" | sed "s/ds-cfg-source-address: //"`
		mmsyncenabled=`sed -n "/dn: cn=Multimaster Synchronization,cn=Synchronization Providers,cn=config/,/^ *$/p" ${configfile} | grep "ds-cfg-enabled" | sed "s/ds-cfg-enabled: //"`

		if [ "${grpid}" = "" ]; then
			grpid="1"
		fi
		if [ "${computechangenumber}" = "" ]; then
			computechangenumber="true"
		fi
		if [ "${confidentialityenabled}" = "" ]; then
			confidentialityenabled="false"
		fi
		if [ "${replicationpurgedelay}" = "" ]; then
			replicationpurgedelay="3 d"
		fi
		if [ "${sourceaddress}" = "" ]; then
			sourceaddress="Let the server decide."
		fi

		printf "%-24s\t\t%-5s\t\t%-27s\t%s\t%s\t%s\t%s\t%s\n" "Property" "Value(s)" | log
		printf "%-24s\t\t%-5s\t\t%-27s\t%s\t%s\t%s\t%s\t%s\n" "------------------------" "--------" | log 
		printf "%-24s\t\t%-5s\t\t%-27s\t%s\t%s\t%s\t%s\t%s\n" "replication-server-id" "${rsid}" | log 
		printf "%-24s\t\t%-5s\t\t%-27s\t%s\t%s\t%s\t%s\t%s\n" "group-id" "${grpid}" | log 
		printf "%-24s\t\t%-5s\t\t%-27s\t%s\t%s\t%s\t%s\t%s\n" "ds-cfg-replication-port" "${replicationport}" | log 
		printf "%-24s\t\t%-5s\t\t%-27s\t%s\t%s\t%s\t%s\t%s\n" "ds-cfg-replication-server" "${replservers}" | log 
		printf "%-24s\t\t%-5s\t\t%-27s\t%s\t%s\t%s\t%s\t%s\n" "${changenumberindexerattr}" "${computechangenumber}" | log 
		printf "%-24s\t\t%-5s\t\t%-27s\t%s\t%s\t%s\t%s\t%s\n" "ds-cfg-confidentiality-enabled" "${confidentialityenabled}" | log 
		printf "%-24s\t\t%-5s\t\t%-27s\t%s\t%s\t%s\t%s\t%s\n" "ds-cfg-replication-purge-delay" "${replicationpurgedelay}" | log 
		printf "%-24s\t\t%-5s\t\t%-27s\t%s\t%s\t%s\t%s\t%s\n" "ds-cfg-source-address" "${sourceaddress}" | log 


		if [ "${computechangenumber}" = "disabled" ]; then
			alerts="${alerts} REPL:Replication~is~configured~but~the~changelog~is~disabled.KBI302"
			printf "\n\t%s\n\n" "${red}Info: Replication is configured but the changelog is disabled.${nocolor}" | log
			addKB "KBI302"
		fi
		mmsyncenabled=`echo ${mmsyncenabled} | tr [:upper:] [:lower:]`
		debug "mmsyncenabled->$mmsyncenabled"
		if [ "${rsid}" != "" -a "${mmsyncenabled}" = "false" ]; then
			fatalalerts="${fatalalerts} REPL:Replication~is~configured~but~is~currently~disabled.~Replication~is~offline!KBI300"
			printf "\n\t%s\n\n" "${red}Alert: Replication is configured but is currently disabled. Replication is offline!${nocolor}" | log
		fi
	fi

	# display connected server info
printf "\n%s\t%s\n\n" "Connected Servers:" | log
if [ "${serverType}" = "Directory Server + Replication Server (DS+RS)" -o "${serverType}" = "Replication Server (RS only)" ]; then
  if [ "${monitorfile}" != "" ]; then

	# loop through all domains and display the connected DS to RS
	for domain in ${replicaDomain}; do
		domain=`echo ${domain} | sed "s/~/ /g" | sed "s/\\\\\/\./g"`
		baseDn=`sed -n "/${domain}/,/^ *$/p" ${configfile} | grep "ds-cfg-base-dn:" | sed "s/ds-cfg-base-dn: //"`

	  if [ "${shortbaseversion}" -le "5" ]; then
		thisDomain=`echo ${baseDn} | sed "s/,/_/g" | sed "s/=/_/g"`
	  else
		thisDomain=`echo ${baseDn} | sed "s/,/.*/g"`
	  fi
		if [ -s ../node/networkInfo ]; then
			localhost=`grep 'Local Host:' ../node/networkInfo | awk '{print $3}'`
			runtimeaddress=`grep IP ../node/networkInfo | grep ${localhost} | awk -F" " '{print $NF}' | sed 's/[)(]//g'`
		fi

	# Work around not having the proper FQDN from the networkInfo avalable.
	# See if the IP is actually used for the Connected DS entries and use the $fqdn if not
	connectedDsIPCheck=`grep '^dn: ' ${monitorfile} | grep "${thisDomain}" | grep "${runtimeaddress}"`
	if [ "${connectedDsIPCheck}" = "" ]; then
		runtimeaddress=${fqdn}
	fi
	# Final fallback to deriving the host name from the networkInfo file, use the ds-cfg-server-fqdn/hostname value
	if [ "${runtimeaddress}" = "" ]; then
		runtimeaddress=${fqdn}
	fi

	printf "\t%s\t%s\t%s\n\n" "BaseDN:" "${baseDn}" "${connectedDSconflictsDisplay}" | log
	  if [ "${shortbaseversion}" -le "5" ]; then
		connectedDS=`grep "dn: cn=Connected directory server DS(.*) ${runtimeaddress}:.*,cn=Replication server RS(${rsid}) .*:${replicationport},cn=${thisDomain},cn=Replication,cn=monitor" ${monitorfile} | grep -v 'cn=Connected replication server RS'`

		connectedDSconflicts=`sed -n "/dn: cn=Directory server DS(.*) ${runtimeaddress}:.*,cn=${thisDomain},cn=Replication,cn=monitor/,/^ *$/p" ${monitorfile} | grep "unresolved-naming-conflicts:" | sed "s/unresolved-naming-conflicts: //"`
		dsid=`sed -n "/${domain}/,/^ *$/p" ${configfile} | grep "ds-cfg-server-id:" | sed "s/ds-cfg-server-id: //"`

		baseDn=`echo ${baseDn} | sed "s/ /~/g"`

		# FIXME if connectedDSconflicts
		if [ "${connectedDSconflicts}" ]; then
			if [ "${connectedDSconflicts}" -gt "0" ]; then
				connectedDSconflictsDisplay="${red}unresolved-naming-conflicts: [${connectedDSconflicts}]${nocolor} *"
				alerts="${alerts} REPL:${baseDn}~has~${connectedDSconflicts}~unresolved~naming~conflicts.KBI301"
				addKB "KBI301"
				healthScore "Replication" "RED"
			else
				connectedDSconflictsDisplay=""
			fi
		fi

		thisRS=`echo ${connectedDS} | sed "s/.*cn=Replication server RS//" | sed "s/,cn=${thisDomain},cn=Replication,cn=monitor//"`
		connectedDS=`echo ${connectedDS} | sed "s/dn: cn=Connected directory server DS//" | sed s"/,cn=Replication server RS.*//"`
			if [ "${connectedDS}" = "" ]; then
				connectedDS="(${dsid}) ${runtimeaddress}:${adminPort}"
				connectionInfo="${red}is not connected to an${nocolor}"
				alerts="${alerts} REPL:DS~for~${baseDn}~is~not~connected~to~an~RS"
			else
				connectionInfo="${green}<- connected to ->${nocolor}"
			fi
		calcLen "${connectedDS}"; cdstab=${tab}
		printf "\t\t%-9s %-${cdstab}s %-23s" "This DS:" "${connectedDS}" "${connectionInfo}" | log
			if [ "${thisRS}" = "" ]; then
				thisRS="(${rsid}) ${runtimeaddress}:${replicationport}"
				connectedRS=""
				connectionInfo="${red}is not connected to an${nocolor}"
			else
				connectionInfo="${green}<- connected to ->${nocolor}"
				connectedRS="(${rsid}) ${runtimeaddress}:${replicationport}"
			fi
		printf "%s %s\n" " RS:" "${connectedRS}" | log

		connectedRS=`grep "dn: cn=Connected replication server RS(.*) .*:.*,cn=Replication server RS(${rsid}) .*:${replicationport},cn=${thisDomain},cn=Replication,cn=monitor" ${monitorfile}`
		connectedRS=`echo ${connectedRS} | sed "s/dn: cn=Connected replication server RS//" | sed s"/,cn=Replication server RS.*//"`
			if [ "${connectedRS}" = "" ]; then
				#thisRS="(${rsid}) ${runtimeaddress}:${replicationport}"
				connectedRS=""
				connectionInfo="${red}is not connected to an${nocolor}"
				alerts="${alerts} REPL:RS~for~${baseDn}~is~not~connected~to~another~RS"
			else
				connectionInfo="${green}<- connected to ->${nocolor}"
			fi

		calcLen "${thisRS}"; crstab=${tab}
		printf "\t\t%-9s %-${crstab}s %-23s" "This RS:" "${thisRS}" "${connectionInfo}" | log
		printf "%s %s\n\n" " RS:" "${connectedRS}" | log

	  # DS 6x block - begin
	  else
		# DS6+ Connected DS
		dsid=`sed -n "/${domain}/,/^ *$/p" ${configfile} | grep "ds-cfg-server-id:" | sed "s/ds-cfg-server-id: //"`

		if [ "${dsid}" = "" ]; then
			dsid=`sed -n "/dn: cn=config/,/^ *$/p" ${configfile} | grep "ds-cfg-server-id:" | sed "s/ds-cfg-server-id: //"`
		fi
		connectedDS=`sed -n "/dn: ds-mon-server-id=${dsid},cn=connected replicas,ds-mon-domain-name=${thisDomain},cn=changelog,cn=replication,cn=monitor/,/^ *$/p" ${monitorfile} | grep 'ds-mon-replica-hostport:' | sed "s/ds-mon-replica-hostport: //"`
			if [ "${connectedDS}" = "" ]; then
				connectedDS="(${dsid}) ${runtimeaddress}:${adminPort}"
				connectionInfo="${red}is not connected to an${nocolor}"
				baseDn=`echo ${baseDn} | sed "s/ /~/g"`
				alerts="${alerts} REPL:DS~for~${baseDn}~is~not~connected~to~an~RS"
				baseDn=`echo ${baseDn} | sed "s/~/ /g"`
			else
				connectionInfo="${green}<- connected to ->${nocolor}"
			fi
		DSconnectedRS=`sed -n "/dn: ds-mon-server-id=${dsid},cn=connected replicas,ds-mon-domain-name=${thisDomain},cn=changelog,cn=replication,cn=monitor/,/^ *$/p" ${monitorfile} | grep 'ds-mon-connected-to-server-hostport:' | sed "s/ds-mon-connected-to-server-hostport: //"`

		rsid=`sed -n "/dn: ds-mon-server-id=${dsid},cn=connected replicas,ds-mon-domain-name=${thisDomain},cn=changelog,cn=replication,cn=monitor/,/^ *$/p" ${monitorfile} | grep 'ds-mon-connected-to-server-id:' | sed "s/ds-mon-connected-to-server-id: //"`
		connectedDS="(${dsid}) ${connectedDS}"
		DSconnectedRS="(${rsid}) ${DSconnectedRS}"
		calcLen "${connectedDS}"; cdstab=${tab}
		printf "\t\t%-9s %-${cdstab}s %-23s" "This DS:" "${connectedDS}" "${connectionInfo}" | log
		printf "%s %s\n" " RS:" "${DSconnectedRS}" | log

		# DS6+ Connected RS
		connectedRS=`sed -n "/dn: ds-mon-changelog-id=.*,cn=connected changelogs,ds-mon-domain-name=${thisDomain},cn=changelog,cn=replication,cn=monitor/,/^ *$/p" ${monitorfile} | grep 'ds-mon-changelog-hostport:' | sed "s/ds-mon-changelog-hostport: //" | head -1`
		connectedrsid=`sed -n "/dn: ds-mon-changelog-id=.*,cn=connected changelogs,ds-mon-domain-name=${thisDomain},cn=changelog,cn=replication,cn=monitor/,/^ *$/p" ${monitorfile} | grep 'ds-mon-changelog-id:' | sed "s/ds-mon-changelog-id: //" | head -1`

			if [ "${connectedRS}" = "" ]; then
				connectedRS=""
				connectionInfo="${red}is not connected to an${nocolor}"
				baseDn=`echo ${baseDn} | sed "s/ /~/g"`
				alerts="${alerts} REPL:RS~for~${baseDn}~is~not~connected~to~another~RS"
				baseDn=`echo ${baseDn} | sed "s/~/ /g"`
			else
				connectionInfo="${green}<- connected to ->${nocolor}"
			fi

		calcLen "${thisRS}"; crstab=${tab}
		printf "\t\t%-9s %-${crstab}s %-23s" "This RS:" "${DSconnectedRS}" "${connectionInfo}" | log
		connectedRS="(${connectedrsid}) ${connectedRS}"
		printf "%s %s\n\n" " RS:" "${connectedRS}" | log
	  fi
	  # DS 6x block - end

	done
  else
	printf "%s\t%s\n" "Note:" "cn=monitor data is not available, to derive this information." | log
  fi

# Print some hints on how the runtime and configured RS hostnames are derived...since they can all be different.
printf "%s\n" "
[Internal Notes (not logged)]
1. This DS \"hostname\" is derived from the \"Local Host's\" ip address as seen in the ../node/networkInfo file

	See:
	grep 'Local Host:' ../node/networkInfo | awk '{print $\3}' -> i.e. ${localhost}
	grep IP ../node/networkInfo | grep ${localhost} | awk -F\" \" '{print \$NF}' | sed 's/[)(]//g' -> i.e. ${runtimeaddress}

2. This RS \"hostname\" is derived from the RS configuration
"
else
	printf "\t%s\n\n" "Server is a Directory Server (DS only) - No connected servers" | log
fi

  fi # <- if [ "${serverType}" != "Stand Alone/Not replicated" ]; then

	if [ "${Replication}" != "RED" -o "${Replication}" != "YELLOW" ]; then
		healthScore "Replication" "GREEN"
	fi
}

printBackends()
{

printf "%s\n" "---------------------------------------" | log
printf "%s\n" "BACKEND INFORMATION:" | log
printf "\n%s\n" "${backendinfo}" | log
printf "%s\n\n" "---------------------------------------" | log
if [ "${backends}" = "" ]; then
	printf "\t%s\n\t%s\n\n" "No Backends available...system could be a Replication Server" "See below." | log
	return
fi

# Calculate the string length of the backends.
for backend in $backends; do
	calcLen "$backend"
done

	if [ "$tab" -lt "8" ]; then
		tab=8
	fi

	sharedCacheEnabled=`sed -n "/dn: cn=config/,/^ *$/p" $configfile | grep "ds-cfg-je-backend-shared-cache-enabled: " | sed "s/ds-cfg-je-backend-shared-cache-enabled: //"`
	sharedCacheEnabled=`echo ${sharedCacheEnabled} | tr [:upper:] [:lower:]`
	if [ "${compactversion}" -ge "650" -a "${sharedCacheEnabled}" = "false" ]; then
		sharedCacheAddInMsg="The db-cache-percent & db-cache-size settings are in effect. (JE shared-cache is disabled)"
		sharedCacheAddInMsgAlert="The~db-cache-percent~&~db-cache-size~settings~are~in~effect.~(JE~shared-cache~is~disabled)"
	elif [ "${compactversion}" -ge "650" -a "${sharedCacheEnabled}" = "" -o "${sharedCacheEnabled}" = "true" ]; then
		sharedCacheEnabled="true"
	else
		sharedCacheEnabled=""
	fi

# calculate the string len of each backend name
for backend in $backends; do
	# sed to substitute spaces in the baseDN like -> o=Bank New
	basedn=`sed -n "/dn: ds-cfg-backend-id=${backend},cn=Backends,cn=config/,/^ *$/p" $configfile | grep "ds-cfg-base-dn: " | sed "s/ds-cfg-base-dn: //" | sed "s/ /-/g"`
	calcLen2 "$basedn"; dl=${btab}
	getDashes "${dl}"
	dbcache=`sed -n "/dn: ds-cfg-backend-id=${backend},cn=Backends,cn=config/,/^ *$/p" $configfile | grep "ds-cfg-db-cache-percent: " | sed "s/ds-cfg-db-cache-percent: //"`
	limit=`sed -n "/dn: ds-cfg-backend-id=${backend},cn=Backends,cn=config/,/^ *$/p" $configfile | grep "index-entry-limit: " | sed "s/index-entry-limit: //"`
	backendType=`sed -n "/dn: ds-cfg-backend-id=${backend},cn=Backends,cn=config/,/^ *$/p" $configfile | grep "ds-cfg-java-class: " | sed "s/\./ /g" | awk -F" " '{print $NF}' | sed "s/Backend//"`
	confidentiality=`sed -n "/dn: ds-cfg-backend-id=${backend},cn=Backends,cn=config/,/^ *$/p" $configfile | grep "confidentiality-enabled: " | sed "s/\./ /g" | awk -F" " '{print $NF}' | sed "s/Backend//"`
		if [ "$backendType" = "Impl" ]; then
			backendType="JE"
		fi
done

# print all
	printf "%-${tab}s\t%-${btab}s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" "BackendID" "BaseDN" "Db-Cache%" "Enabled" "iLimit" "LG-Cache" "Type" "Encryption" "Cmprs" "Entries" | log
	printf "%-${tab}s\t%-${btab}s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" "---------" "${dashes}" "---------" "-------" "------" "--------" "----" "----------" "-----" "-------" | log

for backend in $backends; do
	check=`echo "rootUser adminRoot ads-truststore backup config monitor schema tasks" | grep ${backend}`
	if [ $? = 0 -a "$displayall" = "" ]; then
		i=`expr  1 + 1`
	else
	basedn=`sed -n "/dn: ds-cfg-backend-id=${backend},cn=Backends,cn=config/,/^ *$/p" $configfile | grep "ds-cfg-base-dn: " | sed "s/ds-cfg-base-dn: //" | sed "s/ /-/g"`
	dbcache=`sed -n "/dn: ds-cfg-backend-id=${backend},cn=Backends,cn=config/,/^ *$/p" $configfile | grep "ds-cfg-db-cache-percent: " | sed "s/ds-cfg-db-cache-percent: //"`
	logcache=`sed -n "/dn: ds-cfg-backend-id=${backend},cn=Backends,cn=config/,/^ *$/p" $configfile | grep "ds-cfg-db-log-filecache-size: " | sed "s/ds-cfg-db-log-filecache-size: //"`
	compression=`sed -n "/dn: ds-cfg-backend-id=${backend},cn=Backends,cn=config/,/^ *$/p" $configfile | grep "ds-cfg-entries-compressed: " | sed "s/ds-cfg-entries-compressed: //"`
	limit=`sed -n "/dn: ds-cfg-backend-id=${backend},cn=Backends,cn=config/,/^ *$/p" $configfile | grep "ds-cfg-index-entry-limit: " | sed "s/ds-cfg-index-entry-limit: //"`
	backendType=`sed -n "/dn: ds-cfg-backend-id=${backend},cn=Backends,cn=config/,/^ *$/p" $configfile | grep "ds-cfg-java-class: " | sed "s/\./ /g" | awk -F" " '{print $NF}' | sed "s/Backend//"`
	confidentiality=`sed -n "/dn: ds-cfg-backend-id=${backend},cn=Backends,cn=config/,/^ *$/p" $configfile | grep "confidentiality-enabled: " | sed "s/\./ /g" | awk -F" " '{print $NF}' | sed "s/Backend//"`

		if [ "${dbcache}" = "" -a "$check" = "" ]; then
			dbcache="50"
		fi
		if [ "${dbcache}" = "" -a "$check" != "" ]; then
			dbcache="-"
		fi
		if [ "${limit}" = "" -a "$check" = "" ]; then
			limit="4000"
		fi
		if [ "${limit}" != "" -a "${limit}" -gt "50000" ]; then
			alerts="${alerts} Backends:Excessive~Global~Index~Limit~Set.KBI101"
			addKB "KBI101"
			excesssiveGlobalLimit=${limit}
		fi
		# Set the default logcache if not present in the config.
		if [ "${logcache}" = "" -a "$check" = "" ]; then
  			if [ "${shortbaseversion}" -ge "6" ]; then
				logcache="200"
			else
				logcache="100"
			fi
		fi
		if [ "${compression}" = "" -a "$check" = "" ]; then
			compression="false"
			# Final change here. Stop
		fi
		if [ "${limit}" = "" -a "$check" != "" ]; then
			limit="-"
		fi
		if [ "$backendType" = "Impl" ]; then
			backendType="JE"
		fi
		if [ "$confidentiality" = "" ]; then
			confidentiality=false""
		else
			prodModeCheck1="1"
		fi
	enabled=`sed -n "/dn: ds-cfg-backend-id=${backend},cn=Backends,cn=config/,/^ *$/p" $configfile | grep "ds-cfg-enabled: " | sed "s/ds-cfg-enabled: //" | tr [:upper:] [:lower:]`

	for thisbase in $basedn; do
		getBackendEntries "${backend}" "${thisbase}"

		# Get a total count of all backends entries
		if [ "${entries}" != "NA" ]; then
			totalentries=`expr ${totalentries} + ${entries}`
		fi

		if [ "$printedbackend" = "0" -a "$currentbase" = "$thisbase" ]; then
			printf "%-${tab}s\t%-${btab}s\t%s\t\t%s\t%s\t%s\t%s\t\t%s\t%s\n" ${backend} ${thisbase} ${dbcache} ${enabled} ${limit} "${logcache}" ${confidentiality} "Com3" "${entries}" | log
		
			printedbackend=1
			currentbase=$thisbase
		elif [ "$printedbackend" = "1" -a "$currentbase" != "$thisbase" ]; then
			printf "%-${tab}s\t%-${btab}s\t%s\t\t%s\t%s\t%s\t\t%s\t%s\t%s\t\t%s\n" " " ${thisbase} " " " " " " " " " " " " " " "${entries}" | log
			printedbackend=1
		else
			printf "%-${tab}s\t%-${btab}s\t%s\t\t%s\t%s\t%s\t\t%s\t%s\t\t%s\t%s\t%s\n" ${backend} ${thisbase} ${dbcache} ${enabled} ${limit} "${logcache}" ${backendType} ${confidentiality} "${compression}" "${entries} ${entriesaddin}" | log
			printedbackend=1
			currentbase=$thisbase
		fi
			totaldbcache=`expr ${totaldbcache} + ${dbcache}`
			dbcache=0
			limit=''
	done
	fi
			printedbackend=0
done

			if [ "${compactversion}" -ge "650" -a "${totaldbcache}" -gt "80" -a "${sharedCacheEnabled}" = "true" ]; then
				alerts="${alerts} Backends:Total~db-cache-percent~is~greater~than~80%~but~the~JE~shared-cache~is~enabled.~The~db-cache-percent~&~db-cache-size~settings~are~ignored.KBI105"
				addKB "KBI105"
				totaldbcachemsg="${totaldbcache}% Total *"
			elif [ "${totaldbcache}" -gt "80" -a "${totaldbcache}" -lt "90" ]; then
				alerts="${alerts} Backends:Total~db-cache-percent~is~greater~than~80%~${sharedCacheAddInMsgAlert}.KBI100"
				addKB "KBI100"
				totaldbcachemsg="${totaldbcache}% Total *"
			elif [ "${totaldbcache}" -ge "90" ]; then
				alerts="${alerts} Backends:Total~db-cache-percent~is~greater~than~90%~${sharedCacheAddInMsgAlert}.KBI100"
				addKB "KBI100"
				totaldbcachemsg="${totaldbcache}% Total *"
			else
				totaldbcachemsg="${totaldbcache}% Total"
			fi
	printf "%-${tab}s\t%-${btab}s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" "---------" "${dashes}" "---------" "-------" "------" "--------" "----" "----------" "-----" "-------" | log
	#		printf "%-${tab}s\t%-${btab}s\t%s\t\t%s\t%s\t%s\t%s\t%s\t%s\t\t%s\t%s\t%s\t%s\n" "" "" "${totaldbcachemsg}" "-" "-" "-" "-" "-" "$totalentries" | log
	printf "%-${tab}s\t%-${btab}s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" "         " "      " "${totaldbcachemsg}" "       " "      " "        " "    " "          " "     " "${totalentries}" | log

			if [ "${compactversion}" -ge "650" -a "${totaldbcache}" -gt "80" -a "${sharedCacheEnabled}" = "true" ]; then
				printf "\n\t%s\n" "Info: Total db-cache-percent is greater than 80% but the JE shared-cache is enabled. The db-cache-percent & db-cache-size settings are ignored." | log
			fi
			if [ "${compactversion}" -ge "650" -a "${totaldbcache}" -le "80" -a "${sharedCacheEnabled}" = "true" ]; then
				printf "\n\t%s\n" "Info: The JE shared-cache is enabled. The db-cache-percent & db-cache-size settings are ignored." | log
				addKB "KBI105"
			fi
			if [ "${compactversion}" -ge "650" -a "${totaldbcache}" -le "80" -a "${sharedCacheEnabled}" = "false" ]; then
				printf "\n\t%s\n" "Info: ${sharedCacheAddInMsg}." | log
			fi
			if [ "${totaldbcache}" -gt "80" -a "${totaldbcache}" -lt "90" -a "${sharedCacheEnabled}" = "false" ]; then
				printf "\n\t%s\n" "${yellow}Warning: Total db-cache-percent is greater than 80%. ${sharedCacheAddInMsg}${nocolor}" | log
			fi
			if [ "${totaldbcache}" -ge "90" -a "${sharedCacheEnabled}" = "false" -o "${totaldbcache}" -ge "90" -a "${sharedCacheEnabled}" = "" ]; then
				printf "\n\t%s\n" "${red}Alert: Total db-cache-percent is greater than 90%. ${sharedCacheAddInMsg}${nocolor}" | log
			fi
			if [ "${compression}" = "true" -o "$compression" = "TRUE" ]; then
				alerts="${alerts} Backends:Entry~Compression~is~on,~at~risk~of~hitting~OPENDJ-5137.KBI102"
				addKB "KBI102"
				printf "\n\t%s\n" "${red}Alert: Entry Compression is on, at risk of hitting OPENDJ-5137${nocolor}" | log
			fi
			if [ "${backendAlert}" != "" ]; then
				echo "\n\t${red}Alert: ${backendAlert}${nocolor}\n" | log
				if [ "${backendException}" ]; then
					echo "\t${backendException}"
				fi
			fi
			if [ "${excesssiveGlobalLimit}" ]; then
				printf "\n\t%s\n" "${yellow}Warning: Excessive Global Index Limit Set - ${excesssiveGlobalLimit}${nocolor}" | log
			fi
	printKey

	if [ "${Backends}" != "RED" -o "${Backends}" != "YELLOW" ]; then
		healthScore "Backends" "GREEN"
	fi
}

printJvmInfo()
{
	jvmargs=$1
	# print the JVM args in a more readable format
	for arg in $jvmargs; do
		if [ `echo "${arg}" | grep -i 'UseCompressedOops'` ]; then
			addon="<-- ${green}-XX:+UseCompressedOops used!${nocolor}"
			usecompressedoops=1
		elif [ `echo "${arg}" | grep -i ':MaxTenuringThreshold=1'` ]; then
			addon="<-- ${green}-XX:MaxTenuringThreshold=1 used!${nocolor}"
			maxtenuringthreshold=1
		elif [ `echo "${arg}" | grep -i 'UseConcMarkSweepGC'` ]; then
			addon="<-- ${green}-XX:UseConcMarkSweepGC used!${nocolor}"
			collectorinuse=1
		elif [ `echo "${arg}" | grep -i 'UseG1GC'` ]; then
			addon="<-- ${green}-XX:UseG1GC used!${nocolor}"
			collectorinuse=1
			collectorType='UseG1GC'
		elif [ `echo "${arg}" | grep -i 'DisableExplicitGC'` ]; then
			addon="<-- ${green}-XX:DisableExplicitGC used!${nocolor}"
			DisableExplicitGCInUse=1
		elif [ `echo "${arg}" | grep -i 'Xloggc'` ]; then
			gclogging=1
		elif [ `echo "${arg}" | grep -i 'Xmx'` ]; then
			Xmx=`echo ${arg} | sed "s/.Xmx//"`
			Xmxvalue=`echo ${Xmx} | sed "s/.Xmx//"`
			XmxInUse=1
		elif [ `echo "${arg}" | grep -i 'Xms'` ]; then
			Xms=`echo ${arg} | sed "s/.Xms//"`
			Xmsvalue=`echo ${Xms} | sed "s/.Xms//"`
			XmsInUse=1
		else
			addon=''
		fi
		if [ `echo ${Xmxvalue} | grep -i 'g' ` ]; then
			XmxGbValue=`echo ${Xmxvalue} | sed 's/[^0-9]*//g' | awk '{ byte =$1 **2 ; print byte " GB" }'`
			XmxGbNumericalValue=`echo ${XmxGbValue} | sed 's/GB//g'`
		elif [ `echo ${Xmxvalue} | grep -i 'm' ` ]; then
			XmxGbValue=`echo ${Xmxvalue} | sed 's/[^0-9]*//g' | awk '{ byte =$1 /1024**2 ; print byte " GB" }'`
			XmxGbNumericalValue=`echo ${XmxGbValue} | sed 's/GB//g'`
		else
			XmxGbValue=`echo ${Xmxvalue} | sed 's/[^0-9]*//g' | awk '{ byte =$1 /1024/1024**2 ; print byte " GB" }'`
			XmxGbNumericalValue=`echo ${XmxGbValue} | sed 's/GB//g'`
		fi
		
		if [ "${XmxInUse}" != "" -a "${XmsInUse}" != "" -a "${Xmxvalue}" = "${Xmsvalue}" -a "${minMaxAlert}" = "" ]; then
			minMaxAlert=1
			addon="<-- ${green}-Xmx is the same as the -Xms value (good)${nocolor}"
		fi
##echo "DEBUG -> \"${XmxInUse}\" != \"\" -a \"${XmxGbValue}\" -lt \"2\""
#echo "XmxGbNumericalValue - $XmxGbNumericalValue"
#		if [ "${XmxInUse}" != "" -a "${XmxGbNumericalValue}" -lt "2" ]; then
		#	minMaxAlert=1
#echo "OKAY"
		#	addon="<-- ${red}-Xmx is under 2GB for a production server${nocolor}"
#		fi
		printf "\t%-29s%s\n" "${arg}" "${addon}" | log

		# unset the addon message so that other options don't print the same addon msg.
		addon=''
	done
}

getJVMInfo()
{
printf "%s\n" "---------------------------------------" | log
printf "%s\n" "JVM ARGS & SYSTEM INFORMATION:" | log
printf "\n%s\n" "${jvminfo}" | log
printf "%s\n\n" "---------------------------------------" | log
	if [ "${monitorfile}" != "" ]; then
			javaVersion=`grep -iE 'javaVersion|ds-mon-jvm-java-version' ${monitorfile} | awk '{print $2}'`
			jvmFileFound=1
			javaShortVersion=`echo ${javaVersion} | cut -c3`
		printf "\t%-16s  %s\n" "javaVersion" "$javaVersion" | log
			javaVendor=`grep -iE 'javaVendor|ds-mon-jvm-java-vendor' ${monitorfile} | sed "s/.*: //"`
		printf "\t%-16s  %s\n" "javaVendor" "$javaVendor" | log
			usedMemory=`grep -iE 'usedMemory|ds-mon-jvm-memory-used' ${monitorfile} | head -1 | awk '{print $2}'`
			usedMemoryGb=`echo ${usedMemory} | awk '{ byte =$1 /1024/1024**2 ; print byte " GB" }'`
			printf "\t%-16s  %s\n" "usedMemory" "$usedMemory (${usedMemoryGb})" | log
			maxMemory=`grep -iE 'maxMemory|ds-mon-jvm-memory-max' ${monitorfile} | awk '{print $2}'`
			maxMemoryGb=`echo ${maxMemory} | awk '{ byte =$1 /1024/1024**2 ; print byte " GB" }'`
			printf "\t%-16s  %s\n" "maxMemory" "$maxMemory (${maxMemoryGb})" | log
		if [ -s ../node/diskInfo ]; then
			availSpace=`awk '{print $14}' ../node/diskInfo` 
			availSpaceGb=`echo ${availSpace} | awk '{ byte =$1 /1024/1024**2 ; print byte " GB" }'`
			printf "\t%-16s  %s\n" "avail disk space" "${availSpace} ($availSpaceGb)" | log
		fi
			availableCPUs=`grep -iE 'availableCPUs|ds-mon-jvm-available-cpus' ${monitorfile} | awk '{print $2}'`
        		if [ "${availableCPUs}" = "" ]; then
				availableCPUs='0'
			fi
		printf "\t%-16s  %s\n\n" "available CPUs" "$availableCPUs" | log
        		if [ "${availableCPUs}" -lt "2" -a "${availableCPUs}" != "0" ]; then
				alerts="$alerts System:Only~${availableCPUs}~CPU~available.~Performance~can~suffer.KBI601"
				addKB "KBI601"
				printf "\t%-54s\t%s\n\n" "${red}Alert: ${availableCPUs} CPU's available. Performance can suffer${nocolor}" "*" | log
			fi
			operatingSystem=`grep -iE 'operatingSystem|ds-mon-os-version' ${monitorfile} | awk '{print $2}'`
		printf "\t%-16s  %s\n\n" "Operating System" "$operatingSystem" | log
	fi
printf "%-26s %s\n\n" "java.properties (start-ds.java-args)" | log
	if [ -s ./config.ldif -a -s ./java.properties ]; then
		theseArgs=`grep '^start-ds.java-args=' java.properties | sed "s/start-ds.java-args=//"`
		printJvmInfo "$theseArgs"
		jvmFileFound=1
	else
		printf "\t%s\n" "java.properties not available" | log
	fi
printf "\n" | log
printf "%-26s\t%s\n\n" "cn=monitor - (jvmArguments)" | log
	if [ "${monitorfile}" != "" ]; then
		jvmFileFound=1
		jvmArchitecture=`grep -iE 'jvmArchitecture|ds-mon-jvm-architecture' ${monitorfile} | awk '{print $2}'`
		printf "\t%s\n" "jvmArchitecture - $jvmArchitecture" | log
		theseArgs=`grep -iE 'jvmArguments|ds-mon-jvm-arguments' ${monitorfile}`
		printJvmInfo "$theseArgs"
	else
		printf "\t%s\n" "monitor.ldif not available" | log
	fi
printf "\n" | log
printf "%-26s\t%s\n\n" "server.out log - (JVM Arguments)" | log
	if [ -s ../logs/server.out ]; then
		theseArgs=`grep "msg=JVM Arguments" ../logs/server.out | sed "s/.*msg=JVM Arguments://"`
		if [ "${theseArgs}" != "" ]; then
			printJvmInfo "$theseArgs"
			jvmFileFound=1
		else
			echo "\tJVM Arguments not available" | log
		fi
	else
		printf "\t%s\n" "server.out log not available" | log
	fi

	printf "\n" | log

   if [ "${jvmFileFound}" = "1" ]; then
        if [ "${usecompressedoops}" != "1" -o "${maxtenuringthreshold}" != "1" -o "${gclogging}" != "1" ]; then
		printf "\n%-26s\t%s\n\n" "Results:" | log
	fi
        if [ "${collectorinuse}" != "1" ]; then
		alerts="$alerts JVM:-XX:+UseConcMarkSweepGC~or~-XX:+UseG1GC~not~defined"
		printf "\t%-54s\t%s\n" "${red}Alert: -XX:+UseConcMarkSweepGC or -XX:+UseG1GC missing${nocolor}" "*" | log
		tuningKBNeeded=1
	fi
        if [ "${Xmx}" = "" ]; then
		alerts="$alerts JVM:-Xmx~not~defined"
		printf "\t%-54s\t%s\n" "${red}Alert: -Xmx missing${nocolor}" "*" | log
		tuningKBNeeded=1
	fi
        if [ "${Xms}" = "" ]; then
		alerts="$alerts JVM:-Xms~not~defined"
		printf "\t%-54s\t%s\n" "${red}Alert: -Xms missing${nocolor}" "*" | log
	fi
        if [ "${usecompressedoops}" != "1" ]; then
		alerts="$alerts JVM:-XX:+UseCompressedOops~not~used"
		printf "\t%-54s\t%s\n" "${red}Alert: -XX:+UseCompressedOops missing${nocolor}" "*" | log
	fi
        if [ "${maxtenuringthreshold}" != "1" ]; then
		alerts="$alerts JVM:-XX:MaxTenuringThreshold=1~not~used"
		printf "\t%-54s\t%s\n" "${red}Alert: -XX:MaxTenuringThreshold=1 missing${nocolor}" "*" | log
		tuningKBNeeded=1
		healthScore "JVMTuning" "RED"
	fi
        if [ "${minMaxAlert}" != "1" -a "${XmxInUse}" != "" -a "${XmsInUse}" != "" ]; then
		alerts="$alerts JVM:-Xmx~should~be~the~same~as~-Xms~and~is~not"
		printf "\t%-54s\t%s\n" "${red}Alert: -Xmx (${Xmx}) are not equal -Xms (${Xms})${nocolor}" "*" | log
		tuningKBNeeded=1
	fi
        if [ "${gclogging}" != "1" ]; then
		alerts="$alerts JVM:GC~Logging~not~enabled"
		printf "\t%-54s\t%s\n" "${yellow}Warning: GC Logging not enabled${nocolor}" "*" | log
		addKB "KBI602"
	fi
        if [ "${jmxportenabled}" = "enabled" -a "${DisableExplicitGCInUse}" = "" ]; then
		alerts="$alerts JVM:JMX~Handler~enabled~without~-XX:+DisableExplicitGC~-~Full~GC~(System.gc())s~will~happen!"
		printf "\t%-54s\t%s\n" "${red}Alert: JMX Handler enabled without -XX:+DisableExplicitGC - Full GC (System.gc())s will happen!${nocolor}" "*" | log
		tuningKBNeeded=1
	fi

	if [ "${javaShortVersion}" != "" -a "${collectorType}" != "" ]; then
		if [ "${javaShortVersion}" -lt "11" -a "${collectorType}" = "UseG1GC" ]; then
			alerts="$alerts JVM:G1~Collector~in~use~with~JDK~${javaShortVersion}.~G1~bugs~fixed~in~JDK~11"
			printf "\t%-54s\t%s\n" "${yellow}Alert: G1 Collector in use with JDK ${javaShortVersion}. G1 bugs fixed in JDK 11${nocolor}" "*" | log
		fi
	fi

	if [ "${ldapporttlsv13}" = "TLSv1.3" -o "${ldapsporttlsv13}" = "TLSv1.3" -o "${ttlsv13mon}" = "TLSv1.3" ]; then
		alerts="$alerts JVM:TLSv1.3~in~use~with~JDK~11.~TLSv1.3~bugs~exist.KBI609"
		addKB "KBI609"
		printf "\t%-54s\t%s\n" "${yellow}Alert: TLSv1.3 in use with JDK 11. TLSv1.3 bugs exist.${nocolor}" "*" | log
	fi

	# OPENDJ-5260 is fixed in 6.5.0 and was backported to 5.5.2
	if [ "${compactversion}" = "400" -o "${compactversion}" = "550" -o "${compactversion}" = "551" ]; then
		alerts="$alerts JVM:Grizzly~pre-allocated~MemoryManager~not~needed.~Use~Jira~workaround.KBI610"
		addKB "KBI610"
		printf "\t%-54s\t%s\n" "${yellow}Info: Grizzly pre-allocated MemoryManager not needed. Use Jira workaround.${nocolor}" "*" | log
		tuningKBNeeded=1
	fi
	if [ "${tuningKBNeeded}" = "1" ]; then
		addKB "KBI600"
		printf "\n\t%-54s\t%s\n" "${yellow}JVM tuning is needed, for the above issues${nocolor}" "*" | log
	fi
   fi
	if [ "${JVMTuning}" != "RED" -o "${JVMTuning}" != "YELLOW" ]; then
		healthScore "JVMTuning" "GREEN"
	fi
}

printCertInfo()
{
	connectorName=$1
	#certStoreEntry=$2
	certStoreFileParam=$3
	connectorDisplayName=$3

	# Get the cert from the cn=config entry
	# -> connectorName dn: cn=LDAPS Connection Handler,cn=connection handlers,cn=config
	#	-> keyManagerEntry ds-cfg-key-manager-provider
	#		-> keyMgrPovider cn=Default Key Manager,cn=Key Manager Providers,cn=config
	#			-> ds-cfg-key-store-file config/keystore

#echo "\nconnectorName -> $connectorName"

  #connectorEnable=`sed -n "/${connectorName}/,/^ *$/p" ${configfile} | grep "ds-cfg-enabled:" | sed "s/ds-cfg-enabled: //" | tr [:upper:] [:lower:]`

	printf "\n" | log
	certNick=`sed -n "/${connectorName}/,/^ *$/p" ${configfile} | grep "ds-cfg-ssl-cert-nickname:" | sed "s/ds-cfg-ssl-cert-nickname: //"`
	keyManagerEntry=`sed -n "/${connectorName}/,/^ *$/p" ${configfile} | grep "ds-cfg-key-manager-provider:" | sed "s/ds-cfg-key-manager-provider: //"`
		if [ "${keyManagerEntry}" = "" -a "${connectorName}" = "dn: cn=Crypto Manager,cn=config" ]; then
			keyManagerEntry="dn: ds-cfg-backend-id=ads-truststore,cn=Backends,cn=config"
			keyStoreFileParam="ds-cfg-trust-store-file"
		elif [ "${keyManagerEntry}" = "" ]; then
			keyManagerEntry="NA"
			keyStoreFileParam="ds-cfg-trust-store-file"
		else
			keyStoreFileParam="ds-cfg-key-store-file"
		fi
#echo "keyManagerEntry -> $keyManagerEntry"
	keyStore=`sed -n "/${keyManagerEntry}/,/^ *$/p" ${configfile} | grep "${keyStoreFileParam}:" | sed "s/${keyStoreFileParam}: //" | sed "s,/, ,g" | awk -F" " '{print $NF}'`
#echo "keyStore -> $keyStore"

	# Get the actual store info/expiration
	if [ "${certNick}" != "" -a "${keyManagerEntry}" != "NA" ]; then
		if [ -s ./security/${keyStore}-list ]; then
			if [ "${extractvertype}" = "script" -o "${extractvertype}" = "powershell" ]; then
				thisCertInfo=`sed -n "/^Alias name: ${certNick}/,/^ *$/p" ./security/${keyStore}-list | grep 'Valid from' | head -1 | sed "s/Valid from: //" | sed "s/ /~/g"`
			else
				thisCertInfo=`grep "^${certNick} " ./security/${keyStore}-list | sed "s/${certNick} ,//" | sed "s/ /~/g"`
			fi

			# For debugging purposes only
			#echo "=====CERT ${certNick}=====
			#$thisCertInfo
			#=====CERT=====
			#"
		else
		# the store is empty, return
			printf "%s\n" "${connectorDisplayName}" | log 
			printf "\t\t%-12s\t%s\n" "Certificate" "${certNick}" | log 
			printf "\t\t%-12s\t%s\n" "" "Keystore (./security/${keyStore}-list) is empty or not available, skipping this certificate" | log 
			return
		fi
	else
		printf "%s\n" "${connectorDisplayName}" | log 
		printf "\t\t%-12s\t%s\n" "Certificate" "Cert info not available, skipping this certificate" | log 
		return
	fi

	thisCertExp=`echo ${thisCertInfo} | sed "s/,/ /" | awk '{print $1}' | sed "s/~/ /g"`
	thisCertExpYear=`echo ${thisCertInfo} | sed "s/,/ /" | awk '{print $1}' | sed "s/~/ /g" | awk -F" " '{print $NF}'`
        thisYear=`date "+%Y"`

			# For debugging purposes only
			#echo "BEGIN DEBUG"
			#echo "thisCertInfo ($thisCertInfo)"
			#echo "Keystore (./security/${keyStore}-list)"
			#echo "thisYear -> ($thisYear)"
			#echo "thisCertExpYear -> ($thisCertExpYear)"
			#echo "END DEBUG\n"

		if [ "${thisCertExpYear}" -le "${thisYear}" ]; then
			alerts="${alerts} Cert:${certNick}~expired~or~expiring~soon.KBI500"
			addin=" *"
		fi


		if [ "${thisCertExp}" != "" ]; then
			thisCertExp="From ${thisCertExp}${addin}"
		else
			thisCertExp="Unknown"
		fi
	thisCertType=`echo ${thisCertInfo} | sed "s/,/ /g" | awk -F" " '{print $NF}' | sed "s/~/ /g" | sed "s/^ //"`
		if [ "${thisCertType}" = "" ]; then
			thisCertType="Unknown"
		fi
	printf "%s\n" "${connectorDisplayName}" | log 
	printf "\t\t%-12s\t%s\n" "Certificate" "${certNick}" | log 
	printf "\t\t%-12s\t%s\n" "Expiration" "${thisCertExp}" | log
	printf "\t\t%-12s\t%s" "Type" "${thisCertType}" | log
	if [ "${thisCertExpYear}" = "${thisYear}" -o "${thisCertExpYear}" -lt "${thisYear}" ]; then
		printf "\n\n" | log
		printf "\t%s" "${red}Alert: The ${certNick} certificate is expired or expires soon${nocolor}" | log
		addKB "KBI500"
	fi
printf "\n" | log

	connectorName=''
	keyManagerEntry=''
	StoreFileParam=''
	connectorDisplayName=''
	thisCertExp=''
	thisCertType=''
	addin=''
}

printPasswordPolicyInfo()
{
printf "%s\n" "---------------------------------------" | log
printf "%s\n" "PASSWORD POLICY INFORMATION:" | log
printf "\n%s\n" "${passwordpolicyinfo}" | log
printf "%s\n\n" "---------------------------------------" | log
printf "%s\t%s\n" "Note:" "Password Policies other than \"Root Password Policy\" using Bcrypt, PBKDF2 or PKCS5S2 are flagged" | log

	passwordPolicies=`grep ',cn=Password Policies,cn=config' ${configfile} | grep ^dn: | sed "s/,cn=Password Policies,cn=config//" | sed "s/^dn: //" | sed "s/cn=//" | sed "s/ /~/g"`

	# Get the longest policy name
	longestPassPolName=0
	for passwordPolicy in ${passwordPolicies}; do
		thisLen=${#passwordPolicy}
		if [ "${thisLen}" -gt "${longestPassPolName}" ]; then
			longestPassPolName=${thisLen}
		fi
	done
	# Get the longest storage schemes
	for passwordPolicy in ${passwordPolicies}; do
		passwordPolicyName=`echo ${passwordPolicy} | sed "s/~/ /g"`
		passwordStorageSchemes=`sed -n "/dn: cn=${passwordPolicyName},cn=Password Policies,cn=config/,/^ *$/p" ${configfile} | grep "ds-cfg-default-password-storage-scheme: " | sed "s/ds-cfg-default-password-storage-scheme: //" | sed "s/,cn=Password Storage Schemes,cn=config//; s/,cn=password storage schemes,cn=config//" | sed "s/,cn=password storage schemes,cn=config//" | sed "s/cn=//" | sed "s/ /~/g" | perl -p -e 's/\r\n|\n|\r/\n/g' | sed "s/ /~/g"`
		passwordStorageSchemes=`echo ${passwordStorageSchemes} | perl -p -e 's/\r\n|\n|\r/\n/g' | sed "s/ /~/g"`

		for passwordStorageScheme in $passwordStorageSchemes; do
			thisLen=${#passwordStorageScheme}
			if [ "${thisLen}" -gt "${longestStorageSchemeName}" ]; then
				longestStorageSchemeName=${thisLen}
			fi
		done
	done
		if [ "${longestStorageSchemeName}" -lt "22" ]; then
			longestStorageSchemeName=21
		fi
	longestPassPolName=`expr ${longestPassPolName} + 2`; getDashes "${longestPassPolName}"; idash1=${dashes}
	longestPassAttrName="18" ; getDashes "${longestPassAttrName}"; idash2=${dashes}
	longestStorageSchemeName=`expr ${longestStorageSchemeName} + 3`; getDashes "${longestStorageSchemeName}"; idash3=${dashes}

	# Print the policy table
	printf "\n%-${longestPassPolName}s: %-18s: %-${longestStorageSchemeName}s: %-26s: %-6s\n" "Password Policy" "Password Attr" "Default Storage Scheme" "Deprecated Storage Scheme" "Cost"| log
	printf "%-${longestPassPolName}s:%-18s:%-${longestStorageSchemeName}s:%-26s:%-6s\n" "${idash1}" "${idash2}-" "${idash3}-" "---------------------------" "------" | log

	for passwordPolicy in ${passwordPolicies}; do
		deprecatedPasswordStorageScheme=""
		passwordPolicyName=`echo ${passwordPolicy} | sed "s/~/ /g"`
		passwordStorageScheme=`sed -n "/dn: cn=${passwordPolicyName},cn=Password Policies,cn=config/,/^ *$/p" ${configfile} | grep "ds-cfg-default-password-storage-scheme: " | sed "s/ds-cfg-default-password-storage-scheme: //" | sed "s/,cn=Password Storage Schemes,cn=config//; s/,cn=password storage schemes,cn=config//" | sed "s/cn=//" | sed "s/ /~/g" | perl -p -e 's/\r\n|\n|\r/\n/g'`
		passwordStorageScheme=`echo ${passwordStorageScheme} | perl -p -e 's/\r\n|\n|\r/\n/g' | sed "s/~/ /g"`

		heavyScheme=`echo "${passwordStorageScheme}" | grep -iE 'BCRYPT|PBKDF2|PKCS5S2'`
		if [ $? = 0 ]; then
			heavySchemeAlertDisplay="*"

		   	#heavySchemes"BCRYPT PBKDF2 PKCS5S2"
			heavySchemeCheck=`echo "${passwordStorageScheme}" | grep -i 'BCRYPT'`
			if [ $? = 0 ]; then
				heavySchemeName="Bcrypt"
				heavySchemeAttr="ds-cfg-bcrypt-cost"
			fi
			heavySchemeCheck=`echo "${passwordStorageScheme}" | grep -i 'PBKDF2'`
			if [ $? = 0 ]; then
				heavySchemeName="PBKDF2"
				heavySchemeAttr="ds-cfg-pbkdf2-iterations"
			fi
			heavySchemeCheck=`echo "${passwordStorageScheme}" | grep -i 'PKCS5S2'`
			if [ $? = 0 ]; then
				heavySchemeName="PKCS5S2"
				heavySchemeAttr="NA"
			fi
				#passwordPolicyName=`echo ${passwordPolicy} | sed "s//~/g"`
				alerts="${alerts} Policies:Password~Policy~using~${heavySchemeName}~found~(${passwordPolicy}).KBI400"
				addKB "KBI400"
				#passwordPolicyName=`echo ${passwordPolicy} | sed "s/~/ /g"`
				passwordStorageSchemeCost=`sed -n "/dn: cn=${heavySchemeName},cn=Password Storage Schemes,cn=config/,/^ *$/p" ${configfile} | grep "${heavySchemeAttr}: " | awk '{print $2}'`

				if [ "${passwordStorageSchemeCost}" = "" -a "${heavySchemeName}" = "Bcrypt" ]; then
					passwordStorageSchemeCost=12
				fi
				if [ "${passwordStorageSchemeCost}" = "" -a "${heavySchemeName}" = "PBKDF2" ]; then
					passwordStorageSchemeCost=10000
				fi
				if [ "${passwordStorageSchemeCost}" = "" -a "${heavySchemeName}" = "PKCS5S2" ]; then
					passwordStorageSchemeCost="10000"
				fi
				if [ "${heavySchemeNames}" = "" ]; then
					heavySchemeNames="${heavySchemeName}"
				else
					heavySchemeNames="${heavySchemeNames}, ${heavySchemeName}"
				fi
		else
			heavySchemeAlertDisplay=""
			passwordStorageSchemeCost="-"
		fi

		passwordAttr=`sed -n "/dn: cn=${passwordPolicyName},cn=Password Policies,cn=config/,/^ *$/p" ${configfile} | grep "ds-cfg-password-attribute: " | awk '{print $2}'`
		deprecatedPasswordStorageSchemes=`sed -n "/dn: cn=${passwordPolicyName},cn=Password Policies,cn=config/,/^ *$/p" ${configfile} | grep "ds-cfg-deprecated-password-storage-scheme: " | awk '{print $2}' | sed "s/cn=//" | sed "s/,/ /" | awk '{print $1}'`
			if [ "${deprecatedPasswordStorageSchemes}" = "" ]; then
				deprecatedPasswordStorageScheme="-"
			else
				for thisScheme in ${deprecatedPasswordStorageSchemes}; do
					deprecatedPasswordStorageScheme="${deprecatedPasswordStorageScheme} ${thisScheme}" 
				done
				deprecatedPasswordStorageScheme=`echo "${deprecatedPasswordStorageScheme}" | sed "s/^ //"`
			fi

		printf "%-${longestPassPolName}s: %-18s: %-${longestStorageSchemeName}s: %-26s: %-6s\n" "${passwordPolicyName}" "${passwordAttr}" "${passwordStorageScheme} ${heavySchemeAlertDisplay}" "${deprecatedPasswordStorageScheme}" "${passwordStorageSchemeCost}" | log

		passwordStorageSchemeCost=''
		heavyScheme=''
	done

	if [ "${heavySchemeName}" != "" ]; then
		printf "\n\t%s" "${red}Alert: Heavy impact Password Storage Scheme in use - ${heavySchemeNames}${nocolor}" | log
		healthScore "PasswordPolicy" "RED"
	fi
	if [ "${heavySchemeName}" != "" ]; then
		printf "\n\t%s\n" "${yellow}Warning: DS 5.0 and higher uses PBKDF2 for the \"Root Password Policy\", beware of applications using Root DNs${nocolor}" | log
		alerts="${alerts} Policies:DS~5.0~and~higher~uses~PBKDF2~for~the~\"Root~Password~Policy\",~beware~of~applications~using~Root~DNs"
	fi
	printf "%s\n\n" "" | log
	if [ "${PasswordPolicy}" != "RED" -o "${PasswordPolicy}" != "YELLOW" ]; then
		healthScore "PasswordPolicy" "GREEN"
	fi
}

getCertInfo()
{
printf "%s\n" "---------------------------------------" | log
printf "%s\n" "CERTIFICATE INFORMATION:" | log
printf "\n%s\n" "${certificateinfo}" | log
printf "%s\n" "---------------------------------------" | log

	certNames=`grep ds-cfg-ssl-cert-nickname ${configfile} | sort -u | awk '{print $2}'`
	longestCertName=0
	for certName in ${certNames}; do
		thisLen=${#certName}
		if [ "${thisLen}" -gt "${longestCertName}" ]; then
			longestCertName=${thisLen}
		fi
	done

	# Get the ADS cert info
	printCertInfo "dn: cn=Crypto Manager,cn=config" 					"ds-cfg-trust-store-file" 			"Crypto Manager"
	printCertInfo "dn: cn=Administration Connector,cn=config" 				"ds-cfg-key-store-file" 			"Administration Connector"
	printCertInfo "dn: cn=HTTP Connection Handler,cn=Connection Handlers,cn=config" 	"ds-cfg-key-store-file"				"HTTP Connection Handler"
	printCertInfo "dn: cn=LDAP Connection Handler,cn=LDAPS Connection Handler,cn=config" 	"ds-cfg-key-store-file"				"cn=LDAP Connection Handler"
	printCertInfo "dn: cn=LDAPS Connection Handler,cn=[Cc]onnection [Hh]andlers,cn=config" 	"ds-cfg-key-store-file"				"cn=LDAPS Connection Handler"
	printf "\n" | log
	if [ "${Certificates}" != "RED" -o "${Certificates}" != "YELLOW" ]; then
		healthScore "Certificates" "GREEN"
	fi
}

stackReports()
{
	topFiles=`ls | grep top | wc -l | awk '{print $1}'`
	hctFiles=`ls | grep high-cpu-threads | wc -l | awk '{print $1}'`
		if [ "${hctFiles}" -gt "0" ]; then
			rm high-cpu-threads*
		fi

	highCpuWaterMark=0
	highestCpuThread=0
	topTotal=0
for (( c=1; c<=${topFiles}; c++ )); do
	ADDIN=''
	topTotal=0

	printf "%s\t" "   - Sample ${c}:" | tee -ai ../config/extract-report.log
	top="top-${c}.txt"
	topLines=`sed -n '/PID USER/,/^ *$/p' ${top} | sed "s/ /~/g" | grep -vE "PID|Total"`

	for topLine in ${topLines}; do
		topPid=`echo ${topLine} | sed "s/~/ /g" | awk '{print $1}'`
		topCPU=`echo ${topLine} | sed "s/~/ /g" | awk '{print $9}'`
		baseCPU=`echo ${topCPU} | cut -c1`

		if [ "${baseCPU}" -gt "0" ]; then
			echo "${topCPU}" >> cpuPercentages.tmp
		fi

		n=0
		hex=0
		hex=`echo "obase=16;ibase=10; ${topPid}" | bc`
		hex=`echo $hex | tr [:upper:] [:lower:]`
		nid="0x${hex}"

		#baseCPU=`echo ${topCPU} | cut -c1`

		if [ "${baseCPU}" -gt "0" ]; then
			if [ "${baseCPU}" -gt "0" -a "${jstackTestFile}" != "" ]; then
				echo "CPU = ${topCPU} % (nid=$nid)" >> high-cpu-threads-${c}.out
				sed -n "/nid=${nid}/,/^ *$/p" jstackdump*-${c}.txt >> high-cpu-threads-${c}.out
			fi

			# Add up all percentages for a total
			thisCpu=`echo ${topCPU} | sed "s/\..*$//"`
			topTotal=`expr ${topTotal} + ${thisCpu}`
		fi
	done
	if [ -s ./high-cpu-threads-${c}.out ]; then
		lowCPU=`cat ./cpuPercentages.tmp | sort -u --general-numeric-sort | head -1`
		highCPU=`cat ./cpuPercentages.tmp | sort -u --general-numeric-sort | tail -1`
		highCpuWaterMark=`echo ${highCPU} | sed "s/\..*$//"`
		#topTotal=`expr ${topTotal} + ${highCpuWaterMark}`
			if [ "${highCpuWaterMark}" -ge "25" ]; then
				if [ "${highCpuWaterMark}" -gt "${highestCpuThread}" ]; then
					highestCpuThread=${highCpuWaterMark}
				fi
				if [ "${c}" = "10" -a "${highestCpuThread}" -gt "25" ]; then
					alerts="${alerts} Process:High~CPU~Threads~found~(${highestCpuThread}~%)"
				fi
				ADDIN=" *"
			fi
		printf "%s \t%s\n" "CPU Range: ${lowCPU}% to ${highCPU}%" "Total Process CPU: ${topTotal}%" | tee -ai ../config/extract-report.log

		rm ./cpuPercentages.tmp
		highCpuThreadsFound=1
	else
		printf "%s\t\t\t\t%s\n" " " "0% cpu used" | tee -ai ../config/extract-report.log
	fi
		#topTotal=0
done
	printf "\n%s\n" "   * Total Process CPU = total cpu used by all threads in that stack"
	printf "                                            \r\b" | tee -ai ../config/extract-report.log
	otherInfoDisplayed=1
	return $highCpuThreadsFound
}

renameJstacks()
{
	printf "%s" "   - Renaming stack files               "
	cd ../processStats
	for (( c=1; c<=9; c++ )); do
		thisFile=`ls jstackdump*-0${c} | sed "s/-0${c}//"`
		mv ${thisFile}-0${c} ${thisFile}-${c}.txt 
	done
		mv ${thisFile}-00 ${thisFile}-10.txt 
	cd ../config
	sleep 2
	printf "                                                                  \r\b"
}

splitJstacks()
{

filedate=`date "+%Y%m%d-%H%M%S"`
pattern=`grep -E '20[0-9][0-9]-' ${serverOutFile} | awk '{print $1}' | sed "s/-/ /" | awk '{print $1}' | sort -u`
pattern=`grep -E '^20[0-9][0-9]-' ${serverOutFile} | awk '{print $1}' | sort -u`

(cd ../logs; csplit -s -f "jstackdump$filedate-" ${serverOutFile} "/....-..-.. ..:..:../" {8} )
if [ $? = 0 ]; then
	echo "Jstack files created" | log
	(cd ../logs; mv ./jstackdump* ../processStats )
	sleep 2
	printf "                                                                  \r\b"
	renameJstacks
	otherInfoDisplayed=1
else
	echo "fail" | log
fi
	jstackTestFile=`ls -1 ../processStats/ | grep jstackdump | head -1`
}

checkProdMode()
{
  if [ "${shortbaseversion}" -ge "4" ]; then
	if [ "${prodModeCheck1}" = "1" -a "${prodModeCheck2}" = "1" ]; then
		checkACIs=`grep -c aci: ${configfile}`
		if [ "${checkACIs}" = "6" ]; then
			printf "%-24s\t%-13s\n" " ${yellow}* Alert: Production Mode" "enabled${nocolor}" | log
			alerts="${alerts} Encryption:Production~Mode~enabled"
		else
			printf "%-18s\t\t%-13s\n" " * Production Mode" "Not enabled." | log
		fi
	else
		printf "%-18s\t\t%-13s\n" " * Production Mode" "Not enabled." | log
	fi
		otherInfoDisplayed=1
  fi
}

checkJstacks()
{
  if [ -d ../processStats ]; then
	jstackTestFile=`ls -1 ../processStats/ | grep jstackdump | head -1`
	topTestFile=`ls -1 ../processStats/ | grep top | head -1`
	if [ ! -s ../processStats/${jstackTestFile} ]; then

		printf "%s\t\t\t%s\n" " * Stacks files" "Missing or zero bytes" | log
			rm ../processStats/jstackdump*
		if [ -s ../logs/server.out ]; then
			serverOutFile='../logs/server.out'
		fi
		if [ -s ../logs/server.out.stacks ]; then
			serverOutFile='../logs/server.out.stacks'
		fi
		if [ "${serverOutFile}" = "" ]; then
			printf "%s\n" "   - server.out not found (${embeddedFound})" | log
			return
		fi
			if [ -s ${serverOutFile} ]; then
				serverOutFileName=`basename "${serverOutFile}"`
				serverOutStacks=`grep -c 'Full thread dump' ${serverOutFile}`
				if [ "${serverOutStacks}" -gt "0" ]; then
					printf "%s\t" " * Splitting ${serverOutFileName}" | log
					splitJstacks
					otherInfoDisplayed=1
				else
					printf "%s\t\t\t%s\n" " * Stack dumps" "Not found in the server.out" | log
					jstackTestFile=""
				fi
			else
				printf "%s\n" " - server.out not found" | log
			fi
	fi
  fi
	if [ "${jstackTestFile}" != "" -a "${topTestFile}" != "" ]; then
		printf "%s\t%s\n" " * Stack+top files found " "Creating high-cpu-thread reports (in ../processStats)" | log
	elif [ "${jstackTestFile}" = "" -a "${topTestFile}" != "" ]; then
		printf "%s\t%s\n" " * Stack files not found." "Not creating high-cpu-thread reports" | log
	else
		printf "%s\t%s\n" " * Stack+top files not found." "Not creating high-cpu-thread reports" | log
	fi
	if [ -s ../processStats/${topTestFile} -a "${topTestFile}" != "" ]; then
		printf "%s\t\t%s\n" " * Top files found" "Showing CPU usage range" | log
	fi

	if [ "${topTestFile}" != "" ]; then
	printf "\n" ""
		cd ../processStats
		stackReports
		cd ../config
	else
		printf "%s\t\t%s\n" " * Top files not found." "Not showing CPU usage or creating high-cpu-thread reports" | log
	fi
}

diffTheStacks()
{
	cd ../processStats
	#jstacks=`ls jstackdump* | grep -v report`
	jstacks=`ls jstackdump* | grep -v report | sed "s/-/ /" | awk '{print $1}' | sort -u`

	echo
	i=1
	lastSample=1
	differenceFound=0
for (( c=0; c<=9; c++ )); do
	currentSample=$jstack

	if [ "$lastSample" != "1" ];then
		c2=`expr $c + 1`

		# jstackdump20190510-151949-1.txt
		lastSample=`ls ${jstacks}-*-${c}.txt`
		currentSample=`ls ${jstacks}-*-${c2}.txt`

		wc=`wc -l ${lastSample} | awk '{print $1}'`; wc=`expr ${wc} - 1`
		tail -${wc} ${lastSample} > ${lastSample}.tmp
		wc=`wc -l ${currentSample} | awk '{print $1}'`; wc=`expr ${wc} - 1`
		tail -${wc} ${currentSample} > ${currentSample}.tmp

		lastSampleIndex=`echo ${lastSample} | sed "s/\.txt//" | sed "s/-/ /g" | awk '{print $2 "-" $3}'`
		currentSampleIndex=`echo ${currentSample} | sed "s/\.txt//" | sed "s/-/ /g" | awk '{print $2 "-" $3}'`

		(cd ../config; printf "%-20s vs %-16s\t%s" "   - Sample ${lastSampleIndex}" "Sample ${currentSampleIndex}" | log )

		pTaken=1
		fileDiffs=`diff ${lastSample}.tmp ${currentSample}.tmp > jstackdiff.${lastSampleIndex}-${currentSampleIndex}`
		if [ $? = 1 ]; then
			(cd ../config; echo "process changing" | log )
			differenceFound=1
		else
			(cd ../config; echo "no change" | log )
			rm jstackdiff.${lastSampleIndex}-${currentSampleIndex}
		fi
	fi
	if [ "$pTaken" = "1" -o "$i" = "1" ];then
		lastSample="${jstacks}-*-${c}.txt"
	fi
	i=`expr $i + 1`
done
	rm *.tmp
	cd ../config
}

printStackCpuInfo()
{
printf "\n%s\n" "---------------------------------------" | log
printf "%s\n" "CPU USAGE INFORMATION:" | log
printf "\n%s\n" "${cpuusageinfo}" | log
printf "%s\n" "---------------------------------------" | log
	checkJstacks "2"
	if [ "${CPUUsage}" != "RED" -o "${CPUUsage}" != "YELLOW" ]; then
		healthScore "CPUUsage" "GREEN"
	fi
}

printStackDifference()
{
printf "\n%s\n" "---------------------------------------" | log
printf "%s\n" "PROCESS DIFFERENCE INFORMATION:" | log
printf "\n%s\n" "${processinfo}" | log
printf "%s\n" "---------------------------------------" | log
	if [ "${jstackTestFile}" = "" ]; then
		printf "%s\t%s\n\n" " * Stack files not found." "Not generating stack diffs" | log
		return 1
	fi

	printf "%s\t%s\n" " * Diffing ../processStats/jstackdump* files" "Creating jstackdiff.* reports (in ../processStats)" | log
	diffTheStacks
	if [ "${differenceFound}" = "1" ]; then
		printf "\n%s\n" " * Process is changing (not hung) " | log
	else
		printf "\n%s\n" " * Process could be idle or hung" | log
	fi
}

printOtherInfo()
{

printf "\n%s\n" "---------------------------------------" | log
printf "%s\n" "OTHER INFORMATION:" | log
printf "\n%s\n" "${otherinfo}" | log
printf "%s\n" "---------------------------------------" | log

	if [ `echo ${installDir} | grep opends` ]; then
		printf "%s\n" " * Embedded DJ Instance." | log
		otherInfoDisplayed=1
		embeddedFound="Embedded DJ Instance"
	fi

	checkProdMode "1"

	if [ ${ctsIndexCount} -ge "1" ]; then
		printf "%-15s\t\t\t%-19s\n" " * CTS Instance" "Cts indexes found." | log
		otherInfoDisplayed=1
	fi
	if [ ${amCfgIndexCount} -ge "1" ]; then
		printf "%-21s\t\t%-28s\n" " * AM Config Instance" "AM Config indexes found." | log
		otherInfoDisplayed=1
	fi

	if [ "${ttlEnabledIndexes}" != "NA" ]; then
		for ttlEnabledIndex in ${ttlEnabledIndexes}; do
			printf " * %-19s\t\t%-22s\n" "Time To Live enabled" "TTL Indexes found." | log
		done
		otherInfoDisplayed=1
	fi

	# display profiles
	if [ "${dsprofiles}" != "" ]; then
		for dsprofile in ${dsprofiles}; do
			dsprofile=`echo ${dsprofile} | sed "s/:/ /"`
			printf " * %-20s\t\t%s\n" "DS Profiles found" "$dsprofile" | log
		done
	fi

	if [ "${dataversion}" != "" ]; then
		dataver=`echo ${dataversion} | cut -c1-5`
		datacommit=`echo ${dataversion} | sed "s/${dataver}.//"`
		printf " * %-17s\t\t%-5s %-42s\n" "Data version" "${dataver}" "(${datacommit})" | log
	fi

	if [ "${serverType}" != "Stand Alone/Not replicated" -a "${serverType}" != "Directory Server (DS only)" -a ${ctsIndexCount} -ge "1" ]; then
		printf " * %-21s\n" "This CTS is replicated. The ${changenumberindexerattr} may be disabled to increase performance." | log
		printf "\t- %-21s\n" "Verify cn=changelog is not being used, before disabling." | log
		otherInfoDisplayed=1
	fi

	if [ "${otherInfoDisplayed}" = "" ]; then
		printf "%s" " * None"
	fi

	if [ "${OtherInfo}" != "RED" -o "${OtherInfo}" != "YELLOW" ]; then
		healthScore "OtherInfo" "GREEN"
	fi
}

printAlerts()
{

	alerts=`echo ${alerts} | sort -u`
alertnumber=0
printf "\n\n%s\n" "---------------------------------------" | log
printf "%s\n" "ALERTS ENCOUNTERED:" | log
printf "%s\n\n" "---------------------------------------" | log
	for alert in ${alerts}; do
		alertnumber=`expr ${alertnumber} + 1`
		alertcategory=`echo ${alert} | sed "s/:/ /" | awk '{print $1}'`
		alertmsg=`echo ${alert} | sed "s/:/ /" | awk '{print $2}'`
		alertmsg=`echo ${alertmsg} | sed "s/~/ /g"`

		# find and display related KBI's
		kbi=`echo ${alertmsg} | grep 'KBI'`
		if [ $? = 0 ]; then
			kbi=`echo ${alertmsg} | sed -E "s/^.*(KBI.*)/\1/"`
			debug "kbi=${kbi}"
			kb=`grep "${kbi}=" $0 | sed "s/${kbi}=//" | sed "s/\"//g" | awk '{print $1}'`
			debug "kb=${kb}"

			kbiTest=`echo ${kb} | grep 'OPENDJ-'`
			if [ $? = 0 ]; then
				alertmsg=`echo ${alertmsg} | sed "s/${kbi}/ See Jira ${kb}/"`
			else
				alertmsg=`echo ${alertmsg} | sed "s/${kbi}/ See KB Article ${kb}/"`
			fi
		fi
		printf " [%s]\t%-12s %s\n" "${alertnumber}" "${alertcategory}:" "${alertmsg}" | log
	done

	if [ "${alertnumber}" = "0" ]; then
		printf " [%s]\t%-12s %s\n" "0" "No alerts encountered" | log
	else
		printf "\n%s\n" "See all reported values with an asterisk (*)" | log
	fi

	fatalalerts=`echo ${fatalalerts} | sort -u`
fatalalertnumber=0
printf "\n\n%s\n" "---------------------------------------" | log
printf "%s\n" "FATAL ERRORS:" | log
printf "%s\n\n" "---------------------------------------" | log
	for fatalalert in ${fatalalerts}; do
		fatalalertnumber=`expr ${fatalalertnumber} + 1`
		fatalalertcategory=`echo ${fatalalert} | sed "s/:/ /" | awk '{print $1}'`
		fatalalertmsg=`echo ${fatalalert} | sed "s/:/ /" | awk '{print $2}'`
		fatalalertmsg=`echo ${fatalalertmsg} | sed "s/~/ /g"`

		# find and display related KBI's
		kbi=`echo ${fatalalertmsg} | grep 'KBI'`
		if [ $? = 0 ]; then
			kbi=`echo ${fatalalertmsg} | sed -E "s/^.*(KBI.*)/\1/"`
			debug "kbi=${kbi}"
			kb=`grep "${kbi}=" $0 | sed "s/${kbi}=//" | sed "s/\"//g" | awk '{print $1}'`
			debug "kb=${kb}"

			kbiTest=`echo ${kb} | grep 'OPENDJ-'`
			if [ $? = 0 ]; then
				fatalalertmsg=`echo ${fatalalertmsg} | sed "s/${kbi}/ See Jira ${kb}/"`
			else
				fatalalertmsg=`echo ${fatalalertmsg} | sed "s/${kbi}/ See KB Article ${kb}/"`
			fi
		fi
		printf " [%s]\t%-12s %s\n" "${fatalalertnumber}" "${fatalalertcategory}:" "${fatalalertmsg}" | log
	done

	if [ "${fatalalertnumber}" = "0" ]; then
		printf " [%s]\t%-12s %s\n" "0" "No fatal errors encountered" | log
	else
		printf "\n%s\n" "See all reported values with an asterisk (*)" | log
	fi

kbasalertnumber=0
printf "\n\n%s\n" "---------------------------------------" | log
printf "%s\n" "KNOWLEDGE ARTICLES:" | log
printf "%s\n\n" "---------------------------------------" | log

	debug "sorted kbas->[$kbas]"

	# get the lengths for each KB message for proper formatting
	msgLen=0
	for kba in ${kbas}; do
		kbi=`grep "^${kba}=" $0 | sed "s/${kba}=//" | sed "s/\"//g" | awk '{print $1}'`
		kbimessage=`grep "${kba}=" $0 | sed "s/\"//g" | sed "s/${kba}=${kbi} //"`
		calcLen "$kbimessage"
			if [ "${mylen}" -gt "${msgLen}" ]; then
				msgLen=$mylen
			fi
	done

	for kba in ${kbas}; do
		debug "KBA->$kba"
		kbasalertnumber=`expr ${kbasalertnumber} + 1`
		kbi=`grep "^${kba}=" $0 | sed "s/${kba}=//" | sed "s/\"//g" | awk '{print $1}'`
		debug "KBURL->$kburl"
		debug "KBI->$kbi"
		debug "KBI=KBA->${kba}=${kbi}"
		kbimessage=`grep "${kba}=" $0 | sed "s/\"//g" | sed "s/${kba}=${kbi} //"`
		debug "KBIMESSAGE->$kbimessage"

		basicversion=`echo ${compactversion} | cut -c1-2`

		msgUrl=`grep "^${kba}URL${basicversion}=" $0 | sed "s/${kba}URL${basicversion}=//" | sed "s/\"//g"`
		debug "msgUrl->$msgUrl"
		if [ "${msgUrl}" = "" ]; then
			kbUrlCheck=`echo "${kbi}" | grep "OPENDJ"`
			if [ $? = 0 ]; then
				msgUrl=${jurl}${kbi}
			else
				msgUrl=${kburl}${kbi}
			fi
		fi
		printf " [%s]\t%-${msgLen}s\t%s\n" "${kbasalertnumber}" "${kbimessage}" "(${msgUrl})" | log
	done

	if [ "${kbasalertnumber}" = "0" ]; then
		printf " [%s]\t%-12s %s\n" "0" "No KB messages to display" | log
	fi
}

printHealthStatus()
{

if [ "${experimental}" = "1" ]; then
printf "\n\n%s\n" "---------------------------------------" | log
printf "%s\n" "HEALTH STATUS: (experimental)" | log
printf "\n%s\n" "${healthstatusinfo}" | log
printf "%s\n\n" "---------------------------------------" | log
printf "%-6s\t\t%s\n" " ${green}GREEN${nocolor}" "No issues encountered" | log
printf "%-6s\t\t%s\n" " ${yellow}YELLOW${nocolor}" "Minor issues encountered, may need addressing" | log
printf "%-6s\t\t%s\n" " ${red}RED${nocolor}" "Issues encountered, needs addressing" | log
printf "%s\n" "" | log

	# get the lengths for each KB message for proper formatting
	msgLen=0
	for sectionScore in ${healthScores}; do
		sectionName=`echo ${sectionScore} | sed "s/=/ /" |awk '{print $1}'`
		calcLen "$sectionName"
			if [ "${mylen}" -gt "${msgLen}" ]; then
				secLen=$mylen
			fi
	done

	hsalertnumber=0
	for healthSection in ${healthScores}; do
		hsalertnumber=`expr ${hsalertnumber} + 1`
		sectionName=`echo ${healthSection} | sed "s/=/ /" |awk '{print $1}' | sed "s/-/ /"`
		sectionScore=`echo ${healthSection} | sed "s/=/ /" |awk '{print $2}'`
		if [ "${sectionScore}" = "RED" ]; then
			thisColor="${red}"
		elif [ "${sectionScore}" = "YELLOW" ]; then
			thisColor="${yellow}"
		else
			thisColor="${green}"
		fi

		printf " [%s]\t%-20s\t\t%s\n" "${hsalertnumber}" "${sectionName}" "(${thisColor}${sectionScore}${nocolor})" | log
	done
fi
}

header
printServerInfo
printBackends
printIndexes
printReplicaInfo
printPasswordPolicyInfo
getCertInfo
getJVMInfo
printStackCpuInfo
printStackDifference
printOtherInfo
printAlerts
printHealthStatus

	printf "\n\n%s\n" "---------------------------------------" | log
	printf "%s\n" "Report saved in \"extract-report.log\""
if [ "${highCpuThreadsFound}" = "1" ]; then
	(cd ..; zip -rpq extract-report.zip  config/extract-report.log processStats/high-cpu-threads-*.out )
	printf "%s\n\n" "Report + high-cpu-threads reports saved in \"extract-report.zip\""
fi

