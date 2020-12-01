#!/bin/sh
# extractor 2.3.3
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
#       Copyright 2018-2020 ForgeRock AS.

version="2.3.3"
copyright="Copyright 2018-2020 ForgeRock AS."
tab=0
btab=0
printedbackend=0
totaldbcache=0
totaldbcachepct=0
cachePercent=""
totaldbcachesz=0
totalentries=0
totalconnectioncount=0
currentbase=""
alert=""
longestIndexType=0
longestStorageSchemeName=0
heavySchemeAlertDisplay=""
entryLimitAlert=0
highCpuThreadsFound=0
blockedThreadCheck=0
debugindex=1
displayall=$2
kbas=""
healthScores=""
osType=`uname`

# the version to start EOSL checks
minimumEoslVersion="3"

# Index Types
ctsIndexes='coreToken|ds-certificate-fingerprint|ds-certificate-subject-dn'
amCfgIndexes='sunxmlkeyvalue|ds-cfg-attribute=ou'
amIdentityStoreIndexes='sun-fm-saml2-nameid-infokey|iplanet-am-user-federation-info-key|ds-cfg-attribute=memberof,'
idmRepoIndexes='fr-idm'
defaultIndexes='ds-cfg-attribute=aci|ds-cfg-attribute=cn|ds-cfg-attribute=givenName|ds-cfg-attribute=mail,|ds-cfg-attribute=member,|ds-cfg-attribute=objectClass|ds-cfg-attribute=sn|ds-cfg-attribute=telephoneNumber|ds-cfg-attribute=uid|ds-cfg-attribute=uniqueMember'
systemIndexes='ds-sync-conflict|ds-sync-hist|ds-cfg-attribute=entryUUID'

virtAttrIgnore="'entryUUID'|'member'|'uniqueMember'"

# Index Counts based on "type": cts, am-cfg, am-id-repo, idm-repo
expectedAmCfgIndexes=2
expectedIDSIndexes=2
expectedIDRIndexes=15

# Section Header summary information
serverinfo="Basic server information including Connection Handlers, Ports and Current Connection counts."
backendinfo="Displays all backends and the most relevant configuration. Also displays alerts when bad configuration is encountered."
indexinfo="Displays all index definitions, types and alerts when Excessive Index Limits are found and whether the index is default, system, custom or a cts index."
replicationinfo="Displays replica type, replication domain and configured RS's. Also displays connected DS's and RS's."
accesscontrolinfo="Displays a basic summary of all ACI's"
passwordpolicyinfo="Displays all password policies, password attributes, storage schemes and alerts when heavy weight policies are found."
certificateinfo="Displays each connection handlers certificate and their expiration date. Warns of expiring certificates."
loghandlerinfo="Displays Log Handler information"
jvminfo="Displays Java version, memory used, cpu's and all JVM based parameters. Alerts when tuning is needed"
otherinfo="Displays miscellaneous information found"
cpuusageinfo="Displays a range of CPU % for all threads used per stack as well as the overall total CPU % used."
processinfo="Displays if the process is changing over time, based on the jstacks captured."
healthstatusinfo="Displays basic health which may indicate if elements within a section need addressing (experimental)"

# Knowledge Base Indexes
# Note any Doc links for DS 5.0 must be prefaced by a 40 instead of a 50, below.
kburl='https://backstage.forgerock.com/knowledge/kb/article/'
jurl='https://bugster.forgerock.org/jira/browse/'

# SERVER INFO
KBI000="a84846841 How do I use the Support Extract tool in OpenDJ (All versions) to capture troubleshooting information?"
KBI001="a18529200#DS DS/OpenDJ release and EOSL dates"
KBI002="a90354602#support Evaluation versions are not supported"

# Connections Handers

# BACKEND INFO
KBI100="a70365000 How do I tune DS/OpenDJ (All versions) process sizes: JVM heap and database cache?"
KBI101="a28635900#high High index entry limits"
KBI102="OPENDJ-5137 Reading compressed or encrypted entries fails to close the InflaterInputStream"
KBI103="a49979000 How do I tune the DS/OpenDJ (All versions) database file cache?"
KBI104="a91168317 How do I check if a backend is online in DS/OpenDJ (All versions)?"
KBI105="shared-cache JE Shared Cache Enabled"
KBI105URL65="https://backstage.forgerock.com/docs/ds/6.5/configref/#objects-global-je-backend-shared-cache-enabled"
KBI106="a42329982 Backend goes offline due to Latch timeouts in DS (All versions) and OpenDJ 3.5.2, 3.5.3"
KBI107="a91168317 How do I check if a backend is online in DS/OpenDJ (All versions)?"


# INDEX INFO
KBI200="a28635900#high High index entry limits"
KBI201="a46097400 How do I rebuild indexes in DS/OpenDJ (All versions)?"
KBI202="xxxxxxxxx Reserved for MISSING SYSTEM INDEX alerts"
KBI203="Virtual-attributes-must~not~be~indexed Virtual attributes must not be indexed"
KBI203URL30="https://backstage.forgerock.com/docs/opendj/3/server-dev-guide/#virtual-attributes"
KBI203URL35="https://backstage.forgerock.com/docs/opendj/3.5/server-dev-guide/#virtual-attributes"
KBI203URL50="https://backstage.forgerock.com/docs/ds/5/dev-guide/#virtual-attributes"
KBI203URL55="https://backstage.forgerock.com/docs/ds/5.5/dev-guide/#virtual-attributes"
KBI203URL60="https://backstage.forgerock.com/docs/ds/6/dev-guide/#virtual-attributes"
KBI203URL65="https://backstage.forgerock.com/docs/ds/6.5/dev-guide/index.html#virtual-attributes"

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

KBI303="a54492144 How do I troubleshoot replication issues in DS/OpenDJ (All versions)?"

# PASSWORD POLICY INFO
KBI400="Password-Storage-Warning. Password Storage Warning."
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

KBI603="a54695000 Garbage-First Garbage Collector Tuning"
KBI603URL65="https://docs.oracle.com/javase/9/gctuning/garbage-first-garbage-collector-tuning.htm#JSGCT-GUID-90E30ACA-8040-432E-B3A0-1E0440AB556A"

KBI609="a50989482 How do I disable TLS 1.3 when running DS 6.5 with Java 11?"
KBI610="OPENDJ-5260 Grizzly pre-allocates a useless MemoryManager"

KBI611="JVM-Codecache-Tuning. JVM Codecache Tuning."
KBI611URL40="https://docs.oracle.com/javase/8/embedded/develop-apps-platforms/codecache.htm"
KBI611URL55="https://docs.oracle.com/javase/8/embedded/develop-apps-platforms/codecache.htm"
KBI611URL60="https://docs.oracle.com/javase/8/embedded/develop-apps-platforms/codecache.htm"
KBI611URL65="https://docs.oracle.com/javase/8/embedded/develop-apps-platforms/codecache.htm"

KBI612="perf-java -XX:TieredStopAtLevel=1 is for client tools only. Performance may suffer!"
KBI612URL65="https://backstage.forgerock.com/docs/ds/6.5/admin-guide/#perf-java"
KBI612URL70="https://backstage.forgerock.com/docs/ds/7/maintenance-guide/tuning.html#perf-java"

# HIGH CPU USAGE
KBI700="a34827000 How do I collect data for troubleshooting high CPU utilization on DS/OpenDJ servers?"
KBI701="a52327300 Unindexed searches causing slow searches and poor performance on DS/OpenDJ (All versions) server"

# ACI CONTROL INFO
KBI800="base64-1 Encode and Decode Base64 Strings"
KBI800URL40="https://backstage.forgerock.com/docs/ds/5/reference/index.html#base64-1"
KBI800URL55="https://backstage.forgerock.com/docs/ds/5.5/reference/index.html#base64-1"
KBI800URL60="https://backstage.forgerock.com/docs/ds/6/reference/index.html#base64-1"
KBI800URL65="https://backstage.forgerock.com/docs/ds/6.5/reference/index.html#base64-1"
KBI800URL70="https://backstage.forgerock.com/docs/ds/6.5/reference/index.html#base64-1"


# Other Info

usage()
{
	clear
        printf "%-80s\n" "--------------------------------------------------------------------------------" 
        printf "%-62s %s\n" "FR Extractor ${version}" "Extract Extractor" 
        printf "%-80s\n" "--------------------------------------------------------------------------------"
	printf "%s\n" "Usage: $0 [-f | -r | -c | -h | -s | -e | -H]"
	printf "%s\n" ""
	printf "%s\n" "The Extractor is used to create a report on various critical and non-critical aspects from a DJ Support Extract"
	printf "%s\n" ""
	printf "%s\n" "-f, {config file}"
	printf "\t%s\n" "The full path to, and including the config.ldif file name."
	printf "\t%s\n" "Not required if used from within the config directory of an uncompressed DJ Extract"
	printf "%s\n" ""
	printf "%s\n" "-r, {save report using <filename>}"
	printf "\t%s\n" "Save the report using the supplied file name"
	printf "%s\n" ""
	printf "%s\n" "-c, {display colors}"
	printf "\t%s\n" "Display all errors using easy to identify colors"
	printf "\t%s\n" "No report file is saved with this option"
	printf "%s\n" ""
	printf "%s\n" "-h, {save report in html format}"
	printf "\t%s\n" "Display all errors using easy to identify colors"
	printf "%s\n" ""
	printf "%s\n" "-s, {redact sensitive data}"
	printf "\t%s\n" "Redacts baseDn's, Hostnames and Certificate Nicknames"
	printf "%s\n" ""
	#printf "%s\n" "-e, {display experimental options}"
	#printf "\t%s\n" "Display experimental sections"
	#printf "%s\n" ""
	printf "%s\n" "-H, {display this help}"
	printf "%s\n" ""
	exit
}

debug()
{
	if [ "${debug}" = "1" ]; then
		date=`date "+%y%m%d-%H%M%S"`
		label=$1 # the main text label to display
		printf "%-7s\t%-13s\t%s\n" "${cyan}DEBUG${debugindex}${nocolor}" "${cyan}${date}${nocolor}" "${label}"
		debugindex=`expr ${debugindex} + 1`
	fi
}

checkHtmlFormat()
{
  if [ "${usehtml}" != "1" ]; then
	HR1='--------------------------------------------------------------------------------'
	HR2='---------------------------------------'
	HR3='---------------------------------------'
	PRE=''
	PREE=''
	return
  fi
	HR1='<HR WIDTH="1000" ALIGN="LEFT">'
	HR2=''
	HR3='<HR WIDTH="1000" ALIGN="LEFT">'
	H4B='<H4>'
	H4E='</H4>'
	PREB="<PRE>"
	PREE="</PRE>\n"
	OLB="<OL>"
	OLE="</OL>"
	ULB="<UL>"
	ULE="</UL>"
	LIB="<LI>"
	LIE="</LI>"
	ITB="<I>"
	ITE="</I>"
	REDB='<font color="#FF0000">'
	REDBA='<font~color="#FF0000">'
	YELB='<font color="#FF8C00">'
	YELBA='<font~color="orange">'
	GRNB='<font color="green">'
	GRNBA='<font~color="green">'
	FEND='</font>'
	PB='<P>'
	PEND='</P>'
}


while getopts f:r:chsdeH w
do
    case $w in
    f) configFile=$OPTARG;;
    r) filename=$OPTARG;;
    c) colorDisplay=1;;
    h) usehtml=1;;
    s) hideSensitiveData=1;;
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
	cyan=`tput setaf 6`
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
	tr -d '\r' < ${monitorfile} > ${monitorfile}.ascii
	iconv --to-code ASCII ${monitorfile}.ascii > ${monitorfile}
elif [ -s ./monitor.ldif ]; then
	monitorfile='./monitor.ldif'
	majorVersion=`grep "majorVersion" ${monitorfile} | sed "s/majorVersion: //"`
	# Convert Windows CRLF files to pure ASCII
	tr -d '\r' < ${monitorfile} > ${adminfile}.ascii
	iconv --to-code ASCII ${monitorfile}.ascii > ${adminfile}
else
        printf "%s\n" "No cn=monitor files found"
	monitorfile=""
fi

if [ -s ./admin-backend.ldif ]; then
	adminfile='./admin-backend.ldif'
	# Convert Windows CRLF files to pure ASCII
	tr -d '\r' < ${adminfile} > ${adminfile}.ascii
	iconv --to-code ASCII ${adminfile}.ascii > ${adminfile}
else
        printf "%s\n" "No admin-backend.ldif files found"
	adminfile=''
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

hostname=`grep ds-cfg-server-fqdn: ${configfile} | awk '{print $2}' | sed 's/"//g'`
hostname=`grep ds-mon-system-name ../monitor/monitor.ldif | awk '{print $2}'`
	if [ "${hostname}" = '&{fqdn}' -o "${hostname}" = "" ]; then
		hostname='hostname-unavailable'
	fi
hostnameCheck=`echo "${hostname}" | grep "^\."`
	if [ "${hostnameCheck}" != "" ]; then
		hostname="illegal-hostname${hostnameCheck}"
	fi

getReportFileName()
{
pwd
	extractRunDate=`head -1 ../supportextract.log | awk '{print $1}'`
	if [ "${extractRunDate}" = "" ]; then
		extractRunDate=`date "+%y-%m-%d"`
	fi

	if [ "${usehtml}" = "1" ]; then
		fileext='html'
	else
		fileext='out'
	fi


	if [ "${filename}" != "" -a "${fqdnDisplay}" = "" ]; then
		zipfilename=${filename}-${extractRunDate}-extract-report.zip
	    filename=${filename}.${fileext}
# rmf		filename=${filename}-${extractRunDate}-extract.${fileext}
	elif [ "${filename}" = "" -a "${hideSensitiveData}" = "1" ]; then
		zipfilename=localhost-${extractRunDate}-extract-report.zip
		filename=localhost-${extractRunDate}-extract.${fileext}
	elif [ "${filename}" = "" -a "${fqdnDisplay}" != "" ]; then
		zipfilename=${fqdnDisplay}-${extractRunDate}-extract-report.zip
		filename=${fqdnDisplay}-${extractRunDate}-extract.${fileext}
	else
		zipfilename=${hostname}-${extractRunDate}-extract-report.zip
		filename=${hostname}-${extractRunDate}-extract.${fileext}
	fi
}

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
		printf "\t%-25s\t%-20s\t\t%s\n" "${label}" "${lelsevalue}" "${ldefault}" | log
	else
		printf "\t%-25s\t%-20s\t\t%s\n" "${label}" "${lvalue}" "${ldefault}" | log
	fi
}

log()
{
	if [ "${colorDisplay}" = "1" ]; then
		tee -ai /dev/null
	else
		tee -ai ${filename}
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
	thisSection=$1
	thisScore=$2
	for score in ${healthScores}; do
		if [ "${score}" = "${thisSection}=${thisScore}" -o "${score}" = "${thisSection}=RED" -o "${score}" = "${thisSection}=YELLOW" ]; then
			hsFound=1
		fi
	done
	# Check to see if there is a healthscore of yellow in case we're trying to increase the severity
	healthScoresCheck=`echo "${healthScores}" | grep "${thisSection}=YELLOW"`
	if [ "${hsFound}" = "" ]; then
		debug "Added Health Score -> ${thisSection} ${thisScore}"
		healthScores="${healthScores} ${thisSection}=${thisScore}"
		eval "${thisSection}=${thisScore}"
		debug "${thisSection}=${thisScore}"
	elif [ "${thisScore}" = "RED" -a "${healthScoresCheck}" != "" ]; then
		debug "Override (Yellow->Red)  Health Score -> ${thisSection} ${thisScore}"
		healthScores=`echo ${healthScores} |  sed "s/${thisSection}=YELLOW/${thisSection}=${thisScore}/"`
		eval "${thisSection}=${thisScore}"
		debug "${thisSection}=${thisScore}"
	else
		debug "Rejected add of Score ${thisSection}=${thisScore} to list -> ${healthScores}"
	fi
	hsFound=""
}

hide()
{
	thisVariable=$1
	thisValue=$2
	thisHash=$3
	if [ "${hideSensitiveData}" = "" ]; then
		eval "${thisVariable}=\"${thisValue}\""
		return
	fi
	debug "Hide thisVariable=[$thisValue]"
	getHashes "${thisVariable}" "${thisValue}" "${thisHash}"
}

header()
{
clear

	if [ "${usehtml}" = "1" ]; then
		printf "%-62s\n" "<!DOCTYPE HTML>" | log
		printf "%-62s\n" "<HEAD>" | log
		printf "%-62s\n" "<TITLE>Extract Report version ${version}</TITLE>" | log
		printf "%-62s\n" "</HEAD>" | log
		printf "%-62s\n" "<BODY BGCOLOR=\"#D3D3D3\">" | log
		printf "%-62s\n" "${HR1}" | log
		printf "%-62s\n" "<TABLE BORDER=0 WIDTH=\"1000\">" | log
		printf "%-62s\n" "<TR>" | log
		printf "%-62s\n" "<TD COLSPAN=\"100\" ALIGN=\"LEFT\"><H4>ForgeRock Extractor ${version}</H4></TD>" | log
		printf "%-62s\n" "<TD COLSPAN=\"100\" ALIGN=\"RIGHT\"><H4>Extract Report</H4></TD>" | log
		printf "%-62s\n" "</TR>" | log
		printf "%-62s\n" "</TABLE>" | log
		printf "%-62s\n" "${HR1}" | log
	else
		printf "%-80s\n" "${HR1}" | log
		printf "%-62s %s\n" "FR Extractor ${version}" "Extract Extractor" | log
		printf "%-80s\n" "${HR1}" | log
	fi
	if [ -s ../supportextract.log ]; then
		extractverfull=`grep -i "VERSION:" ../supportextract.log | awk -F" " '{print $NF}'`
		extractvertype=`grep -i "VERSION:" ../supportextract.log | awk -F" " '{print $NF}' | sed "s/-/ /" | awk '{print $2}'`
		extractdate=`head -1 ../supportextract.log | awk '{print $1 " " $2}'`
		if [ "${extractverfull}" = '2.0' -o "${extractverfull}" = '3.0' ]; then
			alerts="${alerts} Extract:${REDBA}${red}This~Extract~version~(${extractverfull})~has~been~EOSL'd,${nocolor}${FEND}KBI000"
			extractverfull="${REDBA}${red}${extractverfull}-java (EOSL)${nocolor}${FEND}"
			addKB "KBI000"
			healthScore "ServerInfo" "RED"
		fi
		printf "${PREB}\n" | log
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
	if [ -s ../logs/server.out ]; then
		serverOutFile='../logs/server.out'
	fi
	if [ -s ../logs/server.out.stacks ]; then
		serverOutFile='../logs/server.out.stacks'
	fi

	printf "${PREE}" | log
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
Db-Cache:  	See: db-cache-percent & db-cache-size
Enabled:  	See: enabled
iLimit:  	See: index-entry-limit
LG-Cache:  	See: db-log-filecache-size; displayed as db-log-filecache-size/total jdb files (0 if unknown)
Type:  		See: java-class aka Backend Type [JE|PDB|local]
Encryption: 	See: confidentiality-enabled
Cmprs: 		See: ds-cfg-entries-compressed" | log
printf "\n${PREE}\n" | log
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

getParameter()
{
	entry="$1"
	ldifFile="$2"
	parameter="$3"
	variable="$4"
	entry=`echo "${entry}" | sed "s,/,\.,g"`
	if [ -s ${ldifFile} ]; then
		value=`sed -n "/${entry}/,/^ *$/p" ${ldifFile} | grep "${parameter}:" | sed "s/${parameter}: //"`
	fi
	if [ "${variable}" != "" -a "${value}" != "" ]; then
		eval "${variable}=\"${value}\""
	fi
}

getBackendEntries()
{
	entries=''
	entriesaddin=''
	thisbackend="${backend}"
	thisbase="${thisbase}"

		# Capture the extact number of jdb files from the new extract versions log.
		if [ -s ../supportextract.log ]; then
			jdbFiles=`grep " ${backend}: total jdb files" ../supportextract.log | awk -F" " '{print $NF}'`
		fi
		if [ "${jdbFiles}" = "" ]; then
			jdbFiles=0
		fi

	# Use cn=monitor if available
	if [ "${monitorfile}" != "" ]; then
		if [ "${shortbaseversion}" != "6" -a "${shortbaseversion}" != "7" ]; then
			entries=`sed -n "/dn: cn=${thisbackend} Backend,cn=monitor/,/^ *$/p" ${monitorfile} | grep "ds-base-dn-entry-count:.*${thisbase}$" | awk '{print $2}'`
		else
			thisEscapedBase=`echo ${thisbase} | sed 's/,/.,/g'`
			debug "entries=sed -n \"/dn: ds-mon-base-dn=${thisEscapedBase},ds-cfg-backend-id=${thisbackend},cn=backends,cn=monitor/,/^ *$/p\""
			entries=`sed -n "/dn: ds-mon-base-dn=${thisEscapedBase},ds-cfg-backend-id=${thisbackend},cn=backends,cn=monitor/,/^ *$/p" ${monitorfile} | grep "ds-mon-base-dn-entry-count: " | awk '{print $2}'`
		fi

		# monitor.ldif is from an RS or the backend is shutdown
		if [ "${jdbFiles}" != "" ]; then
			if [ "${shortbaseversion}" -ge "6" -a "${jdbFiles}" -gt "${logcache}" ]; then
				alerts="${alerts} Backends:${REDBA}${red}${backend}~has~more~than~${logcache}~jdb~files~(${jdbFiles}).~db-log-filecache-size~is~set~to~low.${nocolor}${FEND}KBI103"
				addKB "KBI103"
				backendAlert="${REDB}${red}The ${backend} backend has more than ${logcache} jdb files (${jdbFiles}). db-log-filecache-size is set too low${nocolor}${FEND}"
				healthScore "Backends" "RED"
			fi
			if [ "${jdbFiles}" -gt "100" -a "${shortbaseversion}" -le "5" -a "${jdbFiles}" -gt "${logcache}" ]; then
				alerts="${alerts} Backends:${REDBA}${red}${backend}~has~more~than~100~jdb~files~(${jdbFiles}).~db-log-filecache-size~is~set~to~low.${nocolor}${FEND}KBI103"
				addKB "KBI103"
				backendAlert="${REDB}${red}The ${backend} backend has more than ${logcache} jdb files (${jdbFiles}). db-log-filecache-size is set too low${nocolor}${FEND}"
				healthScore "Backends" "RED"
			fi
		elif [ "${entries}" != "" ]; then
			if [ "${entries}" -gt "9500000" -a "${logcache}" = "100" -a "${shortbaseversion}" -le "5" ]; then
				entriesaddin="*"
				alerts="${alerts} Backends:${REDBA}${red}${backend}~has~more~than~9.5~million~entries.~db-log-filecache-size~is~set~to~low.${nocolor}${FEND}KBI103"
				addKB "KBI103"
				backendAlert="${REDB}${red}The ${backend} backend has more than 9.5 million entries. db-log-filecache-size is set too low${nocolor}${FEND}"
				logcache="${logcache} *"
				healthScore "Backends" "RED"
			elif [ "${entries}" -gt "100000000" -a "${logcache}" = "200" -a "${shortbaseversion}" -ge "6" ]; then
				entriesaddin="*"
				alerts="${alerts} Backends:${REDBA}${red}${backend}~has~more~than~100~million~entries.~db-log-filecache-size~is~set~to~low.${nocolor}${FEND}KBI103"
				addKB "KBI103"
				backendAlert="${REDB}${red}The ${backend} backend has more than 100 million entries. db-log-filecache-size is set too low${nocolor}${FEND}"
				logcache="${logcache} *"
				healthScore "Backends" "RED"
			elif [ "${entries}" = "0" ]; then
				entriesaddin="*"
			elif [ "${entries}" -lt "0" ]; then
				entriesaddin="*"
				alerts="${alerts} Backends:${REDBA}${backend}~entry~count~is~negative.~The~backend~may~have~encountered~an~exception${FEND}.KBI104"
				addKB "KBI104"
				backendAlert="${REDB}The ${backend} entry count is negative. The backend may have encountered an exception${FEND}"
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
				alerts="${alerts} Backends:${REDBA}${red}${backend}~has~more~than~9.5~million~entries.~db-log-filecache-size~is~set~to~low.${nocolor}${FEND}KBI103"
				backendAlert="${REDB}${red}The ${backend} backend has more than 9.5 million entries. db-log-filecache-size is set too low${nocolor}${FEND}"
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
        #mylen=`expr "$1" : '.*'`
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

getHashes()
{
	var=$1
	val=$2
	hash=$3
		if [ "${hash}" = "" ]; then
			hash="*"
		fi
	hashes=''
	myi=0
	hashlen=`echo ${val} | awk '{ print length($0) }'`
	while [ "$myi" -lt "$hashlen" ]; do
		hashes="${hashes}${hash}"
		myi=`expr ${myi} + 1`
	done
	eval "${var}=\"${hashes}\""
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
			debug "DS6+ ldapportconns = $ldapportconns"
			ldapsportconns=`sed -n "/dn: cn=LDAPS,cn=connection handlers,cn=monitor/,/^ *$/p" ${monitorfile} | grep ds-mon-active-connections-count: | awk '{print $2}' | head -1`
			debug "DS6+ ldapsportconns = $ldapsportconns"
			ldappsearches=`sed -n "/dn: cn=LDAP,cn=connection handlers,cn=monitor/,/^ *$/p" ${monitorfile} | grep ds-mon-active-persistent-searches: | awk '{print $2}' | head -1`

			# psearches
			ldappsearches=`sed -n "/dn: cn=LDAP,cn=connection handlers,cn=monitor/,/^ *$/p" ${monitorfile} | grep ds-mon-active-persistent-searches: | awk '{print $2}' | head -1`
			ldapspsearches=`sed -n "/dn: cn=LDAPS,cn=connection handlers,cn=monitor/,/^ *$/p" ${monitorfile} | grep ds-mon-active-persistent-searches: | awk '{print $2}' | head -1`

                # JDK 11 check
		ttlsv13mon=`sed -n "/dn: cn=jvm,cn=monitor/,/^ *$/p" ${monitorfile} | grep "ds-mon-jvm-supported-tls-protocols: TLSv1.3" | awk '{print $2}'`

			httpportconns=`sed -n "/cn=HTTP,cn=connection handlers,cn=monitor/,/^ *$/p" ${monitorfile} | grep ds-mon-active-connections-count: | awk '{print $2}' | head -1`
			httpsportconns=`sed -n "/cn=HTTPS,cn=connection handlers,cn=monitor/,/^ *$/p" ${monitorfile} | grep ds-mon-active-connections-count: | awk '{print $2}' | head -1`

			# Fallback to the old way if this is an upgraded instance
			# NEEDS WORK?
			if [ "${ldapportconns}" = "" -a "${ldapsportconns}" = "" ]; then
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

getJMXHandlerUse()
{
	# jmxdn looks for the java-class and backtracks to get to the dn: even if it's custom
	jmxdn=`sed -n '1!G;h;$p' ${configfile} | sed -n "/ds-cfg-java-class: org.opends.server.protocols.jmx.JmxConnectionHandler/,/dn: /p" | tail -1`
	if [ "${jmxdn}" != "" ]; then
		jmxport=`sed -n "/${jmxdn}/,/^ *$/p" ${configfile} | grep ds-cfg-listen-port: | awk '{print $2}'`
		jmxportenabled=`sed -n "/${jmxdn}/,/^ *$/p" ${configfile} | grep ds-cfg-enabled: | awk '{print $2}'`
		debug "JMX Handler: jmxport [$jmxport] jmxportenabled [$jmxportenabled]"
	fi
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
		baseversion=NA
		shortbaseversion=NA
	fi
	if [ "${baseversion}" = "NA" ]; then
		# Use the following 3 checks to see what version we have, if only the config file is available.
		# This is a last check to determine the possible version
		# Checks for entries only available in that major version
		finalvertest=`grep "dn: cn=Collation Matching Rule,cn=Matching Rules,cn=config" ${configfile}`
        	finalvertest=`sed -n '/dn: cn=Directory Manager,cn=Root DNs,cn=config/,/^ *$/p' ${configfile} | grep "userPassword:" | grep "SSHA512"`
		if [ $? = 0 ]; then
			baseversion="3.5.3"
			shortbaseversion=3
			guesstimate="(${shortbaseversion}x guesstimated)"
		fi
        	finalvertest=`sed -n '/dn: cn=Directory Manager,cn=Root DNs,cn=config/,/^ *$/p' ${configfile} | grep "userPassword:" | grep "PBKDF2"`
		if [ $? = 0 ]; then
			baseversion="5.5.2"
			shortbaseversion="5"
			guesstimate="(${shortbaseversion}x guesstimated)"
		fi
		finalvertest=`grep "dn: ds-cfg-backend-id=rootUser,cn=Backends,cn=config" ${configfile}`
		if [ $? = 0 ]; then
			baseversion="6.5.2"
			shortbaseversion="6"
			guesstimate="(${shortbaseversion}x guesstimated)"
		fi
	fi

	# check for 6x+ instances
	if [ "${monitorfile}" != "" -a "${baseversion}" = "" ]; then
		baseversion=`grep -E "ds-mon-full-version: |fullVersion: " ${monitorfile} | awk -F" " '{print $NF}' | sed "s/-SNAPSHOT//"`
		shortbaseversion=`echo ${baseversion} | cut -c1`
	fi

	# remove the "." dots from the version for a numerical version number check
	if [ "${baseversion}" != "" ]; then
		compactversion=`echo ${baseversion} | sed "s/\.//g" | cut -c1-3`
	else
		compactversion="0"
	fi

	vertest=`echo ${baseversion} | grep -E '^6.*|^7.*'`
	if [ $? = 0 ]; then
		debug "vertest = $vertest and baseversion = $baseversion"
		# NEEDS WORK?
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
	   fi

	   if [ "${ldapsport}" = "" -o "${ldapsportenabled}" = "" ]; then
		adminport=`sed -n '/dn: cn=Administration Connector,cn=config/,/^ *$/p' ${configfile} | grep ds-cfg-listen-port: | awk '{print $2}'`
		ldapsport=`sed -n '/dn: cn=LDAPS Connection Handler,cn=[Cc]onnection [Hh]andlers,cn=config/,/^ *$/p' ${configfile} | grep ds-cfg-listen-port: | awk '{print $2}'`
		ldapsporttls=`sed -n '/dn: cn=LDAPS Connection Handler,cn=[Cc]onnection [Hh]andlers,cn=config/,/^ *$/p' ${configfile} | grep ds-cfg-allow-start-tls: | awk '{print $2}'`

		ldapsportenabled=`sed -n '/dn: cn=LDAPS Connection Handler,cn=[Cc]onnection [Hh]andlers,cn=config/,/^ *$/p' ${configfile} | grep ds-cfg-enabled: | awk '{print $2}'`

		httpsport=`sed -n '/dn: cn=HTTPS Connection Handler,cn=connection handlers,cn=config/,/^ *$/p' ${configfile} | grep ds-cfg-listen-port: | awk '{print $2}'`

		httpsportenabled=`sed -n '/dn: cn=HTTPS Connection Handler,cn=connection handlers,cn=config/,/^ *$/p' ${configfile} | grep ds-cfg-enabled: | awk '{print $2}'`
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
	getJMXHandlerUse
	if [ "${jmxportenabled}" = "true" -o "${jmxportenabled}" = "TRUE" ]; then
		jmxportenabled="enabled"
	else
		jmxport="----"
		jmxportenabled="disabled"
		jmxportconns='NA'
	fi

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

checkForCustomCode()
{
	plugins=`grep "ds-cfg-java-class:" ${configfile} | grep -vE "org.opends|org.forgerock.openidm" | awk -F" " '{print $NF}' | sort -u`
	if [ "${plugins}" != "" ]; then
			format "Custom java class(s) found:" "" ""
		for plugin in ${plugins}; do
			thisPlugin=`sed -n '1!G;h;$p' ${configfile} | sed -n "/ds-cfg-java-class: ${plugin}/,/dn: /p" | tail -1 | sed "s/dn: //"`
				if [ "${thisPlugin}" = "cn=Backstage Connect,cn=Plugins,cn=config" ]; then
					addin="${YELB}${yellow}Warning: Evaluation DS Software in use!${nocolor}${FEND}"
					alerts="${alerts} Software:${YELBA}${yellow}Warning:~Evaluation~DS~Software~in~use${nocolor}${FEND}.KBI002"
					addKB "KBI002"
				else
					alertaddin=`echo "${thisPlugin}" | sed "s/ /~/g"`
					alerts="${alerts} Software:Info:~Custom~java~class~found:~${alertaddin}"
				fi
			printf "\t%-25s\t%-50s\t\t%s\n" "" "${thisPlugin}" "${addin}" | log
		done
	fi
}

printServerInfo()
{

# print the FQDN
fqdn=`grep ds-cfg-server-fqdn ${configfile} | awk '{print $2}'`
if [ -s "${monitorfile}" ]; then
	fqdn=`grep ds-mon-system-name ${monitorfile} | awk '{print $2}'`
else
	fqdn=""
fi
fqdnDisplay=${fqdn}
fqdnCheck=`echo "${fqdnDisplay}" | grep "^\."`
if [ "${fqdnDisplay}" = '&{fqdn}' ]; then
	fqdnDisplay='hostname-unavailable'
fi
if [ "${fqdnCheck}" != "" ]; then
	fqdnDisplay="illegal hostname (${fqdnDisplay})"
fi
hide "fqdnDisplay" "${fqdnDisplay}" "#"
	if [ "${fqdn}" = "&{fqdn}" -o "${fqdn}" = "" ]; then
		fqdn="FQDN Unavailable"
	fi

printf "\n%s\n" "${HR2}" | log
printf "%s\n" "${H4B}SERVER INFORMATION:${H4E}" | log
printf "\n%s\n" "${serverinfo}" | log
printf "%s\n" "${HR3}" | log
printf "${PREB}\n" | log
printf "\t%-25s\t%s\n" "Install FQDN (Hostname):" "${fqdnDisplay}" | log
  	if [ -s ../node/networkInfo ]; then
		localhost=`grep 'Local Host:' ../node/networkInfo | awk '{print $3}'`
		runtimeaddress=`grep IP: ../node/networkInfo | grep ${localhost} | sed "s/IP: //"`
		hide "runtimeaddress" "${runtimeaddress}" "#"
		printf "\t%-25s\t%s\n" "Runtime IP (Hostname):" "$runtimeaddress" | log
	fi

		getAdminPort
		printf "\n\t%-10s %-10s\t\t%-5s\t%-11s\n" "Admin Port" "(enabled)" "${adminport}" "conns:${adminportconns}" | log
		printf "\t%-10s %-10s\t\t%-5s\t%-11s\t%-12s\t%s\n" "LDAP Port" "(${ldapportenabled})" "${ldapport}" "conns:${ldapportconns}" "psearch:${ldappsearches}" "starttls:${ldapporttls}" | log
		printf "\t%-10s %-10s\t\t%-5s\t%-11s\t%-12s\t%s\n" "LDAPS Port" "(${ldapsportenabled})" "${ldapsport}" "conns:${ldapsportconns}" "psearch:${ldapspsearches}" "starttls:${ldapsporttls}" | log
		if [ "${httpport}" != "" -a "${httpportenabled}" != "" ]; then
			printf "\t%-10s %-10s\t\t%-5s\t%-11s\t\t\t%s\n" "HTTP Port" "(${httpportenabled})" "${httpport}" "conns:${httpportconns}" "starttls:${ldapsporttls}" | log
		fi
		if [ "${httpsport}" != "" -a "${httpsportenabled}" != "" ]; then
			printf "\t%-10s %-10s\t\t%-5s\t%-11s\t\t\t%s\n" "HTTPS Port" "(${httpsportenabled})" "${httpsport}" "conns:${httpsportconns}" "starttls:${ldapsporttls}" | log
		fi
		if [ "${jmxportenabled}" != "" ]; then
			printf "\t%-10s %-10s\t\t%-5s\t%s\t%s\n" "JMX Port" "(${jmxportenabled})" "${jmxport}" "conns:${jmxportconns}" "" | log
		fi

		calcLen "total:${totalconnectioncount}"
		getDashes "${mylen}"
		printf "\t%-25s\t%-5s\t%-11s\t%-12s\t%s\n" "" "" "${dashes}" "" "" | log
		printf "\t%-25s\t%-5s\t%-11s\t%-12s\t%s\n\n" "" "" "total:${totalconnectioncount}" "" "" | log

		if [ "${httpport}" = "" -a "${httpportenabled}" = "" -a "${httpsport}" = "" -a "${httpsportenabled}" = "" ]; then
			printf "\n"
		fi

	if [ "${shortbaseversion}" -le "${minimumEoslVersion}" ]; then
		eoslAlertDisplay="${REDB}${red}Version is EOSL${nocolor} *${FEND}"
		alerts="${alerts} Version:${REDBA}${red}This~OpenDJ~version~past~the~EOSL~date,${nocolor}${FEND}KBI001"
		addKB "KBI001"
		healthScore "ServerInfo" "RED"
	fi

if [ "${monitorfile}" != "" ]; then
	debug "Getting version info from ${monitorfile}"
	format "Base version:" "${baseversion} ${eoslAlertDisplay} ${guesstimate}" "Build info not available"
	format "Full version:" "`grep -iE "fullVersion|ds-mon-full-version" ${monitorfile} | sed "s/fullVersion: //; s/ds-mon-full-version: //"`"
	format "Installation Directory:" "`grep -iE "installPath|ds-mon-install-path" ${monitorfile} | awk -F" " '{print $NF}'`"
	format "Instance Directory:" "`grep -iE "instancePath|ds-mon-instance-path" ${monitorfile} | awk -F" " '{print $NF}'`"
	testInstallDir=`grep -iE "installPath|ds-mon-install-path" ${monitorfile} | awk -F" " '{print $NF}' | grep opends`
	if [ "${testInstallDir}" = "" ]; then
		embeddedFound="External Instance"
	else
		embeddedFound="Embedded Instance"
	fi
	format "Directory Type:" "${embeddedFound}" "NA"
	checkForCustomCode
	format "" "" ""
	format "Start time:" "`grep -iE "startTime: |ds-mon-start-time: " ${monitorfile} | awk -F" " '{print $NF}'`" "NA"
	format "Current time:" "`grep -iE "currentTime: |ds-mon-current-time: " ${monitorfile} | awk -F" " '{print $NF}'`" "NA"
elif [ -s ../logs/server.out ]; then
	debug "Getting version info from server.out"
	fullversion=`grep "starting up" ../logs/server.out | sed "s/.*msg=//; s/ starting up//"`
	if [ "${fullversion}" = "" ]; then
                if [ "${dataversion}" != "" ]; then
                	fullversion=`echo ${dataversion} | cut -c1-5`
                else
			fullversion="0"
                fi

	fi

	installDir=`grep "msg=Installation Directory" ../logs/server.out | awk -F" " '{print $NF}'`
	if [ "${installDir}" = "" ]; then
		installDir="NA"
	fi
	instanceDir=`grep "msg=Instance Directory" ../logs/server.out | awk -F" " '{print $NF}'`
	if [ "${instanceDir}" = "" ]; then
		instanceDir="NA"
	fi
	if [ "${baseversion}" = "" ]; then
		baseversion=`echo ${fullversion} | sed "s/ (build.*//" | awk -F" " '{print $NF}' | cut -c1-5`
		shortbaseversion=`echo ${baseversion} | cut -c1`
		compactversion=`echo ${baseversion} | sed "s/\.//g" | cut -c1-3`
	fi

	format "Base version:" "${baseversion} ${eoslAlertDisplay} ${guesstimate}" "Build info not available"
	printf "\t%-25s\t%s\n" "Full version:" "${fullversion}" | log
	printf "\t%-25s\t%s\n" "Installation Directory:" "${installDir}" | log
	printf "\t%-25s\t%s\n" "Instance Directory:" "${instanceDir}" | log
	testInstallDir=`echo ${installDir} | grep opends`
	if [ "${testInstallDir}" = "" ]; then
		embeddedFound="External DJ Instance"
	else
		embeddedFound="Embedded DJ Instance"
	fi
	format "Directory Type:" "${embeddedFound}" "NA"
	checkForCustomCode
	format "" "" ""
else
	format "Base version:" "${baseversion} ${eoslAlertDisplay} ${guesstimate}" "Build info not available"
	printf "\t%-25s\t%s\n" "Full version:" "NA" | log
	printf "\t%-25s\t%s\n" "Installation Directory:" "NA" | log
	printf "\t%-25s\t%s\n" "Instance Directory:" "NA" | log
	format "Directory Type:" "${embeddedFound}" "NA"
	checkForCustomCode
	format "" "" ""
	format "Start time:" "" "NA"
	format "Current time:" "" "NA"
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

# 1. If monitor exists, check for dn: cn=changelog,cn=replication,cn=monitor
# 2. If the CL entry/param is blank then try the Global Config for ds-cfg-server-id
# 3. If it's not blank, but uses Expressions, check the default value if one exists, against the logs?
# 3. Default to letting the RS code loop through the condfig data.
	if [ "${monitorfile}" != "" ]; then
		getParameter "dn: cn=changelog,cn=replication,cn=monitor" "${monitorfile}" "ds-mon-server-id" "dsid"
	fi
	if [ "${dsid}" = "" ]; then
		dsid=`sed -n "/dn: cn=config/,/^ *$/p" ${configfile} | grep "ds-cfg-server-id:" | sed "s/ds-cfg-server-id: //"`
		#dsidExpCheck=`echo ${dsid} | grep '&'`
	fi

	format "Server ID:" "${dsid}" "NA" ""
	format "Replication Group ID:" "`grep -iE "ds-cfg-group-id:" ${configfile} | head -1 | awk -F" " '{print $NF}'`" "NA" ""
	format "Work Queue:" "`sed -n "/dn: cn=Work Queue,cn=config/,/^ *$/p" ${configfile} | grep -iE "ds-cfg-max-work-queue-capacity: " | awk -F" " '{print $NF}'`" "NA" "1000"
	format "" "" ""

	if [ "${compactversion}" -ge "650" -a "${extractverfull}" = "3.0-java" -o "${compactversion}" -ge "650" -a "${extractverfull}" = "2.0" ]; then
		printf "\t${REDB}${red}%-23s\t%s${nocolor}${FEND}\n" "Warning: Extract version ${extractverfull} was used against a ${baseversion} DS version. Data is missing!" "${reindex}" | log
		alerts="${alerts} Extract:${REDBA}${red}Extract~version~${extractverfull}~was~used~against~a~${baseversion}~DS~version.~Data~is~missing!${nocolor}${FEND}.KBI000"
		addKB "KBI000"
		healthScore "Extract" "RED"
	else
		healthScore "Extract" "GREEN"
	fi

	if [ "${ServerInfo}" != "RED" -o "${ServerInfo}" != "YELLOW" ]; then
		healthScore "ServerInfo" "GREEN"
	fi
printf "${PREE}" | log

	# get profiles for checks later on
	if [ "${dsprofiles}" != "" ]; then
		for dsprofile in ${dsprofiles}; do
			dsprofilever=`echo ${dsprofile} | sed "s/:/ /" | awk '{print $2}'`
			dsprofile=`echo ${dsprofile} | sed "s/:/ /" | awk '{print $1}' | sed "s/-//g"`
			debug "Evaling [$dsprofile=$dsprofilever]"
			eval "${dsprofile}=\"${dsprofilever}\""
		done
	fi
}

printIndexes()
{

printf "\n%s\n" "${HR2}" | log
printf "%s\n" "${H4B}INDEX INFORMATION:${H4E}" | log
printf "\n%s\n" "${indexinfo}" | log
printf "%s\n" "${HR3}" | log
printf "${PREB}\n" | log
if [ "${backends}" = "" -o "${backendType}" = "Proxy" ]; then
	printf "\t%s\n\t%s\n\n" "No Backends available...system could be a Replication or Proxy Server" "See below." | log
	ctsIndexCount=0
	amCfgIndexCount=0
	identityStoreIndexCount=0
	idmRepoIndexCount=0
	printf "${PREE}" | log
	return
fi
printf "%s\t%s\n" "Note:" "Excessive index-entry-limit's flagged at 50,000+" | log

	# Get the len for all index names
	indexNames=`grep 'ds-cfg-attribute: ' ${configfile} | awk '{print $2}'`
	indexNames="${indexNames} ${backends}"

	# Grab the configured Virtual Attributes to be checked against index definitions
	getParameter "cn=Virtual Attributes,cn=config" "${configfile}" "ds-cfg-attribute-type" "virtAttrs"
	virtAttrs=`echo ${virtAttrs} | perl -p -e 's/\r\n|\n|\r/\n/g' | sed "s/ /'|'/g; s/^/'/; s/$/'/"`

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
		ttlInUse=`sed -n "/dn: ${index}/,/^ *$/p" ${configfile} | grep -i "ds-cfg-ttl-enabled: true"`
		thisLen=`sed -n "/dn: ${index}/,/^ *$/p" ${configfile} | grep "ds-cfg-index-type" | awk '{print $2}' | perl -p -e 's/\r\n|\n|\r/\n/g' | wc | awk '{print $3}'`
		if [ "${ttlInUse}" != "" ]; then
			thisLen=`expr ${thisLen} + 4`
		fi
		if [ "${thisLen}" -gt "${longestIndexType}" ]; then
			longestIndexType=${thisLen}
		fi
	done
done

	longestIndexName=`expr ${longestIndexName} + 2`; getDashes "${longestIndexName}"; idash1=${dashes}
	longestIndexType=`expr ${longestIndexType} + 1`; getDashes "${longestIndexType}"; idash2=${dashes}

for backend in $backends; do
	printf "\n%-${longestIndexName}s: %-${longestIndexType}s: %-20s: %-33s: %-24s: %-11s\n" "Backend: ${backend}" "index-type" "index-entry-limit" "index-extensible-matching-rule" "confidentiality-enabled" "Index type" | log
	printf "%-${longestIndexName}s:%-${longestIndexType}s:%-20s:%-33s:%-24s:%-11s\n" "${idash1}" "${idash2}" "---------------------" "----------------------------------" "-------------------------" "----------" | log
	indexes=`sed -n "/cn=Index,ds-cfg-backend-id=${backend},cn=Backends,cn=config/,/^ *$/p" ${configfile} | grep "dn: " | grep -iv 'dn: cn=Index' | awk '{print $2}'`
	indexCount=1
	ctsIndexCount=0
	amCfgIndexCount=0
	identityStoreIndexCount=0
	idmRepoIndexCount=0
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
		for rule in ${matchingRule}; do
			matchingRules="${matchingRules} ${rule}"
		done
		matchingRule=${matchingRules}
		matchingRules=''
		matchingRuleCount=`echo ${matchingRule} | wc | awk '{print $2}'`
		confidentiality=`sed -n "/dn: ${index}/,/^ *$/p" ${configfile} | grep -E "ds-cfg-confidentiality-enabled" | awk '{print $2}'`
		ttlenabled=`sed -n "/dn: ${index}/,/^ *$/p" ${configfile} | grep -E "ds-cfg-ttl-enabled" | awk '{print $2}'`

		if [ "${entryLimit}" = "" -a "${attrName}" != "" ]; then
			entryLimit="4000"
		fi
		if [ "${entryLimit}" != "" -a "${entryLimit}" -gt "50000" ]; then
			entryLimitAlertDisplay="*"
				alertcheck=`echo ${alerts} | grep 'Excessive*Index*Limits'`
				if [ $? = 1 -a "${entryLimitAlert}" = "0" ]; then
					alerts="${alerts} Indexes:${REDBA}${red}Excessive~Index~Limits${nocolor}${FEND}.KBI200"
					addKB "KBI200"
					entryLimitAlert=1
				fi

			entryLimitAlertAttrs="${entryLimitAlertAttrs} ${attrName}:${entryLimit}"
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

		virtCheck=`echo "${virtAttrs}" | grep -i "'${attrName}'"`
		checkVirtsToIgnore=`echo "${virtAttrIgnore}" | grep -i "'${attrName}'"`
		if [ "${virtCheck}" != "" -a "${checkVirtsToIgnore}" = "" ]; then
			ocTypeAlertDisplay=" *V"
			alerts="${alerts} Indexes:${REDBA}${red}Warning:~Illegal~Index~configured~for~virtual~attribute~(${attrName})~in~backend~${backend}${nocolor}${FEND}."
			badIndexes="${badIndexes} ${attrName}"
			badIndexlert=1
			addKB "KBI203"
		fi
		if [ "${attrName}" = "objectClass" ]; then
			for iType in ${indexType}; do
				if [ "${iType}" = "presence" -o "${iType}" = "substring" ]; then
					ocTypeAlertDisplay=" *"
					alerts="${alerts} Indexes:${REDBA}${red}Bad~objectClass~index~type(s)~found~(${iType})~for~backend~${backend}${nocolor}${FEND}."
					iTypes="${iTypes} ${iType}"
					badIndexTypeAlert=1
				#else
				#	ocTypeAlertDisplay=""
				fi
			done
		else
			ocTypeAlertDisplay=""
		fi

		if [ "${ttlenabled}" != "" ]; then
			ttlEnabledAddin="ttl"
			ttlEnabledIndexCount=`expr ${ttlEnabledIndexCount} + 1`
			ttlEnabledIndexes=`echo "${ttlEnabledIndexes}" | sed "s/^NA$//"`
			ttlEnabledIndexes="${attrName} ${ttlEnabledIndexes}"
		fi

	# Check for Default, System, CTS, and Custom indexes
	ctsIndexCheck=`echo ${index} | grep -iE "${ctsIndexes}"`
	amCfgIndexCheck=`echo ${index} | grep -iE "${amCfgIndexes}"`
	identityStoreIndexCheck=`echo ${index} | grep -iE "${amIdentityStoreIndexes}"`
	idmRepoIndexCheck=`echo ${index} | grep -iE "${idmRepoIndexes}"`
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
		indexAlertDisplay="am-cts"
		ctsIndexesFound=1
	elif [ "${amCfgIndexCheck}" != "" ]; then
		amCfgIndexCount=`expr ${amCfgIndexCount} + 1`
		indexAlertDisplay="am-cfg"
	elif [ "${identityStoreIndexCheck}" != "" ]; then
		identityStoreIndexCount=`expr ${identityStoreIndexCount} + 1`
		indexAlertDisplay="am-id"
	elif [ "${idmRepoIndexCheck}" != "" ]; then
		idmRepoIndexCount=`expr ${idmRepoIndexCount} + 1`
		indexAlertDisplay="idm-repo"
	else
		indexAlertDisplay="custom"
		customIndexCount=`expr ${customIndexCount} + 1`
	fi

	if [ "${matchingRuleCount}" -gt "1" ]; then
		matchingRuleCount=1
		for rule in ${matchingRule}; do
			if [ "${matchingRuleCount}" = "1" ]; then
				printf "%-${longestIndexName}s: %-${longestIndexType}s: %-20s: %-33s: %-25s: %-11s\n" "${attrName}${ocTypeAlertDisplay}" "${indexType} ${ttlEnabledAddin}" "${entryLimit} ${entryLimitAlertDisplay}" "${rule}" "${confidentiality}" "${indexAlertDisplay}" | log
			else
				printf "%-${longestIndexName}s: %-${longestIndexType}s: %-20s: %-33s: %-25s: %-11s\n" " " " " " " "${rule}" " " " " | log
			fi
			matchingRuleCount=`expr ${matchingRuleCount} + 1`
		done
	else
		printf "%-${longestIndexName}s: %-${longestIndexType}s: %-20s: %-33s: %-25s: %-11s\n" "${attrName}${ocTypeAlertDisplay}" "${indexType} ${ttlEnabledAddin}" "${entryLimit} ${entryLimitAlertDisplay}" "${matchingRule}" "${confidentiality}" "${indexAlertDisplay}" | log
	fi
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
		expectedCtsIndexes='22'
	else
		expectedCtsIndexes='23'
	fi

	ttlEnabledIndexes=`echo ${ttlEnabledIndexes} | sed "s/ //g"`

	if [ "${ttlEnabledIndexes}" = "" ]; then
		ttlEnabledIndexes="NA"
	fi

	printf "\n\t%-32s\t%s\n" "Total indexes: " "${indexCount}" | log
	printf "\t%-32s\t%s\t%s\n" "Total am-cfg indexes: " "${amCfgIndexCount}" "(expected ${expectedAmCfgIndexes} -  for an AM Config Store)" | log
	printf "\t%-32s\t%s\t%s\n" "Total am-cts indexes: " "${ctsIndexCount}" "(expected ${expectedCtsIndexes} - for an AM CTS Store)" | log
	printf "\t%-32s\t%s\t%s\n" "Total am-identity-store indexes: " "${identityStoreIndexCount}" "(expected ${expectedIDSIndexes} - for an AM Identity Store)" | log
	printf "\t%-32s\t%s\t%s\n" "Total idm-repo indexes: " "${idmRepoIndexCount}" "(expected ${expectedIDRIndexes} - for an IDM Repository)" | log
	printf "\t%-32s\t%s\n" "Total Custom indexes: " "${customIndexCount}" | log
	printf "\t%-32s\t%s\t%s\n\n" "Total TTL indexes: " "${ttlEnabledIndexCount}" "(${ttlEnabledIndexes})" | log
	printf "\t%-32s\t%s\t%s\n\n" "Total System indexes: " "${systemIndexCount}" "(expected 3)${systemIndexAlertDisplay}" | log

	if [ "${ttlEnabledIndexes}" != "NA" ]; then
		alerts="${alerts} Indexes:INFO:~TTL~Indexes~found~(${backend}/${ttlEnabledIndexes})."
		ttlEnabledIndexAlert=1
	fi

	# Check monitor for indexes that need to be rebuilt
	if [ "${monitorfile}" != "" ]; then
		needReindex=`sed -n "/dn: ds-cfg-backend-id=${backend},cn=backends,cn=monitor/,/^ *$/p; /dn: cn=${backend} Storage,cn=monitor/,/^ *$/p" ${monitorfile} | grep -E 'need-reindex|ds-mon-backend-degraded-index:' | awk '{print $2}'`
	fi
	if [ "${monitorfile}" != "" -a "${needReindex}" != "" ]; then
		for reindex in ${needReindex}; do
			printf "\t${YELB}${yellow}%-23s\t%s${nocolor}${FEND}\n" "Indexes need rebuild: " "${reindex}" | log
			alerts="${alerts} Indexes:${YELBA}${yellow}Warning~Index~needs~rebuilding~${reindex}${nocolor}${FEND}.KBI201"
			addKB "KBI201"
			healthScore "Indexes" "YELLOW"
		done
		printf "\n"
	fi

	if [ "${customIndexCount}" != "0" ]; then
		alerts="${alerts} Indexes:Info:~${customIndexCount}~Custom~indexes~configured~for~backend~${backend}."
	fi

	if [ "${entryLimitAlert}" = "1" ]; then
		entryLimitAlertAttrs=`echo ${entryLimitAlertAttrs} | sed "s/^ //"`
		printf "\t${REDB}%s${FEND}\n" "${REDB}${red}Alert: Excessive Index Limits in use (${entryLimitAlertAttrs})${nocolor}${FEND}" | log
		healthScore "Indexes" "RED"
	fi
	if [ "${badIndexlert}" = "1" ]; then
		for badIndex in ${badIndexes}; do
			printf "\t%s\n" "${REDB}${red}Alert: Illegal Index configured for virtual attribute (${badIndex}) in backend ${backend}${nocolor}${FEND}" | log
			healthScore "Indexes" "RED"
		done
	fi
	if [ "${badIndexTypeAlert}" = "1" ]; then
		iTypes=`echo ${iTypes} | sed "s/^ //"`
		printf "\t%s\n" "${REDB}${red}Alert: Bad objectClass index type(s) found (${iTypes})${nocolor}${FEND}" | log
		healthScore "Indexes" "RED"
	fi
	if [ "${systemIndexCount}" -lt "3" ]; then
		systemIndexes=`echo ${systemIndexes} | sed "s/|/ /g"`
		for systemIndex in ${systemIndexes}; do
			systemIndexCheck=`echo ${systemIndexesFound} | grep -iE "${systemIndex}"`
			if [ "${systemIndexCheck}" = "" ]; then
				systemIndex=`echo ${systemIndex} | sed "s/ds-cfg-attribute=//"`
				printf "\t%s\n" "${REDB}${red}Fatal: MISSING SYSTEM INDEX (${systemIndex})${nocolor}${FEND}" | log
				fatalalerts="${fatalalerts} Indexes:Fatal~Error:~Missing~System~Index~${systemIndex}.KBI202"
			fi
		done
	fi
	if [ "${ocIndexFound}" = "" ]; then
		printf "\t%s\n" "${REDB}${red}Fatal: MISSING INDEX (objectClass)${nocolor}${FEND}" | log
		fatalalerts="${fatalalerts} Indexes:Fatal~Error:~Missing~objectClass~Index~${systemIndex}"
	fi
	entryLimitAlert=0
	indexCount=1
	badIndexTypeAlert=0
	ttlEnabledIndexes="NA"
	iTypes=''
	matchingRuleCount=0
done
	if [ "${Indexes}" != "RED" -o "${Indexes}" != "YELLOW" ]; then
		healthScore "Indexes" "GREEN"
	fi
	printf "${PREE}" | log
}

printReplicaInfo()
{

printf "\n%s\n" "${HR2}" | log
printf "%s\n" "${H4B}REPLICATION INFORMATION:${H4E}" | log
printf "\n%s\n" "${replicationinfo}" | log
printf "%s\n" "${HR3}" | log

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
	# NEEDS WORK?
	#elif [ "${dstype}" = "" -a "${rstype}" = "RS" -a "${domainCount}" = "0" ]; then
	#	serverType="Replication Server/RS only/RS Broken Configuration"
	elif [ "${dstype}" = "" -a "${rstype}" = "RS" ]; then
		serverType="Replication Server (RS only)"
	else
		serverType="Stand Alone/Not replicated"
	fi
	printf "${PREB}\n" | log
	printf "\t%s\t%s\n\n" "Replica type:" "${serverType}" | log
	if [ "${serverType}" != "Stand Alone/Not replicated" ]; then
		printf "%s\t%s\n\n" "Directory Server Config:" | log
	fi

	# Calculate the longest ds-cfg-replication-server string for printf formatting
	longestRsName=`grep -E "ds-cfg-replication-server:|ds-cfg-bootstrap-replication-server:" ${configfile} | sed "s/ds-cfg-replication-server: //; s/ds-cfg-bootstrap-replication-server: //" | awk '{ print length($0) " " $0; }' | sort -u -n | cut -d ' ' -f 2- | tail -1 | awk '{ print length($0) " " $0}' | awk '{print $1}'`

		if [ "${longestRsName}" != "" ]; then
			if [ "${longestRsName}" != "" -a "${longestRsName}" -lt "22" ]; then
				longestRsName=22
			fi
		else
			longestRsName=22
		fi
  if [ "${serverType}" != "Stand Alone/Not replicated" ]; then
	# Get all DS cn=domains and sort them by longest to shorted (for display)
	replicaDomain=`grep 'cn=domains,cn=Multimaster Synchronization,cn=Synchronization Providers,cn=config' ${configfile} | grep -vE "dn: cn=domains|dn: cn=external changelog" | sed "s/ /~/g" | awk '{ print length($0) " " $0; }' | sort -r -n | cut -d ' ' -f 2-`

	# calculate $dashes to be displayed
	for domain in ${replicaDomain}; do
		getDashes "${longestRsName}"; d3=${dashes}

		domain=`echo ${domain} | sed "s/~/ /g; s/\\\\\/\./g"`
		baseDn=`sed -n "/${domain}/,/^ *$/p" ${configfile} | grep "ds-cfg-base-dn:" | sed "s/ds-cfg-base-dn: //"`
		calcLen2 "$baseDn"; dl=${btab}
			if [ "${btab}" -lt "19" ]; then
				btab="19"
				dl="19"
			fi
		getDashes "${dl}"; d1=${dashes}
	done
	if [ "${dsid}" != "" ]; then
		dsidLen=`echo ${dsid} | awk '{ print length($0) " " $0}' | awk '{print $1}'`
		if [ "${dsidLen}" -lt "5" ]; then
			dsidLen="5"
		fi
		getDashes "${dsidLen}"; d2=${dashes}
	fi

	printf "%-${btab}s\t%-${dsidLen}s\t\t%-${longestRsName}s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" "Replication Domain" "DS ID" "Replication Server(s)" "Conflict Purge" | log
	printf "%-${btab}s\t%-${dsidLen}s\t\t%-${longestRsName}s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" "${d1}" "${d2}" "${d3}" "--------------" | log
	for domain in ${replicaDomain}; do
		domain=`echo ${domain} | sed "s/~/ /g; s/\\\\\/\./g"`
		baseDn=`sed -n "/${domain}/,/^ *$/p" ${configfile} | grep "ds-cfg-base-dn:" | sed "s/ds-cfg-base-dn: //"`
                if [ "${baseDn}" != "cn=admin data" -a "${baseDn}" != "cn=schema" -a "${baseDn}" != "" ]; then
			displayBase="${baseDn}"
			hide "displayBase" "${displayBase}" "*"
		else
			displayBase="${baseDn}"
                fi
		serverId=`sed -n "/${domain}/,/^ *$/p" ${configfile} | grep "ds-cfg-server-id:" | sed "s/ds-cfg-server-id: //"`
		replServers=`sed -n "/${domain}/,/^ *$/p" ${configfile} | grep "ds-cfg-replication-server:" | sed "s/ds-cfg-replication-server: //" | sed "s/&{rs.servers}/rs.server.unavailable/"`
		conflictPurge=`sed -n "/${domain}/,/^ *$/p" ${configfile} | grep "ds-cfg-conflicts-historical-purge-delay:" | sed "s/ds-cfg-conflicts-historical-purge-delay: //"`
			if [ "${conflictPurge}" = "" ]; then
				conflictPurge="1 d"
			fi
			if [ "${replServers}" = "" ]; then
				getParameter "dn: cn=Multimaster Synchronization,cn=Synchronization Providers,cn=config" "${configfile}" "ds-cfg-bootstrap-replication-server" "replServers"
			fi
			if [ "${serverId}" = "" ]; then
				serverId=${dsid}
			fi

		printedbackend=0
		currentbase=""
	for thisbase in $replServers; do
                        displayRS=${thisbase}
                        hide "displayRS" "${thisbase}" "#"
		if [ "$printedbackend" = "0" -a "$currentbase" = "$thisbase" ]; then
			printf "%-${btab}s\t%-${dsidLen}s\t\t%-${longestRsName}s\t%s\t%s\t%s\t%s\t%s\n" "${displayBase}" "${serverId}" "${replServers}" "${conflictPurge}" | log
		
			printedbackend=1
			currentbase=$thisbase
		elif [ "$printedbackend" = "1" -a "$currentbase" != "$thisbase" ]; then
			printf "%-${btab}s\t%-${dsidLen}s\t\t%-${longestRsName}s\t%s\t%s\t%s\t%s\t%s\n" "" "" "${displayRS}" "${conflictPurge}" | log
			printedbackend=1
		else
			printf "%-${btab}s\t%-${dsidLen}s\t\t%-${longestRsName}s\t%s\t%s\t%s\t%s\t%s\n" "${displayBase}" "${serverId}" "${displayRS}" "${conflictPurge}" | log
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
		domain=`echo ${domain} | sed "s/~/ /g; s/\\\\\/\./g"`
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
		if [ "${dsid}" != "" ]; then
			rsid=${dsid}
		else
			rsid="id.unavailable"
		fi
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
		if [ "${replservers}" = "&{rs.servers}" ]; then
			replservers="rs.servers.unavailable"
		fi

		replServerDisplay="${replservers}"
		hide "replServerDisplay" "${replservers}" "#"

		printf "%-24s\t\t%-5s\t\t%-27s\t%s\t%s\t%s\t%s\t%s\n" "Property" "Value(s)" | log
		printf "%-24s\t\t%-5s\t\t%-27s\t%s\t%s\t%s\t%s\t%s\n" "------------------------" "--------" | log 
		printf "%-24s\t\t%-5s\t\t%-27s\t%s\t%s\t%s\t%s\t%s\n" "replication-server-id" "${rsid}" | log 
		printf "%-24s\t\t%-5s\t\t%-27s\t%s\t%s\t%s\t%s\t%s\n" "group-id" "${grpid}" | log 
		printf "%-24s\t\t%-5s\t\t%-27s\t%s\t%s\t%s\t%s\t%s\n" "ds-cfg-replication-port" "${replicationport}" | log 
		printf "%-24s\t\t%-5s\t\t%-27s\t%s\t%s\t%s\t%s\t%s\n" "ds-cfg-replication-server" "${replServerDisplay}" | log 
		printf "%-24s\t\t%-5s\t\t%-27s\t%s\t%s\t%s\t%s\t%s\n" "${changenumberindexerattr}" "${computechangenumber}" | log 
		printf "%-24s\t\t%-5s\t\t%-27s\t%s\t%s\t%s\t%s\t%s\n" "ds-cfg-confidentiality-enabled" "${confidentialityenabled}" | log 
		printf "%-24s\t\t%-5s\t\t%-27s\t%s\t%s\t%s\t%s\t%s\n" "ds-cfg-replication-purge-delay" "${replicationpurgedelay}" | log 
		printf "%-24s\t\t%-5s\t\t%-27s\t%s\t%s\t%s\t%s\t%s\n" "ds-cfg-source-address" "${sourceaddress}" | log 


		if [ "${computechangenumber}" = "disabled" -o "${computechangenumber}" = "false" ]; then
			alerts="${alerts} REPL:${YELB}${yellow}The~changelog~is~disabled.~The~"cn=changelog"~backend~will~not~be~available~to~client~applications.${nocolor}${FEND}KBI302"
			printf "\n\t%s\n\n" "${YELB}${yellow}Info: The changelog is disabled. The "cn=changelog" backend will not be available to client applications.${nocolor}${FEND}" | log
			addKB "KBI302"
			healthScore "Replication" "YELLOW"
		fi
		mmsyncenabled=`echo ${mmsyncenabled} | tr [:upper:] [:lower:]`
		debug "mmsyncenabled->$mmsyncenabled"
		if [ "${rsid}" != "" -a "${mmsyncenabled}" = "false" ]; then
			fatalalerts="${fatalalerts} REPL:${REDBA}Replication~is~configured~but~is~currently~disabled.~Replication~is~offline!${FEND}KBI300"
			printf "\n\t%s\n\n" "${REDB}${red}Alert: Replication is configured but is currently disabled. Replication is offline!${nocolor}${FEND}" | log
		fi
	fi

		printf "\n%s\t%s\n\n" "Admin Data Config:" | log
		if [ "${serverType}" != "Stand Alone/Not replicated" -a "${adminfile}" != "" -a "${shortbaseversion}" != "7" ]; then

			hasInstanceKeyCount="0"
			allServersEntryCount="0"
			hasServerKeyEntryCount="0"
			allServers=`grep -E '^uniqueMember:|cn=Servers,cn=admin data' "${adminfile}" | sed "s/uniqueMember: //; s/,*cn=Servers,cn=admin data//; s/dn: //g" | sort -u | grep ':'`
			instanceKeys=`grep "dn: ds-cfg-key-id=.*,cn=instance keys,cn=admin data" ${adminfile} | sed "s/dn: ds-cfg-key-id=//; s/,cn=instance keys,cn=admin data//"`
			instanceKeyCount=`grep "dn: ds-cfg-key-id=.*,cn=instance keys,cn=admin data" ${adminfile} | wc -l | awk '{print $1}'`

			abServerLen=0
			for abServer in $allServers; do
				thisABServerLen=`echo ${abServer} | awk '{ print length($0) }'`
				if [ "${thisABServerLen}" -gt "${abServerLen}" ]; then
					abServerLen=${thisABServerLen}
				fi
			done
			if [ "${abServerLen}" = "0" ]; then
				abServerLen="19"
			fi
			getDashes "${abServerLen}"; abServerDashes=${dashes}

		if [ "${allServers}" = "" -a "${instanceKeyCount}" -lt "1" ]; then
			printf "%s\n\n" " * No replica configuration found for:"
			printf "\t- %s\n" "dn: cn=all-servers,cn=Server Groups,cn=admin data uniqueMembers"
			printf "\t- %s\n" "dn: cn=<hostname>:<port>,cn=Servers,cn=admin data entries"
			printf "\t- %s\n" "associated cn=instance keys,cn=admin data entries"
			fatalalerts="${fatalalerts} REPL:${REDBA}${red}Replication~is~configured~but~the~cn=admin~data~entry~is~missing~required~configuration~elements.${nocolor}${FEND}KBI303"
			printf "\n\t%s\n\n" "${REDB}${red}Info: Replication is configured but the cn=admin data entry is missing required configuration elements.${nocolor}${FEND}" | log
			addKB "KBI302"
			healthScore "Replication" "RED"
		elif [ "${allServers}" = "" -a "${instanceKeyCount}" -ge "1" ]; then
			printf "%-19s\t%-20s\t%-16s\t%-32s\n" "Server" "cn=all-servers Entry" "Has Server Entry" "Has Instance Key" | log
			printf "%-19s\t%-20s\t%-16s\t%-32s\n" "-------------------" "--------------------" "----------------" "--------------------------------" | log
			for instanceKey in ${instanceKeys}; do
				printf "%-19s\t%-20s\t%-16s\t%-16s\n" "Entry not Available" "NA" "NA" "${instanceKey}" | log
			done
			printf "\n\t%s\n" "${YELB}${yellow}Warning: Missing configuration. DS tools and DS Proxy Services may fail.${nocolor}${FEND}" | log
			alerts="${alerts} REPL:${YELBA}${yellow}Warning:~Missing~configuration.~DS~tools~and~DS~Proxy~Services~may~fail${nocolor}${FEND}.KBI303"
			healthScore "Replication" "YELLOW"
			addKB "KBI303"
		else
			printf "%-${abServerLen}s\t%-20s\t%-16s\t%-16s\n" "Server" "cn=all-servers Entry" "Has Server Entry" "Instance Key" | log
			printf "%-${abServerLen}s\t%-20s\t%-16s\t%-32s\n" "${abServerDashes}" "--------------------" "----------------" "--------------------------------" | log
			for thisServer in $allServers; do
				allServersEntry=`sed -n "/dn: cn=all-servers,cn=Server Groups,cn=admin data/,/^ *$/p" ${adminfile} | grep "^uniqueMember: ${thisServer}"`
				if [ "${allServersEntry}" != "" ]; then
					allServersEntryDisplay="yes"
					allServersEntryCount=`expr ${allServersEntryCount} + 1`
				else
					allServersEntryDisplay="no *"
					allServersEntryAlert=1
				fi
				hasServerKeyEntry=`sed -n "/dn: ${thisServer},cn=Servers,cn=admin data/,/^ *$/p" ${adminfile} | grep "^ds-cfg-key-id:" | sed "s/ds-cfg-key-id: //"`
				if [ "${hasServerKeyEntry}" != "" ]; then
					hasServerKeyEntryDisplay="yes"
					hasServerKeyEntryCount=`expr ${hasServerKeyEntryCount} + 1`
				else
					hasServerKeyEntryDisplay="no *"
					hasServerKeyEntryAlert=1
					healthScore "Replication" "YELLOW"
				fi
				hasInstanceKeyEntry=`grep "dn: ds-cfg-key-id=${hasServerKeyEntry},cn=instance keys,cn=admin data" ${adminfile}`
				if [ "${hasInstanceKeyEntry}" != "" ]; then
					hasInstanceKeyEntry="yes"
					instanceKeys=`echo ${instanceKeys} | sed "s/${hasServerKeyEntry}//"`
					hasInstanceKeyCount=`expr ${hasInstanceKeyCount} + 1`
				else
					hasInstanceKeyEntry="no"
					hasInstanceKeyAlert=1
					hasServerKeyEntry="${REDB}${red}no instance key found${nocolor}${FEND}"
				fi
				hide "thisServerDisplay" "${thisServer}" "X"
				printf "%-${abServerLen}s\t%-20s\t%-16s\t%-16s\n" "${thisServerDisplay}" "${allServersEntryDisplay}" "${hasServerKeyEntryDisplay}" "${hasServerKeyEntry}" | log

				if  [ "${thisServer}" != "" ]; then
					# print has Server Entry"
						lee=1
				fi

				allServersEntry=''
				hasServerKeyEntry=''
				hasInstanceKeyEntry=''
			done
			#printf "%-19s\t%-20s\t%-16s\t%-32s\n" "                                                                   " "-------" "-------" "-------" | log
			#printf "%-19s\t%-20s\t%-16s\t%-32s\n" "                                                                   " "${allServersEntryCount} Total" "${hasServerKeyEntryCount} Total" "${hasInstanceKeyCount} Total" | log
				debug "instanceKeyCount $instanceKeyCount"
				debug "instanceKeys $instanceKeys"
				instanceKeyCount=`echo ${instanceKeys} | wc | awk '{print $2}'`
				if [ "${instanceKeyCount}" -ge "1" ]; then
					printf "\n"
					for instanceKey in ${instanceKeys}; do
						printf "%-${abServerLen}s\t%-20s\t%-16s\t%-16s\n" "Unreferenced Key **" "" "" "${instanceKey}" | log
					done
				fi
				if [ "${allServersEntryAlert}" = "1" -o "${hasServerKeyEntryAlert}" = "1" ]; then
					printf "\n\t%s\n" "${YELB}${yellow}* Warning: Missing configuration. DS tools and DS Proxy Services may fail.${nocolor}${FEND}" | log
					alerts="${alerts} REPL:${YELBA}${yellow}Warning:~Missing~configuration.~DS~tools~and~DS~Proxy~Services~may~fail.${nocolor}${FEND}.KBI303"
					healthScore "Replication" "YELLOW"
					addKB "KBI303"
				fi
				if [ "${hasInstanceKeyAlert}" = "1" ]; then
					printf "\n\t%s\n" "${REDB}${red}Fatal: Instance keys are missing. Replication is compromised.${nocolor}${FEND}" | log
					fatalalerts="${fatalalerts} REPL:${REDBA}${red}Instance~keys~are~missing.~Replication~is~compromised.${nocolor}${FEND}KBI303"
					healthScore "Replication" "RED"
					addKB "KBI303"
				fi
				if [ "${instanceKeyCount}" -ge "1" ]; then
					printf "\n\t%s\n" "** Keys which are not currently associated with a servers configuration."
					printf "\t%s\n" "   - from deprecated DS instances"
					printf "\t%s\n" "   - from expired/rotated certificates"
					printf "\t%s\n" "   - the result of failed replication setup"
				fi
			fi
		fi
			if [ "${adminfile}" = "" ]; then
				printf "\t%s\n" "${YELB}${yellow}Warning: Missing admin-backend.ldif file.${nocolor}${FEND}" | log
			fi
	# Display the captured changelogDb info
	if [ -s ../changelogDbInfo/domains.state -a -s ../changelogDbInfo/changelogDb.listing -a "${compactversion}" = "653" ]; then
	printf "\n%s\t%s\n\n" "ChangelogDb Information:" | log
	printf "%-${btab}s\t%-5s\t\t%-${longestRsName}s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" "Changelog Domain" "DS ID" "CL File Count" "Generation ID" | log
	printf "%-${btab}s\t%-5s\t\t%-${longestRsName}s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" "${d1}" "-----" "${d2}" "--------------" | log
		domainNumbers=`cat ../changelogDbInfo/domains.state | cut -c1 | sort`
		printedbackend=0
		currentbase=""
		for domainNumber in ${domainNumbers}; do
		changelogDomainName=`grep ${domainNumber} ../changelogDbInfo/domains.state | sed "s/.*://"`
		changelogDomainIDS=`grep "${domainNumber}.dom.*.server:" ../changelogDbInfo/changelogDb.listing | sed "s/.server://; s,/, ,g" | awk -F" " '{print $NF}'`

		hide "displayBase" "${changelogDomainName}" "*"

		   for serverId in ${changelogDomainIDS}; do
			thisDomainChangelog=`sed -n "/$serverId/,/^ *$/p" ../changelogDbInfo/changelogDb.listing`
			thisDomainChangelogCount=`echo ${thisDomainChangelog} | grep -c "log" | awk '{print $1}'`
			thisDomainChangelogGenID=`echo ${thisDomainChangelog} | grep '.id$' | awk -F" " '{print $NF}' | sed "s/generation//; s/\.id$//"`
			if [ "${thisDomainChangelogGenID}" = "" ]; then
				thisDomainChangelogGenID="NA"
			fi

			if [ "$printedbackend" = "0" -a "$currentbase" != "$changelogDomainName" ]; then
				printf "%-${btab}s\t%-5s\t\t%-${longestRsName}s\t%s\t%s\t%s\t%s\t%s\n" "${displayBase}" "${serverId}" "${thisDomainChangelogCount}" "${thisDomainChangelogGenID}" | log
		
				printedbackend=1
				currentbase=$changelogDomainName
			elif [ "$printedbackend" = "1" -a "$currentbase" = "$changelogDomainName" ]; then
				printf "%-${btab}s\t%-5s\t\t%-${longestRsName}s\t%s\t%s\t%s\t%s\t%s\n" "" "${serverId}" "${thisDomainChangelogCount}" "${thisDomainChangelogGenID}" | log
				printedbackend=1
			else
				printf "%-${btab}s\t%-5s\t\t%-${longestRsName}s\t%s\t%s\t%s\t%s\t%s\n" "${displayBase}" "${serverId}" "${thisDomainChangelogCount}" "${thisDomainChangelogGenID}" | log
				printedbackend=1
				currentbase=$changelogDomainName
			fi

		   done
			printedbackend=0
			currentbase=""
		done
	fi

	# display connected server info
printf "\n%s\t%s\n\n" "Connected Servers:" | log
if [ "${serverType}" = "Directory Server + Replication Server (DS+RS)" -o "${serverType}" = "Replication Server (RS only)" ]; then
  if [ "${monitorfile}" != "" ]; then

	# loop through all domains and display the connected DS to RS
	for domain in ${replicaDomain}; do
		domain=`echo ${domain} | sed "s/~/ /g; s/\\\\\/\./g"`
		baseDn=`sed -n "/${domain}/,/^ *$/p" ${configfile} | grep "ds-cfg-base-dn:" | sed "s/ds-cfg-base-dn: //"`

	  if [ "${shortbaseversion}" -le "5" ]; then
		thisDomain=`echo ${baseDn} | sed "s/,/_/g; s/=/_/g"`
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

                if [ "${baseDn}" != "cn=admin data" -a "${baseDn}" != "cn=schema" -a "${baseDn}" != "" ]; then
                        displayBase="${baseDn}"
                        hide "displayBase" "${displayBase}" "*"
		else
                        displayBase="${baseDn}"
                fi

	  if [ "${shortbaseversion}" -le "5" ]; then
		connectedDS=`grep "dn: cn=Connected directory server DS(.*) ${runtimeaddress}:.*,cn=Replication server RS(${rsid}) .*:${replicationport},cn=${thisDomain},cn=Replication,cn=monitor" ${monitorfile} | grep -v 'cn=Connected replication server RS'`

		connectedDSconflicts=`sed -n "/dn: cn=Directory server DS(.*) ${runtimeaddress}:.*,cn=${thisDomain},cn=Replication,cn=monitor/,/^ *$/p" ${monitorfile} | grep "unresolved-naming-conflicts:" | sed "s/unresolved-naming-conflicts: //"`
		#dsid=`sed -n "/${domain}/,/^ *$/p" ${configfile} | grep "ds-cfg-server-id:" | sed "s/ds-cfg-server-id: //; s/&{server.id}/server.id.unavailable/"`
		dsid=`sed -n "/${domain}/,/^ *$/p" ${configfile} | grep "ds-cfg-server-id:" | sed "s/ds-cfg-server-id: //"`
		if [ "${dsid}" = "" ]; then
			getParameter "dn: cn=changelog,cn=replication,cn=monitor" "${monitorfile}" "ds-mon-server-id" "dsid"
		fi

		baseDn=`echo ${baseDn} | sed "s/ /~/g"`

		if [ "${connectedDSconflicts}" ]; then
			if [ "${connectedDSconflicts}" -gt "0" ]; then
				connectedDSconflictsDisplay="${REDB}${red}unresolved-naming-conflicts: [${connectedDSconflicts}]${nocolor}${FEND} *"
				alerts="${alerts} REPL:${REDBA}${red}${backend}~has~${connectedDSconflicts}~unresolved~naming~conflicts.${nocolor}${FEND}KBI301"
				addKB "KBI301"
				healthScore "Replication" "RED"
				printf "\t%s\t%s\t%s\n\n" "BaseDN:" "${displayBase}" "${connectedDSconflictsDisplay}" | log
			else
				connectedDSconflictsDisplay=""
				printf "\t%s\t%s\n\n" "BaseDN:" "${displayBase}" | log
			fi
		fi

		thisRS=`echo ${connectedDS} | sed "s/.*cn=Replication server RS//; s/,cn=${thisDomain},cn=Replication,cn=monitor//"`
		connectedDS=`echo ${connectedDS} | sed "s/dn: cn=Connected directory server DS//; s/,cn=Replication server RS.*//"`
			if [ "${connectedDS}" = "" ]; then
				connectedDS="(${dsid}) ${runtimeaddress}:${adminPort}"
				connectionInfo="${REDB}${red}is not connected to an${nocolor}${FEND}"
				alerts="${alerts} REPL:${REDBA}${red}DS~for~${baseDn}~is~not~connected~to~an~RS${nocolor}${FEND}"
			else
				connectionInfo="${GRNB}${green}<- connected to ->${nocolor}${FEND}"
			fi
		calcLen "${connectedDS}"; cdstab=${tab}
		hide "connectedDSDisplay" "${connectedDS}" "X"
		printf "\t\t%-9s %-${cdstab}s %-23s" "This DS:" "${connectedDSDisplay}" "${connectionInfo}" | log
			if [ "${thisRS}" = "" ]; then
				thisRS="(${rsid}) ${runtimeaddress}:${replicationport}"
				connectedRS=""
				connectionInfo="${REDB}${red}is not connected to an${nocolor}${FEND}"
			else
				connectionInfo="${GRNB}${green}<- connected to ->${nocolor}${FEND}"
				connectedRS="(${rsid}) ${runtimeaddress}:${replicationport}"
			fi
		hide "connectedRSDisplay" "${connectedRS}" "X"
		printf "%s %s\n" " RS:" "${connectedRSDisplay}" | log

		connectedRS=`grep "dn: cn=Connected replication server RS(.*) .*:.*,cn=Replication server RS(${rsid}) .*:${replicationport},cn=${thisDomain},cn=Replication,cn=monitor" ${monitorfile}`
		connectedRS=`echo ${connectedRS} | sed "s/dn: cn=Connected replication server RS//; s/,cn=Replication server RS.*//"`
			if [ "${connectedRS}" = "" ]; then
				#thisRS="(${rsid}) ${runtimeaddress}:${replicationport}"
				connectedRS=""
				connectionInfo="${REDB}${red}is not connected to an${nocolor}${FEND}"
				alerts="${alerts} REPL:${REDBA}${red}RS~for~${baseDn}~is~not~connected~to~another~RS${nocolor}${FEND}"
			else
				connectionInfo="${GRNB}${green}<- connected to ->${nocolor}${FEND}"
			fi

		calcLen "${thisRS}"; crstab=${tab}
		hide "connectedRSDisplay" "${connectedRS}" "X"
		hide "thisConnectedRSDisplay" "${connectedRS}" "X"
		printf "\t\t%-9s %-${crstab}s %-23s" "This RS:" "${thisConnectedRSDisplay}" "${connectionInfo}" | log
		printf "%s %s\n\n" " RS:" "${connectedRSDisplay}" | log

	  # DS 6x block - begin
	  else
	printf "\t%s\t%s\t%s\n\n" "BaseDN:" "${displayBase}" "${connectedDSconflictsDisplay}" | log
		# DS6+ Connected DS
		dsid=`sed -n "/${domain}/,/^ *$/p" ${configfile} | grep "ds-cfg-server-id:" | sed "s/ds-cfg-server-id: //"`

		if [ "${dsid}" = "" ]; then
			dsid=`sed -n "/dn: cn=config/,/^ *$/p" ${configfile} | grep "ds-cfg-server-id:" | sed "s/ds-cfg-server-id: //"`
		fi
		if [ "${dsid}" = "" ]; then
			getParameter "dn: cn=changelog,cn=replication,cn=monitor" "${monitorfile}" "ds-mon-server-id" "dsid"
		fi
		connectedDS=`sed -n "/dn: ds-mon-server-id=${dsid},cn=connected replicas,ds-mon-domain-name=${thisDomain},cn=changelog,cn=replication,cn=monitor/,/^ *$/p" ${monitorfile} | grep 'ds-mon-replica-hostport:' | sed "s/ds-mon-replica-hostport: //"`
			if [ "${connectedDS}" = "" ]; then
				connectedDS="(${dsid}) ${runtimeaddress}:${adminPort}"
				connectionInfo="${REDB}${red}is not connected to an${nocolor}${FEND}"
				baseDn=`echo ${baseDn} | sed "s/ /~/g"`
				alerts="${alerts} REPL:${REDBA}${red}DS~for~${baseDn}~is~not~connected~to~an~RS${nocolor}${FEND}"
				baseDn=`echo ${baseDn} | sed "s/~/ /g"`
			else
				connectionInfo="${GRNB}${green}<- connected to ->${nocolor}${FEND}"
			fi
		DSconnectedRS=`sed -n "/dn: ds-mon-server-id=${dsid},cn=connected replicas,ds-mon-domain-name=${thisDomain},cn=changelog,cn=replication,cn=monitor/,/^ *$/p" ${monitorfile} | grep 'ds-mon-connected-to-server-hostport:' | sed "s/ds-mon-connected-to-server-hostport: //"`

		rsid=`sed -n "/dn: ds-mon-server-id=${dsid},cn=connected replicas,ds-mon-domain-name=${thisDomain},cn=changelog,cn=replication,cn=monitor/,/^ *$/p" ${monitorfile} | grep 'ds-mon-connected-to-server-id:' | sed "s/ds-mon-connected-to-server-id: //"`
		hide "connectedDSDisplay" "${connectedDS}" "X"
		connectedDS="(${dsid}) ${connectedDSDisplay}"
		hide "DSconnectedRSDisplay" "${DSconnectedRS}" "X"
		DSconnectedRS="(${rsid}) ${DSconnectedRSDisplay}"
		calcLen "${connectedDS}"; cdstab=${tab}
		printf "\t\t%-9s %-${cdstab}s %-23s" "This DS:" "${connectedDS}" "${connectionInfo}" | log
		printf "%s %s\n" " RS:" "${DSconnectedRS}" | log

		# DS6+ Connected RS
		connectedRS=`sed -n "/dn: ds-mon-changelog-id=.*,cn=connected changelogs,ds-mon-domain-name=${thisDomain},cn=changelog,cn=replication,cn=monitor/,/^ *$/p" ${monitorfile} | grep 'ds-mon-changelog-hostport:' | sed "s/ds-mon-changelog-hostport: //" | head -1`
		connectedrsid=`sed -n "/dn: ds-mon-changelog-id=.*,cn=connected changelogs,ds-mon-domain-name=${thisDomain},cn=changelog,cn=replication,cn=monitor/,/^ *$/p" ${monitorfile} | grep 'ds-mon-changelog-id:' | sed "s/ds-mon-changelog-id: //" | head -1`

			if [ "${connectedRS}" = "" ]; then
				connectedRS=""
				connectionInfo="${REDB}${red}is not connected to an${nocolor}${FEND}"
				baseDn=`echo ${baseDn} | sed "s/ /~/g"`
				alerts="${alerts} REPL:${REDBA}${red}RS~for~${baseDn}~is~not~connected~to~another~RS${nocolor}${FEND}"
				baseDn=`echo ${baseDn} | sed "s/~/ /g"`
			else
				connectionInfo="${GRNB}${green}<- connected to ->${nocolor}${FEND}"
			fi

		calcLen "${thisRS}"; crstab=${tab}
		printf "\t\t%-9s %-${crstab}s %-23s" "This RS:" "${DSconnectedRS}" "${connectionInfo}" | log
		hide "connectedRSDisplay" "${connectedRS}" "X"
		connectedRS="(${connectedrsid}) ${connectedRSDisplay}"
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
	printf "${PREE}" | log
}

printBackends()
{

printf "\n%s\n" "${HR2}" | log
printf "%s\n" "${H4B}BACKEND INFORMATION:${H4E}" | log
printf "\n%s\n" "${backendinfo}" | log
printf "%s\n" "${HR3}" | log
printf "${PREB}\n" | log

	# Calculate the string length of the backends.
	for backend in $backends; do
	calcLen "$backend"

		# Remove any LDIF based backend
		backendType=`sed -n "/dn: ds-cfg-backend-id=${backend},cn=Backends,cn=config/,/^ *$/p" $configfile | grep "ds-cfg-java-class: " | sed "s/\./ /g" | awk -F" " '{print $NF}' | sed "s/Backend//"`
			if [ "${backendType}" = "LDIF" ]; then
				backends=`echo "${backends}" | sed "s/$backend//"`
			fi
	done

	if [ "${backends}" = "" ]; then
		printf "\t%s\n\t%s\n\n" "No Backends available...system could be a Replication or Proxy Server" "See below." | log
		printf "${PREE}" | log
		return
	fi

	if [ "$tab" -lt "9" ]; then
		tab=9
	fi

	sharedCacheEnabled=`sed -n "/dn: cn=config/,/^ *$/p" $configfile | grep "ds-cfg-je-backend-shared-cache-enabled: " | sed "s/ds-cfg-je-backend-shared-cache-enabled: //"`
	sharedCacheEnabled=`echo ${sharedCacheEnabled} | tr [:upper:] [:lower:]`
	if [ "${compactversion}" -ge "650" -a "${sharedCacheEnabled}" = "false" ]; then
		sharedCacheAddInMsg="The db-cache-percent & db-cache-size settings are in effect. (JE shared-cache is disabled)"
		sharedCacheAddInMsgAlert="The~db-cache-percent~&~db-cache-size~settings~are~in~effect.~(JE~shared-cache~is~disabled)"
	elif [ "${compactversion}" -ge "650" -a "${sharedCacheEnabled}" = "" -o "${sharedCacheEnabled}" = "true" ]; then
		sharedCacheEnabled="true"
	else
		sharedCacheEnabled="false"
	fi

# calculate the string len of each backend name
for backend in $backends; do
	# sed to substitute spaces in the baseDN like -> o=Bank New
	basedn=`sed -n "/dn: ds-cfg-backend-id=${backend},cn=Backends,cn=config/,/^ *$/p" $configfile | grep "ds-cfg-base-dn: " | sed "s/ds-cfg-base-dn: //; s/ /-/g"`

	# get dashes for the backendID
	getDashes "${tab}"
	backendDashes=$dashes

	# get dashes for the baseDN
	calcLen2 "$basedn"; dl=${btab}
	getDashes "${dl}"
# WORKING
	baseDnDashes=${dashes}
	#limit=`sed -n "/dn: ds-cfg-backend-id=${backend},cn=Backends,cn=config/,/^ *$/p" $configfile | grep "index-entry-limit: " | sed "s/index-entry-limit: //"`
	#backendType=`sed -n "/dn: ds-cfg-backend-id=${backend},cn=Backends,cn=config/,/^ *$/p" $configfile | grep "ds-cfg-java-class: " | sed "s/\./ /g" | awk -F" " '{print $NF}' | sed "s/Backend//"`
	#confidentiality=`sed -n "/dn: ds-cfg-backend-id=${backend},cn=Backends,cn=config/,/^ *$/p" $configfile | grep "confidentiality-enabled: " | sed "s/\./ /g" | awk -F" " '{print $NF}' | sed "s/Backend//"`
	#	if [ "$backendType" = "Impl" ]; then
	#		backendType="JE"
	#	fi
done

# print all
	printf "%-${tab}s\t%-${btab}s\t%-9s\t%s\t%s\t%-10s\t%s\t%s\t%s\t%s\n" "BackendID" "BaseDN" "Cache(s)" "Enabled" "iLimit" "LG-Cache" "Type" "Encryption" "Cmprs" "Entries" | log
	printf "%-${tab}s\t%-${btab}s\t%-9s\t%s\t%s\t%-10s\t%s\t%s\t%s\t%s\n" "${backendDashes}" "${baseDnDashes}" "---------" "-------" "------" "---------" "----" "----------" "-----" "-------" | log

for backend in $backends; do
	check=`echo "'rootUser' 'adminRoot' 'ads-truststore' 'backup' 'config' 'monitor' 'schema' 'tasks'" | grep "'${backend}'"`
	if [ $? = 0 -a "$displayall" = "" ]; then
		i=`expr  1 + 1`
	else
	basedn=`sed -n "/dn: ds-cfg-backend-id=${backend},cn=Backends,cn=config/,/^ *$/p" $configfile | grep "ds-cfg-base-dn: " | sed "s/ds-cfg-base-dn: //; s/ /-/g"`

	#dbcache=`sed -n "/dn: ds-cfg-backend-id=${backend},cn=Backends,cn=config/,/^ *$/p" $configfile | grep "ds-cfg-db-cache-.*: "`
	getParameter "dn: ds-cfg-backend-id=${backend},cn=Backends,cn=config" "${configfile}" "ds-cfg-db-cache-size" "cacheSize"
	getParameter "dn: ds-cfg-backend-id=${backend},cn=Backends,cn=config" "${configfile}" "ds-cfg-db-cache-percent" "cachePercent"
	dbcachesizevalue=`echo "${cacheSize}" | awk '{print $1}'`
	debug "DEBUG cacheSize [$cacheSize] cachePercent [$cachePercent] dbcachesizevalue [$dbcachesizevalue]"

	if [ "${cacheSize}" != "" -a "${dbcachesizevalue}" != "0" ]; then
		dbcache=${dbcachesizevalue}
		dbcachesizeunit=`echo "${cacheSize}" | awk '{print $2}' | sed "s/megabytes/mb/"`
		dbcachesizing="${dbcachesizeunit}"
		totaldbcachesz=`expr ${totaldbcachesz} + ${dbcachesizevalue}`
	elif [ "${cachePercent}" != "" -a "${cacheSize}" = "" -o "${cachePercent}" != "" -a "${dbcachesizevalue}" = "0" ]; then
		dbcache=${cachePercent}
		dbcachesizing="%"
		totaldbcachepct=`expr ${totaldbcachepct} + ${cachePercent}`
	else
		dbcache="50"
		cachePercent="50"
		dbcachesizing="%"
		totaldbcachepct=`expr ${totaldbcachepct} + ${cachePercent}`
	fi

	logcache=`sed -n "/dn: ds-cfg-backend-id=${backend},cn=Backends,cn=config/,/^ *$/p" $configfile | grep "ds-cfg-db-log-filecache-size: " | sed "s/ds-cfg-db-log-filecache-size: //"`
	compression=`sed -n "/dn: ds-cfg-backend-id=${backend},cn=Backends,cn=config/,/^ *$/p" $configfile | grep "ds-cfg-entries-compressed: " | sed "s/ds-cfg-entries-compressed: //" | tr [:upper:] [:lower:]`
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
			alerts="${alerts} Backends:${REDBA}${red}Excessive~Global~Index~Limit~Set${nocolor}${FEND}.KBI101"
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
		if [ "$backendType" = "Impl" -o "$backendType" = "" ]; then
			backendType="JE"
		fi
		if [ "$confidentiality" = "" ]; then
			confidentiality=false""
		else
			prodModeCheck1="1"
		fi
	enabled=`sed -n "/dn: ds-cfg-backend-id=${backend},cn=Backends,cn=config/,/^ *$/p" $configfile | grep "ds-cfg-enabled: " | sed "s/ds-cfg-enabled: //" | tr [:upper:] [:lower:]`
	backendEnabledCheck=`echo ${enabled} | grep '|'`
	if [ $? = 0 ]; then
		enabled=`echo ${enabled} | sed "s/|/ /" | awk '{print $2}' | sed "s/\}//"`
	fi
	if [ "${enabled}" = "false" -o "${enabled}" = "FALSE" ]; then
		disabledBackends="${backend}"
		healthScore "Backends" "RED"
	fi

	for thisbase in $basedn; do
		getBackendEntries "${backend}" "${thisbase}"

		# Get a total count of all backends entries
		if [ "${entries}" != "NA" ]; then
			totalentries=`expr ${totalentries} + ${entries}`
		fi
			displayBase="${thisbase}"
			hide "displayBase" "${displayBase}" "*"

		if [ "$printedbackend" = "0" -a "$currentbase" = "$thisbase" ]; then
			printf "%-${tab}s\t%-${btab}s\t%-9s\t%s\t%s\t%-10s\t%s\t\t%s\t%s\n" ${backend} ${displayBase} "${dbcache}${dbcachesizing}" ${enabled} ${limit} "${logcache}/${jdbFiles}" ${confidentiality} "Com3" "${entries}" | log
		
			printedbackend=1
			currentbase=$thisbase
		elif [ "$printedbackend" = "1" -a "$currentbase" != "$thisbase" ]; then
			if [ "${enabled}" = "false" ]; then
				entriesaddin="*"
			else
				entriesaddin=""
			fi
			printf "%-${tab}s\t%-${btab}s\t%-9s\t%s\t%s\t%-10s\t\t%s\t%s\t%s\t%s\n" " " "${displayBase}" " " " " " " " " " " " " " " "${entries}" | log
			printedbackend=1
		else
			if [ "${enabled}" = "false" ]; then
				entriesaddin="*"
			else
				entriesaddin=""
			fi
			printf "%-${tab}s\t%-${btab}s\t%-9s\t%s\t%s\t%-10s\t%s\t%s\t\t%s\t%s\t%s\n" "${backend}" "${displayBase}" "${dbcache}${dbcachesizing}" "${enabled}" "${limit}" "${logcache}/${jdbFiles}" ${backendType} ${confidentiality} "${compression}" "${entries} ${entriesaddin}" | log
			printedbackend=1
			currentbase=$thisbase
		fi
			limit=''
			cachePercent=""
			cacheSize=""
	done
	fi
			printedbackend=0
done

			if [ "${compactversion}" -ge "650" -a "${totaldbcachepct}" -gt "80" -a "${sharedCacheEnabled}" = "true" ]; then
				totaldbcachemsg=" ttl *"
			elif [ "${totaldbcachepct}" -gt "80" -a "${totaldbcachepct}" -lt "90" ]; then
				alerts="${alerts} Backends:${YELA}${yellow}Total~db-cache-percent~is~greater~than~80%~${sharedCacheAddInMsgAlert}${nocolor}${FEND}.KBI100"
				addKB "KBI100"
				totaldbcachemsg=" ttl *"
			elif [ "${totaldbcachepct}" -ge "90" ]; then
				alerts="${alerts} Backends:${REDBA}${red}Total~db-cache-percent~is~greater~than~90%~${sharedCacheAddInMsgAlert}${nocolor}${FEND}.KBI100"
				addKB "KBI100"
				totaldbcachemsg=" ttl *"
			else
				totaldbcachemsg=" ttl"
			fi
	printf "%-${tab}s\t%-${btab}s\t%-9s\t%s\t%s\t%-10s\t%s\t%s\t%s\t%s\n" "${backendDashes}" "${baseDnDashes}" "---------" "-------" "------" "---------" "----" "----------" "-----" "-------" | log
	if [ "${totaldbcachepct}" -gt "0" ]; then
	printf "%-${tab}s\t%-${btab}s\t%-9s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" "         " "      " "${totaldbcachepct}% ${totaldbcachemsg}" "       " "      " "        " "    " "          " "     " "${totalentries}" | log
	fi
	if [ "${totaldbcachesz}" -gt "0" ]; then
	printf "%-${tab}s\t%-${btab}s\t%-9s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" "         " "      " "${totaldbcachesz}${dbcachesizeunit} ${totaldbcachemsg}" "       " "      " "        " "    " "          " "     " " " | log
	fi

			if [ "${compactversion}" -ge "650" -a "${sharedCacheEnabled}" = "true" ]; then
				printf "\n\t%s\n" "Info: The JE shared-cache is enabled. The db-cache-percent & db-cache-size settings are ignored." | log
				alerts="${alerts} Backends:Info:~The~JE~shared-cache~is~enabled.~The~db-cache-percent~&~db-cache-size~settings~are~ignored.KBI105"
				addKB "KBI105"
			fi
			if [ "${compactversion}" -ge "650" -a "${totaldbcachepct}" -le "80" -a "${sharedCacheEnabled}" = "false" ]; then
				printf "\n\t%s\n" "Info: ${sharedCacheAddInMsg}." | log
			fi
			if [ "${totaldbcachepct}" -gt "80" -a "${totaldbcachepct}" -lt "90" -a "${sharedCacheEnabled}" = "false" ]; then
				printf "\n\t%s\n" "${YELB}${yellow}Warning: Total db-cache-percent is greater than 80%. ${sharedCacheAddInMsg}${nocolor}${FEND}" | log
			fi
			if [ "${totaldbcachepct}" -ge "90" -a "${sharedCacheEnabled}" = "false" -o "${totaldbcachepct}" -ge "90" -a "${sharedCacheEnabled}" = "" ]; then
				printf "\n\t%s\n" "${REDB}${red}Alert: Total db-cache-percent is greater than 90%. ${sharedCacheAddInMsg}${nocolor}${FEND}" | log
				healthScore "Backends" "RED"
			fi
			if [ "${compression}" = "true" -a "${compactversion}" -lt "650" ]; then
				alerts="${alerts} Backends:Entry~Compression~is~on,~at~risk~of~hitting~OPENDJ-5137.KBI102"
				addKB "KBI102"
				printf "\n\t%s\n" "${REDB}${red}Alert: Entry Compression is on, at risk of hitting OPENDJ-5137${nocolor}${FEND}" | log
				healthScore "Backends" "RED"
			fi
			if [ "${backendAlert}" != "" ]; then
				echo "\n\t${REDB}${red}Alert: ${backendAlert}${nocolor}${FEND}\n" | log
				if [ "${backendException}" ]; then
					echo "\t${backendException}"
					healthScore "Backends" "RED"
				fi
			fi
			if [ "${excesssiveGlobalLimit}" ]; then
				printf "\n\t%s\n" "${REDB}${red}Warning: Excessive Global Index Limit Set - ${excesssiveGlobalLimit}${nocolor}${FEND}" | log
			fi

		# Check for FSync limits or Latch timeout errors
		for backend in $backends; do
			if [ -a ../logs/${backend}/je.info.0 ]; then
				fsyncCheck=`grep "FSync time of" ../logs/${backend}/je.info.0 | tail -1`
				fsyncDateLast=`echo ${fsyncCheck} | awk '{print $1 "-" $2}'`
				fsyncTime=`echo ${fsyncCheck} | awk '{print $9}'`
				latchTimeoutCheck=`grep "Latch timeout" ../logs/${backend}/je.info.0 | tail -1`
			fi
			if [ "${fsyncCheck}" != "" -o "${latchTimeoutCheck}" != "" ]; then
				if [ "${fsyncCheck}" != "" ]; then
					fatalalerts="${fatalalerts} Backends:${REDBA}${red}Backend~${backend}~encountered~FSync~issues:~FSync~${fsyncTime}.~Last~event:~${fsyncDateLast}.${nocolor}${FEND}KBI106"
					printf "\n\t%s\n" "${REDB}${red}Alert: Backend ${backend} encountered FSync issues: FSync time of ${fsyncTime} ms exceeds limit (5000 ms). Last event: ${fsyncDateLast}${nocolor}${FEND}" | log
					healthScore "Backends" "RED"
					addKB "KBI106"
				fi
				if [ "${latchTimeoutCheck}" != "" ]; then
					fatalalerts="${fatalalerts} Backends:${REDBA}${red}Backend~${backend}~encountered~a~Latch~Timeout~exception.${nocolor}${FEND}KBI106"
					printf "\n\t%s\n" "${REDB}${red}Alert: Backend ${backend} encountered a Latch Timeout exception${nocolor}${FEND}" | log
					printf "\n\t%s\n" "Exception: ${REDB}${red}${latchTimeoutCheck}${nocolor}${FEND}" | log
					healthScore "Backends" "RED"
					addKB "KBI106"
				fi
			fi
		done
			if [ "${disabledBackends}" != "" ]; then
				for thisDisabledBackend in ${disabledBackends}; do
					alerts="${alerts} Backends:${REDBA}${red}Backend~${backend}~is~disabled.${nocolor}${FEND}KBI107"
					printf "\n\t%s\n" "${REDB}${red}Alert: Backend ${thisDisabledBackend} is disabled *${nocolor}${FEND}" | log
					addKB "KBI107"
				done
			fi
	printKey

	if [ "${Backends}" != "RED" -o "${Backends}" != "YELLOW" ]; then
		healthScore "Backends" "GREEN"
	fi
}

printJvmInfo()
{
	jvmargs=$1
	# print the JVM in a more readable format
	for arg in $jvmargs; do
		if [ `echo "${arg}" | grep -i 'UseCompressedOops'` ]; then
			addon="<-- ${GRNB}${green}-XX:+UseCompressedOops used!${nocolor}${FEND}"
			usecompressedoops=1
		elif [ `echo "${arg}" | grep -i ':MaxTenuringThreshold'` ]; then
			maxTenuringThresholdValue=`echo "${arg}" | sed "s/=/ /; "s/\"//g"; s/,//g" | awk '{print $2}'`
			if [ "${maxTenuringThresholdValue}" = "1" ]; then
				addon="<-- ${GRNB}${green}-XX:MaxTenuringThreshold used!${nocolor}${FEND}"
			else
				addon="<-- ${YELB}${yellow}-XX:MaxTenuringThreshold is used but is not set to 1. 1 is required for proper db-caching and faster GC's${nocolor}${FEND}"
			fi
		elif [ `echo "${arg}" | grep -i 'UseConcMarkSweepGC'` ]; then
			addon="<-- ${GRNB}${green}-XX:UseConcMarkSweepGC used!${nocolor}${FEND}"
			collectorinuse=1
			collectorType='UseConcMarkSweepGC'
		elif [ `echo "${arg}" | grep -i 'UseG1GC'` ]; then
			addon="<-- ${GRNB}${green}-XX:UseG1GC used!${nocolor}${FEND}"
			collectorinuse=1
			collectorType='UseG1GC'
		elif [ `echo "${arg}" | grep -i 'DisableExplicitGC'` ]; then
			addon="<-- ${GRNB}${green}-XX:DisableExplicitGC used!${nocolor}${FEND}"
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
		elif [ `echo "${arg}" | grep -i 'NewSize'` ]; then
			NewSize=`echo ${arg} | sed "s/.*NewSize=//; s/\",//; s/\"$//"`
			NewSizeValue=`echo ${NewSize} | sed "s/\",//; s/\"$//; s/.$//"`
			NewSizeUnit=`echo ${NewSize} | sed "s/\",//; s/\"$//; s/$NewSizeValue//" | tr [:upper:] [:lower:]`
			NewSizeUnitCheck=`echo "$NewSizeUnit" | grep -E ^\-?[0-9]+$`
				if [ "${NewSizeUnitCheck}" != "" ]; then
					NewSizeUnit="k"
				fi
			NewSizeInUse=1
		elif [ `echo "${arg}" | grep -i 'agentpath'` ]; then
			arg="-agentpath:/path/redacted"
		elif [ `echo "${arg}" | grep -i 'HSM'` ]; then
			arg="-D_INFO=parameterredacted"
		elif [ `echo "${arg}" | grep -i 'org.glassfish.grizzly.memory.HeapMemoryManager'` ]; then
			defaultMemManagerOn=1
		elif [ `echo "${arg}" | grep -i ':TieredStopAtLevel'` ]; then
			addon="<-- ${REDB}${red}-XX:TieredStopAtLevel=1 used!${nocolor}${FEND}"
			TieredStopAtLevel=1
		else
			addon=''
		fi
		if [ `echo ${Xmxvalue} | grep -i 'g' ` ]; then
			XmxGbValue=`echo ${Xmxvalue} | sed 's/[^0-9]*//g'`
			XmxGbNumericalValue=`echo ${XmxGbValue} | sed 's/GB//g'`
		elif [ `echo ${Xmxvalue} | grep -i 'm' ` ]; then
			XmxGbValue=`echo ${Xmxvalue} | sed 's/[^0-9]*//g;  s/\..*$//; s/ //g' | awk '{ byte =$1 /1000 ; print byte " MB" }'`
			XmxGbNumericalValue=`echo ${XmxGbValue} | sed 's/MB//g'`
		else
			XmxGbValue=`echo ${Xmxvalue} | sed 's/[^0-9]*//g' | awk '{ byte =$1 /1000/1000 ; print byte " GB" }'`
			XmxGbNumericalValue=`echo ${XmxGbValue} | sed 's/GB//g'`
		fi
		# Remove after a dot
		XmxGbNumericalValue=`echo "${XmxGbNumericalValue}" | sed "s/\..*$//; s/ //g"`
		
		if [ "${XmxInUse}" != "" -a "${XmsInUse}" != "" -a "${Xmxvalue}" = "${Xmsvalue}" -a "${minMaxAlert}" = "" ]; then
			minMaxAlert=1
			addon="<-- ${GRNB}${green}-Xmx is the same as the -Xms value (good)${nocolor}${FEND}"
		fi
		# NEEDS WORK?
		debug "DEBUG -> \"${XmxInUse}\" != \"\" -a \"${XmxGbValue}\" -lt \"2\""
		debug  "XmxGbNumericalValue - $XmxGbNumericalValue"
		if [ "${debug}" = "1" ]; then
		if [ "${XmxInUse}" != "" -a "${XmxGbNumericalValue}" -lt "2" ]; then
			minMaxAlert=1
			addon="<-- ${REDB}${red}-Xmx is under 2GB for a production server${nocolor}${FEND}"
		fi
		fi
		printf "\t%-29s%s\n" "${arg}" "${addon}" | log

		# unset the addon message so that other options don't print the same addon msg.
		addon=''
	done
		if [ "${javaShortVersion}" = "11" -a "${collectorType}" = "" -o "${javaShortVersion}" = "11" -a "${collectorType}" = "default" ]; then
			printf "\t%-29s%s\n" "-XX:UseG1GC" "<-- ${GRNB}${green}-XX:UseG1GC default collector in use${nocolor}${FEND}" | log
			collectorinuse=1
			collectorType='default'
		fi
}

getLoggerInfo()
{
printf "\n%s\n" "${HR2}" | log
printf "%s\n" "${H4B}LOG HANDLER INFORMATION:${H4E}" | log
printf "\n%s\n" "${loghandlerinfo}" | log
printf "%s\n" "${HR3}" | log
	printf "${PREB}" | log

	loggers=`sed -n "/cn=Loggers,cn=config/,/^ *$/p" ${configfile} | grep "dn: " | grep -vE "dn: cn=Loggers,cn=config|cn=Filtering Criteria" | sed "s/,cn=Loggers,cn=config//; s/dn: cn=//; s/ /~/g"`
	# Get the longest logger name
	longestLoggerName=0
	for loggerName in ${loggers}; do
		thisLen=${#loggerName}
		if [ "${thisLen}" -gt "${longestLoggerName}" ]; then
			longestLoggerName=${thisLen}
		fi
	done
	getDashes "${longestLoggerName}"

	printf "\n%-${longestLoggerName}s : %-15s : %-15s \n" "Log Handler" "Enabled" "Filtering Policy" | log
	printf "%-${longestLoggerName}s:%-17s:%-15s\n" "${dashes}-" "-----------------" "-----------------:" | log

	for logger in ${loggers}; do
		logger=`echo ${logger} | sed "s/~/ /g"`
		loggerName=`echo ${logger} | sed "s/ /~/g"`
		getParameter "dn: cn=${logger},cn=Loggers,cn=config" "${configfile}" "ds-cfg-enabled" "loggerenabled"
		getParameter "dn: cn=${logger},cn=Loggers,cn=config" "${configfile}" "ds-cfg-filtering-policy" "loggerfilter"
		loggerName=`echo ${logger} | sed "s/~/ /g"`
		printf "%-${longestLoggerName}s : %-15s : %-15s : %s" "${loggerName}" "${loggerenabled}" "${loggerfilter}" | log
			if [ "${loggerfilter}" = "" ]; then
				loggerfilter="no-filtering"
			fi
			if [ "${loggerenabled}" = "false" ]; then
				if [ "${logger}" = "File-Based Audit Logger" -o "${logger}" = "File-Based Debug Logger" ]; then
					printf "\n" "" | log
					continue
				fi
				loggerName=`echo ${logger} | sed "s/ /~/g"`
				printf "%s" "${YELBA}${yellow}Warning: Logger is Disabled${nocolor}${FEND}" | log
				alerts="${alerts} Logging:${YELBA}${yellow}Warning:~Logger~is~Disabled~[${loggerName}]${nocolor}${FEND}"
			fi
			if [ "${loggerenabled}" = "true" ]; then
				if [ "${logger}" = "File-Based Audit Logger" -o "${logger}" = "File-Based Debug Logger" ]; then
				loggerName=`echo "${logger}" | sed "s/ /~/g"`
				printf "%s" "${REDB}${red}Alert: Heavyweight Logger is Enabled${nocolor}${FEND}" | log
				alerts="${alerts} Logging:${REDB}${red}Alert:~Heavyweight~Logger~is~Enabled~[${loggerName}]${nocolor}${FEND}"
				fi
			fi
			printf "\n" "" | log
		loggerenabled=''
		loggerfilter=''
	done
}

getJVMInfo()
{
printf "\n%s\n" "${HR2}" | log
printf "%s\n" "${H4B}JVM ARGS & SYSTEM INFORMATION:${H4E}" | log
printf "\n%s\n" "${jvminfo}" | log
printf "%s\n" "${HR3}" | log
	printf "${PREB}" | log

	NewSizeValue=0
	NewSizeInUse=0
	NewSizeUnit=''
	collectorType=''

	if [ "${monitorfile}" != "" ]; then
			javaVersion=`grep -iE 'javaVersion|ds-mon-jvm-java-version' ${monitorfile} | awk '{print $2}'`
			jvmFileFound=1
			javaShortVersion=`echo ${javaVersion} | cut -c3`
			if [ "${javaShortVersion}" = '.' ]; then
				javaShortVersion=`echo ${javaVersion} | cut -c1-2`
			fi
			debug "javaShortVersion->$javaShortVersion"
		printf "\t%-16s  %s\n" "Java Version" "$javaVersion" | log
			javaVendor=`grep -iE 'javaVendor|ds-mon-jvm-java-vendor' ${monitorfile} | sed "s/.*: //"`
		printf "\t%-16s  %s\n" "Java Vendor" "$javaVendor" | log
			usedMemory=`grep -iE 'usedMemory|ds-mon-jvm-memory-used' ${monitorfile} | head -1 | awk '{print $2}'`
			usedMemoryGb=`echo ${usedMemory} | awk '{ byte =$1 /1024/1024**2 ; print byte " GB" }'`
			printf "\t%-16s  %s\n" "Used Memory" "$usedMemory (${usedMemoryGb})" | log
			maxMemory=`grep -iE 'maxMemory|ds-mon-jvm-memory-max' ${monitorfile} | awk '{print $2}'`
			maxMemoryGb=`echo ${maxMemory} | awk '{ byte =$1 /1024/1024**2 ; print byte " GB" }'`
			printf "\t%-16s  %s\n" "Max Memory" "$maxMemory (${maxMemoryGb})" | log
		if [ -s ../node/diskInfo ]; then
			availSpace=`awk '{print $14}' ../node/diskInfo` 
			availSpaceGb=`echo ${availSpace} | awk '{ byte =$1 /1024/1024**2 ; print byte " GB" }'`
			printf "\t%-16s  %s\n" "Avail Diskspace" "${availSpace} ($availSpaceGb)" | log
		fi
		printf "\t%-16s\n" "Disk state monitor" | log
		diskMonitors=`grep "dn: ds-mon-disk-root=.*,cn=disk space monitor,cn=monitor" "${monitorfile}" | sed "s/ /~/g"`
		for diskMonitor in ${diskMonitors}; do
			diskMonitor=`echo ${diskMonitor} | sed "s/~/ /g"`
			diskRoot=`echo "${diskMonitor}" | sed "s/,/ /" | awk '{print $2}'`
			getParameter "${diskMonitor}" "${monitorfile}" "ds-mon-disk-state" "diskState"
			if [ "${diskState}" = "full" ]; then
				printf "\t\t\t - %s\n" "${REDB}${red}Fatal Issue: Disk is Full! [${diskRoot}]${nocolor}${FEND}" | log
				fatalalerts="${fatalalerts} System:${REDB}${red}Fatal~Issue:~Disk~is~Full!${nocolor}${FEND}~[${diskRoot}]."
			elif [ "${diskState}" = "low" ]; then
				printf "\t\t\t - %s\n" "${YELBA}${yellow}Warning: Disk Space is Low [${diskRoot}]${nocolor}${FEND}" | log
				alerts="${alerts} System:${YELBA}${yellow}Warning:~Disk~Space~is~Low~[${diskRoot}]${nocolor}${FEND}."
			else
				printf "\t\t\t - %s\n" "${GRNB}${green}Info: Disk Space is Normal. [${diskRoot}]${nocolor}${FEND}" | log
			fi
		done
			availableCPUs=`grep -iE 'availableCPUs|ds-mon-jvm-available-cpus' ${monitorfile} | awk '{print $2}'`
        		if [ "${availableCPUs}" = "" ]; then
				availableCPUs='0'
			fi
		printf "\t%-16s  %s\n\n" "available CPUs" "$availableCPUs" | log
        		if [ "${availableCPUs}" -lt "2" -a "${availableCPUs}" != "0" ]; then
				alerts="$alerts System:${REDBA}${red}Only~${availableCPUs}~CPU~available.~Performance~can~suffer.${nocolor}${FEND}KBI601"
				addKB "KBI601"
				printf "\t%-54s\t%s\n\n" "${REDB}${red}Alert: ${availableCPUs} CPU's available. Performance can suffer${nocolor}${FEND}" "*" | log
			fi
			operatingSystem=`grep -iE 'operatingSystem|ds-mon-os-version' ${monitorfile} | awk '{print $2}'`
		printf "\t%-16s  %s\n\n" "Operating System" "$operatingSystem" | log
	else
		if [ -s ../logs/server.out ]; then
			javaInfo=`grep -iE 'JVM Information' ../logs/server.out | sed "s/^.*msg=JVM Information://; s/,.*-bit architecture.*$//"`
			javaVersion=`echo "${javaInfo}" | awk '{print $1}'`
			jvmFileFound=1
			javaShortVersion=`echo ${javaVersion} | cut -c3`
			if [ "${javaShortVersion}" = '.' ]; then
				javaShortVersion=`echo ${javaVersion} | cut -c1-2`
			fi
			debug "javaShortVersion->$javaShortVersion"
		fi
		if [ "${javaVersion}" = "" -a -s ../logs/errors ]; then
			javaInfo=`grep -iE 'JVM Information' ../logs/errors | head -1 | sed "s/^.*msg=JVM Information://; s/,.*-bit architecture.*$//"`
			javaVersion=`echo "${javaInfo}" | awk '{print $1}'`
			jvmFileFound=1
			javaShortVersion=`echo ${javaVersion} | cut -c3`
			if [ "${javaShortVersion}" = '.' ]; then
				javaShortVersion=`echo ${javaVersion} | cut -c1-2`
			fi
			debug "javaShortVersion->$javaShortVersion"
		fi
		if [ "${javaVersion}" != "" ]; then
			javaVendor=`echo "${javaInfo}" | sed "s/ ${javaVersion} //; s/by //"`
			printf "\t%-16s  %s\n" "javaVersion" "$javaVersion" | log
			printf "\t%-16s  %s\n\n" "javaVendor" "$javaVendor" | log
		fi
	fi

		collapsedJavaVersion=`echo ${javaVersion} | sed "s/\.//g; s/_//g; s/[+-].*$//g"`
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
			printf "\t%s" "JVM Arguments not available" | log
		fi
	else
		printf "\t%s\n" "server.out log not available" | log
	fi

	printf "\n" | log

   if [ "${jvmFileFound}" = "1" ]; then
		printf "\n%-26s\t%s\n\n" "JVM issues found" | log
	# Check for 64-Bit Server VM warning's in the server.out
	if [ "${serverOutFile}" != "" ]; then
		jvmWarnings=`grep '64-Bit Server VM warning' ${serverOutFile} | sort -u | sed "s/ /~/g"`
	fi
	if [ "${jvmWarnings}" != "" ]; then
		for jvmWarning in ${jvmWarnings}; do
			alerts="$alerts JVM:${YELBA}${yellow}${jvmWarning}${nocolor}${FEND}"
			printf "\t%s\n" "${YELB}${yellow}Warning: `echo ${jvmWarning} | sed 's/~/ /g'`${nocolor}${FEND}"
		done
		healthScore "JVMTuning" "YELLOW"
	fi
        if [ "${collectorinuse}" != "1" ]; then
		alerts="$alerts JVM:${REDBA}${red}-XX:+UseConcMarkSweepGC~or~-XX:+UseG1GC~not~used${nocolor}${FEND}"
		printf "\t%-74s\t%s\n" "${REDB}${red}Alert: -XX:+UseConcMarkSweepGC or -XX:+UseG1GC missing${nocolor}${FEND}" "*" | log
		healthScore "JVMTuning" "RED"
		tuningKBNeeded=1
	fi
        if [ "${Xmx}" = "" ]; then
		alerts="$alerts JVM:${REDBA}${red}-Xmx~not~defined${nocolor}${FEND}"
		printf "\t%-74s\t%s\n" "${REDB}${red}Alert: -Xmx missing${nocolor}${FEND}" "*" | log
		tuningKBNeeded=1
	fi
        if [ "${Xms}" = "" ]; then
		alerts="$alerts JVM:${REDBA}${red}-Xms~not~defined${nocolor}${FEND}"
		printf "\t%-74s\t%s\n" "${REDB}${red}Alert: -Xms missing${nocolor}${FEND}" "*" | log
	fi

        if [ "${usecompressedoops}" != "1" ]; then
		if [ "${XmxGbNumericalValue}" -lt "32" -o "${XmxGbNumericalValue}" = "0" ]; then
			alerts="$alerts JVM:${REDBA}${red}-XX:+UseCompressedOops~not~used${nocolor}${FEND}"
			printf "\t%-74s\t%s\n" "${REDB}${red}Alert: -XX:+UseCompressedOops missing${nocolor}${FEND}" "*" | log
		fi
	fi
        if [ "${maxTenuringThresholdValue}" = "" ]; then
		alerts="$alerts JVM:${REDBA}${red}-XX:MaxTenuringThreshold=1~not~used${nocolor}${FEND}"
		printf "\t%-74s\t%s\n" "${REDB}${red}Alert: -XX:MaxTenuringThreshold=1 missing${nocolor}${FEND}" "*" | log
		healthScore "JVMTuning" "RED"
		tuningKBNeeded=1
	else
        	if [ "${maxTenuringThresholdValue}" -gt "1" ]; then
			alerts="$alerts JVM:${REDBA}${red}-XX:MaxTenuringThreshold~value~(${maxTenuringThresholdValue}),~must~be~set~to~1${nocolor}${FEND}"
			printf "\t%-74s\t%s\n" "${REDB}${red}Alert: -XX:MaxTenuringThreshold value (${maxTenuringThresholdValue}), must be set to 1.${nocolor}${FEND}" "*" | log
			healthScore "JVMTuning" "RED"
			tuningKBNeeded=1
		fi
	fi
	if [ "${XmxGbNumericalValue}" -ge "32" -a "${usecompressedoops}" = "1" ]; then
		minMaxAlert=1
		addon="<-- ${REDB}${red}-Xmx is 32GB or above. -XX:+UseCompressedOops is not needed${nocolor}${FEND}"
		alerts="$alerts JVM:${YELBA}${yellow}-Xmx~is~32GB~or~above.~-XX:+UseCompressedOops~is~not~needed${nocolor}${FEND}"
		printf "\t%-74s\t%s\n" "${REDB}${red}Alert: -Xmx is 32GB or above. -XX:+UseCompressedOops is not needed.${nocolor}${FEND}" "*" | log
	fi
        if [ "${minMaxAlert}" != "1" -a "${XmxInUse}" != "" -a "${XmsInUse}" != "" ]; then
		alerts="$alerts JVM:${REDBA}${red}-Xmx~should~be~the~same~as~-Xms~and~is~not${nocolor}${FEND}"
		printf "\t%-74s\t%s\n" "${REDB}${red}Alert: -Xmx (${Xmx}) are not equal -Xms (${Xms})${nocolor}${FEND}" "*" | log
		healthScore "JVMTuning" "RED"
		tuningKBNeeded=1
	fi
        if [ "${NewSizeInUse}" = "1" -a "${NewSizeValue}" -gt "2" -a "${NewSizeUnit}" != "m" -a "${NewSizeUnit}" != "k" -a "${collectorType}" != "UseG1GC" ]; then
		alerts="$alerts JVM:${REDBA}${red}-XX:NewSize~is~set~to~${NewSize}~but~should~be~no~greater~than~2G${nocolor}${FEND}"
		printf "\t%-74s\t%s\n" "${REDB}${red}Alert: -XX:NewSize is set to ${NewSize} but should be no greater than 2G${nocolor}${FEND}" "*" | log
		healthScore "JVMTuning" "RED"
		tuningKBNeeded=1
	fi
        if [ "${NewSizeInUse}" = "1" -a "${collectorType}" = "UseG1GC" ]; then
		alerts="$alerts JVM:${REDBA}${red}-XX:NewSize~should~be~removed~when~-XX:UseG1GC~is~set${nocolor}${FEND}"
		printf "\t%-74s\t%s\n" "${REDB}${red}Alert: -XX:NewSize should be removed when -XX:UseG1GC is set${nocolor}${FEND}" "*" | log
		healthScore "JVMTuning" "RED"
		tuningKBNeeded=1
		addKB "KBI603"
	fi
        if [ "${TieredStopAtLevel}" = "1" ]; then
		alerts="$alerts JVM:${REDBA}${red}-XX:TieredStopAtLevel=1~is~for~client~tools~only.~Performance~may~suffer!${nocolor}${FEND}KBI612"
		printf "\t%-74s\t%s\n" "${REDB}${red}Alert: -XX:TieredStopAtLevel=1 is for client tools only. Performance may suffer!${nocolor}${FEND}" "*" | log
		healthScore "JVMTuning" "RED"
		tuningKBNeeded=1
		addKB "KBI612"
	fi
        if [ "${jmxportenabled}" = "enabled" -a "${DisableExplicitGCInUse}" = "" ]; then
		alerts="$alerts JVM:${REDBA}${red}JMX~Handler~enabled~without~-XX:+DisableExplicitGC~-~Full~GC~(System.gc())s~will~happen!${nocolor}${FEND}"
		printf "\t%-74s\t%s\n" "${REDB}${red}Alert: JMX Handler enabled without -XX:+DisableExplicitGC - Full GC (System.gc())s will happen!${nocolor}${FEND}" "*" | log
		healthScore "JVMTuning" "RED"
		tuningKBNeeded=1
	fi

	if [ "${javaShortVersion}" = "8" -a "${collectorType}" = "" -o "${javaShortVersion}" = "8" -a "${collectorType}" = "default" ]; then
		alerts="$alerts JVM:${REDBA}${red}Default~ParallelGC~collector~in~use,~Stop~The~World~GCs~will~happen${FEND}${nocolor}"
		healthScore "JVMTuning" "RED"
		printf "\t%-74s\t%s\n" "${REDB}${red}Alert: Default ParallelGC collector in use, Stop The World GC's will happen!!${nocolor}${FEND}" "*" | log
		#collectorType='default'
	fi
        if [ "${gclogging}" != "1" ]; then
		alerts="$alerts JVM:${YELBA}${yellow}GC~Logging~not~enabled${nocolor}${FEND}"
		printf "\t%-74s\t%s\n" "${YELB}${yellow}Warning: GC Logging not enabled${nocolor}${FEND}" "*" | log
		addKB "KBI602"
	fi
	if [ "${javaShortVersion}" != "" -a "${collectorType}" != "" ]; then
		if [ "${javaShortVersion}" -lt "11" -a "${collectorType}" = "UseG1GC" ]; then
			alerts="$alerts JVM:${YELBA}${yellow}G1~Collector~in~use~with~JDK~${javaShortVersion}.~G1~bugs~fixed~in~JDK~11.${nocolor}${FEND}"
			printf "\t%-74s\t%s\n" "${YELB}${yellow}Alert: G1 Collector in use with JDK ${javaShortVersion}. G1 bugs fixed in JDK 11.${nocolor}${FEND}" "*" | log
			healthScore "JVMTuning" "YELLOW"
		fi
	fi

	if [ "${javaShortVersion}" = "11" -a "${collapsedJavaVersion}" -le "1103" ]; then
		if [ "${ldapporttlsv13}" = "TLSv1.3" -o "${ldapsporttlsv13}" = "TLSv1.3" -o "${ttlsv13mon}" = "TLSv1.3" ]; then
			alerts="$alerts JVM:${YELBA}${yellow}TLSv1.3~in~use~with~JDK~11.0.3~or~older.~TLSv1.3~bugs~exist.${nocolor}${FEND}KBI609"
			addKB "KBI609"
			printf "\t%-74s\t%s\n" "${YELB}${yellow}Alert: TLSv1.3 in use with JDK 11.0.3 or older. TLSv1.3 bugs exist.${nocolor}${FEND}" "*" | log
		fi
	fi

	# OPENDJ-5260 is fixed in 6.5.0 and was backported to 5.5.2
	if [ "${compactversion}" = "400" -o "${compactversion}" = "550" -o "${compactversion}" = "551" ]; then
		if [ "${defaultMemManagerOn}" = "" ]; then
			alerts="$alerts JVM:${YELBA}${yellow}Grizzly~pre-allocated~MemoryManager~in~use,~use~workaround${nocolor}${FEND}.KBI610"
			addKB "KBI610"
			printf "\t%-74s\t%s\n" "${YELB}${yellow}Info: Grizzly pre-allocated MemoryManager in use, use workaround.${nocolor}${FEND}" "*" | log
			healthScore "JVMTuning" "YELLOW"
			tuningKBNeeded=1
		fi
	else
		if [ "${defaultMemManagerOn}" = "1" ]; then
			alerts="$alerts JVM:${YELBA}${yellow}Grizzly~HeapMemoryManager~used,~workaround~can~be~removed${nocolor}${FEND}.KBI610"
			addKB "KBI610"
		printf "\t%-74s\t%s\n" "${YELB}${yellow}Info: Grizzly HeapMemoryManager used, OPENDJ-5260 workaround can be removed.${nocolor}${FEND}" "*" | log
			healthScore "JVMTuning" "YELLOW"
			tuningKBNeeded=1
		fi
	fi

	if [ "${tuningKBNeeded}" = "1" ]; then
		addKB "KBI600"
		printf "\n\t%-74s\t%s\n" "${REDB}${red}JVM tuning is needed, for the above issues${nocolor}${FEND}" "*" | log
		if [ "${embeddedFound}" = "Embedded DJ Instance"  ]; then
			printf "\t%-74s\t%s\n" "${REDB}${red}Tuning for Embedded DJ must be done within the Container JVM${nocolor}${FEND}" "*" | log
			healthScore "JVMTuning" "RED"
		fi
	fi
   fi
	if [ "${JVMTuning}" != "RED" -a "${JVMTuning}" != "YELLOW" ]; then
		healthScore "JVMTuning" "GREEN"
		printf "\t%-74s\t%s\n" "${GRNB}${green}No JVM issues found${nocolor}${FEND}" "*" | log
	fi
	printf "${PREE}" | log
}

printCertInfo()
{
	connectorName=$1
	certStoreFileParam=$3
	connectorDisplayName=$3

	# Get the cert from the cn=config entry
	# -> connectorName dn: cn=LDAPS Connection Handler,cn=connection handlers,cn=config
	#	-> keyManagerEntry ds-cfg-key-manager-provider
	#		-> keyMgrPovider cn=Default Key Manager,cn=Key Manager Providers,cn=config
	#			-> ds-cfg-key-store-file config/keystore

	debug "\nconnectorName -> $connectorName"
	##connectorEnable=`sed -n "/${connectorName}/,/^ *$/p" ${configfile} | grep "ds-cfg-enabled:" | sed "s/ds-cfg-enabled: //" | tr [:upper:] [:lower:]`

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
	debug  "keyManagerEntry -> $keyManagerEntry"
	keyStore=`sed -n "/${keyManagerEntry}/,/^ *$/p" ${configfile} | grep "${keyStoreFileParam}:" | sed "s/${keyStoreFileParam}: //; s,/, ,g" | awk -F" " '{print $NF}'`
	debug "keyStore -> $keyStore"

	# Get the actual store info/expiration
	if [ "${certNick}" != "" -a "${keyManagerEntry}" != "NA" ]; then
		if [ -s ./security/${keyStore}-list ]; then
			if [ "${extractvertype}" = "script" -o "${extractvertype}" = "powershell" ]; then
				thisCertInfo=`sed -n "/^Alias name: ${certNick}/,/^ *$/p" ./security/${keyStore}-list | grep 'Valid from' | head -1 | sed "s/Valid from: //; s/ /~/g"`
			else
				thisCertInfo=`grep "^${certNick} " ./security/${keyStore}-list | sed "s/${certNick} ,//; s/ /~/g"`
			fi

			# For debugging purposes only
			#echo "=====CERT ${certNick}=====
			#$thisCertInfo
			#=====CERT=====
			#"
		else
		# the store is empty, return
			printf "%s\n" "${connectorDisplayName}" | log 
				hide "certNick" "${certNick}" "X"
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
			alerts="${alerts} Cert:${REDBA}${red}${certNick}~expired~or~expiring~soon.${nocolor}${FEND}KBI500"
			addin=" *"
			healthScore "Certificates" "RED"
		fi


		if [ "${thisCertExp}" != "" ]; then
			thisCertExp="From ${thisCertExp}${addin}"
		else
			thisCertExp="Unknown"
		fi
	thisCertType=`echo ${thisCertInfo} | sed "s/,/ /g" | awk -F" " '{print $NF}' | sed "s/~/ /g; s/^ //"`
		if [ "${thisCertType}" = "" ]; then
			thisCertType="Unknown"
		fi
	printf "%s\n" "${connectorDisplayName}" | log 
		hide "certNick" "${certNick}" "X"
	printf "\t\t%-12s\t%s\n" "Certificate" "${certNick}" | log 
	printf "\t\t%-12s\t%s\n" "Expiration" "${thisCertExp}" | log
	printf "\t\t%-12s\t%s" "Type" "${thisCertType}" | log
	if [ "${thisCertExpYear}" = "${thisYear}" -o "${thisCertExpYear}" -lt "${thisYear}" ]; then
		printf "\n\n" | log
		printf "\t%s" "${REDB}${red}Alert: The ${certNick} certificate is expired or expires soon${nocolor}${FEND}" | log
		addKB "KBI500"
		healthScore "Certificates" "RED"
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

printAciInfo()
{
printf "\n%s\n" "${HR2}" | log
printf "%s\n" "${H4B}ACI CONTROL INFORMATION:${H4E}" | log
printf "\n%s\n" "${accesscontrolinfo}" | log
printf "%s\n" "${HR3}" | log

if [ "${backendType}" = "Proxy" ]; then
	printf "\t%s\n\n" "No ACI's available...system could be a Proxy Server" | log
	return
fi

acis=`grep 'ds-cfg-global-aci:' ${configfile} | sed "s/ /~/g; s/[~|(]userdn/;userdn/; s/[~|(]groupdn/;groupdn/"`
aciNum=0
aciDescLen=0
aciSubLen=0

	for aci in $acis; do
		thisAciLen=`echo ${aci} | sed "s/;/ /g" | awk '{print $2}' | sed "s/\"$//; s/.*\"//; s/~/ /g" | awk '{ print length($0) }'`
		thisAciSubLen=`echo ${aci} | sed "s/;/ /g" | awk '{print $4}' | sed "s/[~\"()]//g; s/ldap:...//; s/^=//; s/=/\(/; s/$/\)/" | awk '{ print length($0) }'`
		if [ "${thisAciLen}" -gt "${aciDescLen}" ]; then
			aciDescLen=${thisAciLen}
		fi
		if [ "${thisAciSubLen}" -gt "${aciSubLen}" ]; then
			aciSubLen=${thisAciSubLen}
		fi
	done
		getDashes "${aciDescLen}"; aciDescDashes=${dashes}
		if [ "${hideSensitiveData}" = "1" ]; then
			aciSubDashes="--------------------------------"
		else
			getDashes "${aciSubLen}"; aciSubDashes=${dashes}
		fi

printf "${PREB}\n" | log
	printf "%-4s\t%-${aciDescLen}s\t%-35s\t%s\n" "" "Description" "Perms" "Subject" | log
	printf "%-4s\t%-${aciDescLen}s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" "     " "${aciDescDashes}" "-----------------------------------" "${aciSubDashes}" | log
for aci in $acis; do
	aciNum=`expr ${aciNum} + 1`
	aciDesc=`echo ${aci} | sed "s/;/ /g" | awk '{print $2}' | sed "s/\"$//; s/.*\"//; s/~/ /g"`

	aciPerms=`echo ${aci} | sed "s/;/ /g" | awk '{print $3}' | sed "s/~//g"`
	aciSubject=`echo ${aci} | sed "s/;/ /g" | awk '{print $4}' | sed "s/[~\"()]//g; s/ldap:...//; s/^=//; s/=/\(/; s/$/\)/"`

	if [ "${aciDesc}" = "" ]; then
		aciBase64Check=`echo ${aci} | grep 'ds-cfg-global-aci::'`
		if [ "${aciBase64Check}" != "" ]; then
			aciDesc="ACI is Base64 encoded"
			aciPerms='-'
			aciSubject='-'
		fi
	fi

	aciSubjectCheck=`echo "${aciSubject}" | grep '='`
	if [ "${hideSensitiveData}" = "1" -a "${aciSubjectCheck}" != "" ]; then
		aciSubject="********************************"
	fi
	printf "%-4s\t%-${aciDescLen}s\t%-35s\t%-30s\n" "[$aciNum]" "${aciDesc}" "${aciPerms}" "${aciSubject}" | log
done
printf "${PREE}" | log
	if [ "${aciBase64Check}" != "" ]; then
		printf "\n\t%s\n" "${YELB}${yellow}Alert: One or more ACI's are base64 encoded${nocolor}${FEND}" | log
		alerts="${alerts} ACIs:${YELBA}${yellow}One~or~more~ACI's~are~base64~encoded.${nocolor}${FEND}"
		addKB "KBI800"
		healthScore "AccessControls" "YELLOW"
	else
		healthScore "AccessControls" "GREEN"
	fi
}

printPasswordPolicyInfo()
{
printf "\n%s\n" "${HR2}" | log
printf "%s\n" "${H4B}PASSWORD POLICY INFORMATION:${H4E}" | log
printf "\n%s\n" "${passwordpolicyinfo}" | log
printf "%s\n" "${HR3}" | log
printf "%s\t%s\n" "Note:" "Password Policies other than \"Root Password Policy\" using Bcrypt, PBKDF2 or PKCS5S2 are flagged" | log

	passwordPolicies=`grep ',cn=Password Policies,cn=config' ${configfile} | grep ^dn: | sed "s/,cn=Password Policies,cn=config//; s/^dn: //; s/cn=//; s/ /~/g"`

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
		passwordStorageSchemes=`sed -n "/dn: cn=${passwordPolicyName},cn=Password Policies,cn=config/,/^ *$/p" ${configfile} | grep "ds-cfg-default-password-storage-scheme: " | sed "s/ds-cfg-default-password-storage-scheme: //; s/,cn=Password Storage Schemes,cn=config//; s/,cn=password storage schemes,cn=config//; s/,cn=password storage schemes,cn=config//; s/cn=//; s/ /~/g" | perl -p -e 's/\r\n|\n|\r/\n/g' | sed "s/ /~/g"`
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

	printf "${PREB}\n" | log
	# Print the policy table
	printf "\n%-${longestPassPolName}s: %-18s: %-${longestStorageSchemeName}s: %-26s: %-6s\n" "Password Policy" "Password Attr" "Default Storage Scheme" "Deprecated Storage Scheme" "Cost"| log
	printf "%-${longestPassPolName}s:%-18s:%-${longestStorageSchemeName}s:%-26s:%-6s\n" "${idash1}" "${idash2}-" "${idash3}-" "---------------------------" "------" | log

	for passwordPolicy in ${passwordPolicies}; do
		deprecatedPasswordStorageScheme=""
		passwordPolicyName=`echo ${passwordPolicy} | sed "s/~/ /g"`
		passwordStorageScheme=`sed -n "/dn: cn=${passwordPolicyName},cn=Password Policies,cn=config/,/^ *$/p" ${configfile} | grep "ds-cfg-default-password-storage-scheme: " | sed "s/ds-cfg-default-password-storage-scheme: //; s/,cn=Password Storage Schemes,cn=config//; s/,cn=password storage schemes,cn=config//; s/cn=//; s/ /~/g" | perl -p -e 's/\r\n|\n|\r/\n/g'`
		passwordStorageScheme=`echo ${passwordStorageScheme} | perl -p -e 's/\r\n|\n|\r/\n/g' | sed "s/~/ /g"`

		heavyScheme=`echo "${passwordStorageScheme}" | grep -iE 'BCRYPT|PBKDF2|PKCS5S2'`
		if [ $? = 0 ]; then
			heavySchemeAlertDisplay="*"

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
				alerts="${alerts} Policies:${REDBA}${red}Password~Policy~using~${heavySchemeName}~found~(${passwordPolicy}).${nocolor}${FEND}KBI400"
				addKB "KBI400"
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
		deprecatedPasswordStorageSchemes=`sed -n "/dn: cn=${passwordPolicyName},cn=Password Policies,cn=config/,/^ *$/p" ${configfile} | grep "ds-cfg-deprecated-password-storage-scheme: " | sed "s/ds-cfg-deprecated-password-storage-scheme: //; s/,cn=Password Storage Schemes,cn=config//; s/,cn=password storage schemes,cn=config//; s/cn=//; s/ /~/g" | perl -p -e 's/\r\n|\n|\r/\n/g' | sed "s/~/ /"`
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
		printf "\n\t%s" "${YELB}${yellow}Alert: Heavy impact Password Storage Scheme in use - ${heavySchemeNames}${nocolor}${FEND}" | log
		healthScore "PasswordPolicy" "YELLOW"
	fi
	if [ "${heavySchemeName}" != "" ]; then
		printf "\n\t%s\n" "${YELB}${yellow}Warning: DS 5.0 and higher uses PBKDF2 for the \"Root Password Policy\", beware of applications using Root DNs.${nocolor}${FEND}" | log
		alerts="${alerts} Policies:${YELBA}${yellow}DS~5.0~and~higher~uses~PBKDF2~for~the~\"Root~Password~Policy\",~beware~of~applications~using~Root~DNs.${nocolor}${FEND}"
	fi
	printf "%s\n\n" "" | log
	if [ "${PasswordPolicy}" != "RED" -o "${PasswordPolicy}" != "YELLOW" ]; then
		healthScore "PasswordPolicy" "GREEN"
	fi
	printf "${PREE}" | log
}

getCertInfo()
{
printf "\n%s\n" "${HR2}" | log
printf "%s\n" "${H4B}CERTIFICATE INFORMATION:${H4E}" | log
printf "\n%s\n" "${certificateinfo}" | log
printf "%s\n" "${HR3}" | log

	certNames=`grep ds-cfg-ssl-cert-nickname ${configfile} | sort -u | awk '{print $2}'`
	longestCertName=0
	for certName in ${certNames}; do
		thisLen=${#certName}
		if [ "${thisLen}" -gt "${longestCertName}" ]; then
			longestCertName=${thisLen}
		fi
	done

	printf "${PREB}" | log
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
	printf "${PREE}" | log
}

stackReports()
{
	topFiles=`ls | grep top | wc -l | awk '{print $1}'`
	hctFiles=`ls | grep "high-cpu-threads" | wc -l | awk '{print $1}'`
		if [ "${hctFiles}" -gt "0" ]; then
			rm high-cpu-threads*
		fi

	highCpuWaterMark=0
	highestCpuThread=0
	topTotal=0
c=1
while [ "${c}" -le "${topFiles}" ]; do
	ADDIN=''
	topTotal=0

	(cd ../config; printf "%-15s\t" "   - Sample ${c}:" | log )
	top="top-${c}.txt"
	topLines=`sed -n '/PID USER/,/^ *$/p' ${top} | sed "s/ /~/g" | grep -vE "PID|Total"`

	# Check to see if the PID USER columns has 11 or 12 coulums.
	# 	Alpine Linux uses 11
	#	All other Linuxes use 12
	# This has an effect on the outcome of topCPU=
	cpuClumnCheck=`grep 'PID USER' ${top} | wc | awk '{print $2}'`

	for topLine in ${topLines}; do
		topPid=`echo ${topLine} | sed "s/~/ /g" | awk '{print $1}'`
		if [ "${cpuClumnCheck}" = "12" ]; then
			topCPU=`echo ${topLine} | sed "s/~/ /g" | awk '{print $9}'`
		else
			topCPU=`echo ${topLine} | sed "s/~/ /g" | awk '{print $7}'`
		fi
		baseCPU=`echo ${topCPU} | cut -c1`

		if [ "${baseCPU}" -gt "0" ]; then
			echo "${topCPU}" >> cpuPercentages.tmp
		fi

		n=0
		hex=0
		hex=`echo "obase=16;ibase=10; ${topPid}" | bc`
		hex=`echo $hex | tr [:upper:] [:lower:]`
		nid="0x${hex}"

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
	# Check for BLOCKED threads
	grep --no-filename -B1 " BLOCKED " jstackdump*-${c}.txt | grep "nid=" | sed "s/.*tid=.* nid=//g" | awk '{print $1}' > blocked-threads-${c}.tmp
	blockedThreadCount=`wc -l blocked-threads-${c}.tmp | awk '{print $1}'`
	if [ "${blockedThreadCount}" -gt "0" ]; then
		blockedThreadCheck=`expr ${blockedThreadCount} + ${blockedThreadCheck}`
		threads="${blockedThreadCount} BLOCKED Thread(s)"
	fi
	if [ -s ./high-cpu-threads-${c}.out ]; then
		lowCPU=`cat ./cpuPercentages.tmp | sort -u --general-numeric-sort | head -1`
		highCPU=`cat ./cpuPercentages.tmp | sort -u --general-numeric-sort | tail -1`
		highCpuWaterMark=`echo ${highCPU} | sed "s/\..*$//"`
			if [ "${highCpuWaterMark}" -ge "5" ]; then
				if [ "${highCpuWaterMark}" -gt "${highestCpuThread}" ]; then
					highestCpuThread=${highCpuWaterMark}
				fi
				ADDIN=" *"
			fi
		(cd ../config; printf "%s \t%-24s\t%-17s\n" "CPU Range: ${lowCPU}% to ${highCPU}%" "Total Process CPU: ${topTotal}%" "${threads}" | log )

		rm ./cpuPercentages.tmp
		highCpuThreadsFound=1
	else
		(cd ../config; printf "%-19s\t\t%-24s\t%-17s\n" "......................." "Total Process CPU: 0%" "${threads}" | log )
	fi
	c=`expr ${c} + 1`
	threads=''
done
c=1
while [ "${c}" -le "${topFiles}" ]; do
	if [ -s blocked-threads-${c}.tmp ]; then
	nids=`cat blocked-threads-${c}.tmp`
	for nid in ${nids}; do
		sed -n "/nid=${nid}/,/^ *$/p" jstackdump*-${c}.txt > blocked-threads-${c}.out
	done
		# Set the following as a check to display "Creating blocked-threads reports" or not
		blockedThreadCount=1
	fi
	rm blocked-threads-${c}.tmp
	c=`expr ${c} + 1`
done
	(cd ../config; printf "\n%s\n" " * Total Process CPU = total cpu used by all threads in that stack sample" | log )
	if [ "${blockedThreadCount}" -gt "0" ]; then
		(cd ../config; printf "%s\t%s\n" " * Creating blocked-threads reports (in ../processStats)" | log )
	fi
	if [ "${highestCpuThread}" -gt "5" ]; then
		compilerThreadCheck=`grep -B1 "C. CompilerThread" high-cpu-threads-* | grep "CPU" | awk '{print $3}' | sort -r | head -1`
		if [ "${compilerThreadCheck}" != "" ]; then
			alerts="${alerts} JVM:${YELBA}${yellow}Compiler~Thread's~with~high~CPU~found~(${compilerThreadCheck}~%)${nocolor}${FEND}.KBI611"
			(cd ../config; printf "\n   %-68s\t%s\n" "${YELB}${yellow}Alert: Compiler Thread's with high CPU found (${compilerThreadCheck} %).${nocolor}${FEND}" "" | log )
			(cd ../config; printf "    - %-68s\t%s\n" "${YELB}${yellow}Test using -XX:ReservedCodeCacheSize= and -XX:+UseCodeCacheFlushing in your JVM arguments.${nocolor}${FEND}" "" | log )
			addKB "KBI611"
			healthScore "JVMTuning" "YELLOW"
		fi
		searchNotIndexedThreadCheck=`grep -B27 "searchNotIndexed" high-cpu-threads-* | grep "CPU" | awk '{print $3}' | sort -r | head -1`
		if [ "${searchNotIndexedThreadCheck}" != "" ]; then
			alerts="${alerts} Process:${YELBA}${yellow}Unindexed~Search~Thread's~with~high~CPU~found~(${searchNotIndexedThreadCheck}~%)${nocolor}${FEND}.KBI701"
			(cd ../config; printf "\n   %-68s\t%s\n" "${YELB}${yellow}Alert: Unindexed Search Thread's with high CPU found (${searchNotIndexedThreadCheck} %).${nocolor}${FEND}" "" | log )
			addKB "KBI701"
			healthScore "CPUUsage" "YELLOW"
		fi
	fi
		# Check for org.opends.server.protocols.BlockingBackpressureOperator$BackpressureSemaphore.blockUntilAllowedToEmit
		# Pattern = org.opends.server.protocols.BlockingBackpressureOperator.BackpressureSemaphore.blockUntilAllowedToEmit
		backPressureThreadCheck=`grep -c "blockUntilAllowedToEmit" jstackdump*-* | grep -v ':0' | wc -l | awk '{print $1}'`
		if [ "${backPressureThreadCheck}" != "0" ]; then
			alerts="${alerts} Process:${REDBA}${red}${backPressureThreadCheck}~Worker~threads~waiting~in~backpressure.${nocolor}${FEND}"
			(cd ../config; printf "\n   %-68s\t%s\n" "${REDB}${red}Alert: ${backPressureThreadCheck} Worker threads waiting in backpressure.${nocolor}${FEND}" "" | log )
			healthScore "Threads" "RED"
		fi
		# Pattern = sun.security.util.MemoryCache.emptyQueue
		jdkSslBlockingThreadCheck=`grep -c "waiting to lock <.*> (a sun.security.util.MemoryCache)" jstackdump*-* | grep -v ':0' | wc -l | awk '{print $1}'`
		if [ "${jdkSslBlockingThreadCheck}" != "0" ]; then
			alerts="${alerts} Process:${REDBA}${red}${jdkSslBlockingThreadCheck}~Worker~threads~blocked~in~JDK~SSL.${nocolor}${FEND}"
			(cd ../config; printf "\n   %-68s\t%s\n" "${REDB}${red}Alert: ${jdkSslBlockingThreadCheck} Worker threads blocked in JDK SSL.${nocolor}${FEND}" "" | log )
			healthScore "Threads" "RED"
		fi
		# Pattern = BLOCKED
		if [ "${blockedThreadCheck}" != "0" ]; then
			alerts="${alerts} Process:${REDBA}${red}${blockedThreadCheck}~Worker~threads~blocked.${nocolor}${FEND}"
			(cd ../config; printf "\n   %-68s\t%s\n" "${REDB}${red}Alert: ${blockedThreadCheck} threads in a BLOCKED state.${nocolor}${FEND}" "" | log )
			(cd ../config; printf "   \t%-68s\t%s\n" "Note: blocked threads do not always indicate a problem. Investigation required." "" | log )
			healthScore "Threads" "RED"
		fi
	if [ "${highestCpuThread}" -gt "25" ]; then
		alerts="${alerts} Process:${REDBA}${red}High~CPU~Threads~found~(${highestCpuThread}~%).${nocolor}${FEND}"
		(cd ../config; printf "\n   ${REDB}%s${FEND}\n" "${REDB}${red}Alert: High CPU Threads found (${highestCpuThread} %)${nocolor}${FEND}" | log )
		addKB "KBI700"
		healthScore "CPUUsage" "RED"
	fi
	otherInfoDisplayed=1
	return $highCpuThreadsFound
}

renameJstacks()
{
	printf "%s" "   - Renaming stack files               "
	cd ../processStats
	newFileNumber=1
	c=0
	while [ "${c}" -le "9" ]; do
		thisFile=`ls jstackdump*-0${c} | sed "s/-0${c}$//"`
		mv ${thisFile}-0${c} ${thisFile}-${newFileNumber}.txt 
		newFileNumber=`expr ${newFileNumber} + 1`
		c=`expr ${c} + 1`
	done
	cd ../config
	sleep 2
	printf "                                                                  \r\b"
}

splitJstacks()
{

filedate=`date "+%Y%m%d-%H%M%S"`

# Remove any non-jstack/date-time logged data that may be in the server.out file.
# Dec 9, 2019 14:03:19 -0600 [5640 1] com.newrelic INFO: New Relic Agent: Loading configuration file "/opt/newrelic/java/./newrelic.yml"
# Jan 22, 2020 05:08:08 +0000 [13180 1] com.newrelic INFO: New Relic Agent: Loading configuration file "/opt/newrelic/./newrelic.yml"
if [ "${osType}" = "Darwin" ]; then
#LEET TEST THIS ON LINUX
	sed -i '' "/... .*, .... ..:..:../d" ${serverOutFile}

	#sed -n '/....-..-.. ..:..:../,$p' ${serverOutFile} > ${serverOutFile}.tmp
	#mv ${serverOutFile}.tmp ${serverOutFile}
	#grep '..-..-.. ..:..:..' ${serverOutFile} | head -1 > ${serverOutFile}.tmp
	#sed '1,/....-..-.. ..:..:../d' ${serverOutFile} >> ${serverOutFile}.tmp
	#awk 'f;/2020-06-13 15:49:32/{f=1}' ${serverOutFile} >> ${serverOutFile}.tmp
else
	sed -i "/... .*, .... ..:..:../d" ${serverOutFile}
fi

# The following splitCount & csplit was changed to {$splitCount} from {8} to account for when there are more than 10 stacks in the server.out
splitCount=`grep "^....-..-.. " ../logs/${serverOutFile} | wc -l | awk '{print $1}'`
splitCount=`expr ${splitCount} - 2`
(cd ../logs; csplit -s -f "jstackdump$filedate-" ${serverOutFile} "/....-..-.. ..:..:../" {$splitCount} )
if [ $? = 0 ]; then
	printf "\tJstack files created\n" | log
	(cd ../logs; mv ./jstackdump* ../processStats )
	sleep 2
	printf "                                                                  \r\b"
	renameJstacks
	# clean out any additional stacks
	if [ -s ../processStats/jstackdump$filedate-11 ]; then
		(cd ../processStats; rm jstackdump$filedate-1? )
	fi
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
			printf "%-24s\t%-13s\n" " ${YELB}${yellow}* Alert: Production Mode" "enabled${nocolor}${FEND}" | log
			alerts="${alerts} Encryption:${YELBA}${yellow}Production~Mode~enabled${nocolor}${FEND}"
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

		jstackTestFile=""

		printf "${PREB}\n" | log
		printf "%s\t\t\t%s\n" " * Stacks files" "Missing or zero bytes" | log
			rm ../processStats/jstackdump*
		if [ -s ../logs/server.out ]; then
			serverOutFile='../logs/server.out'
		fi
		if [ -s ../logs/server.out.stacks ]; then
			serverOutFile='../logs/server.out.stacks'
		fi
		if [ "${serverOutFile}" = "" ]; then
			printf "%-25s\t%s\n" "   - server.out not found" "NA with an ${embeddedFound}" | log
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
		printf "\n%s\t%s\n" " * Stack files not found." "Not creating high-cpu-thread reports" | log
		zeroByteStackTopFile=1
		return
	else
		printf "\n%s\t%s\n" " * Stack+top files not found." "Not creating high-cpu-thread reports" | log
		zeroByteStackTopFile=1
		return
	fi
	if [ -s ../processStats/${topTestFile} -a "${topTestFile}" != "" ]; then
		printf "%s\t\t%s\n" " * Top files found" "Showing CPU usage range" | log
	fi

	if [ "${topTestFile}" != "" -a "${jstackTestFile}" != "" ]; then
	printf "\n" "" | log
		cd ../processStats
		stackReports
		cd ../config
	else
		printf "%s\t\t%s\n" " * Top files not found." "Not showing CPU usage or creating high-cpu-thread reports" | log
	fi
}

diffTheStacks()
{
	if [ "${zeroByteStackTopFile}" = "1" ]; then
		printf "%s\t%s\n" " * Stack+top files not found." "Not creating high-cpu-thread reports" | log
		return
	fi

	cd ../processStats
	jstacks=`ls jstackdump* | grep -v report | sed "s/-/ /" | awk '{print $1}' | sort -u`

	echo
	i=1
	lastSample=1
	differenceFound=0
c=0
while [ "${c}" -le "9" ]; do
	currentSample=$jstack

	if [ "$lastSample" != "1" ];then
		c2=`expr $c + 1`

		# jstackdump20190510-151949-1.txt
		lastSample=`ls ${jstacks}-*-${c}.txt`
		currentSample=`ls ${jstacks}-*-${c2}.txt`

		wc=`wc -l ${lastSample} | awk '{print $1}'`; wc=`expr ${wc} - 1`
		if [ "${osType}" = "Darwin" ]; then
			tail -${wc} ${lastSample} > ${lastSample}.tmp
		else
			tail -n ${wc} ${lastSample} > ${lastSample}.tmp
		fi
		wc=`wc -l ${currentSample} | awk '{print $1}'`; wc=`expr ${wc} - 1`
		tail -${wc} ${currentSample} > ${currentSample}.tmp

		lastSampleIndex=`echo ${lastSample} | sed "s/\.txt//; s/-/ /g" | awk '{print $2 "-" $3}'`
		currentSampleIndex=`echo ${currentSample} | sed "s/\.txt//; s/-/ /g" | awk '{print $2 "-" $3}'`

		(cd ../config; printf "%-20s vs %-16s\t%s" "   - Sample ${lastSampleIndex}" "Sample ${currentSampleIndex}" | log )

		pTaken=1
		if [ -s  ${lastSample}.tmp -a -s ${currentSample}.tmp ]; then
		fileDiffs=`diff ${lastSample}.tmp ${currentSample}.tmp > jstackdiff.${lastSampleIndex}-${currentSampleIndex}`
		if [ $? = 1 ]; then
			(cd ../config; echo "process changing" | log )
			differenceFound=1
		else
			(cd ../config; echo "no change" | log )
			rm jstackdiff.${lastSampleIndex}-${currentSampleIndex}
		fi
		else
			(cd ../config; printf "%-20s\n" "0-byte files" | log )
		fi
	fi
	if [ "$pTaken" = "1" -o "$i" = "1" ];then
		lastSample="${jstacks}-*-${c}.txt"
	fi
	i=`expr $i + 1`
	c=`expr ${c} + 1`
done
	rm *.tmp
	cd ../config
}

printStackCpuInfo()
{
printf "\n%s\n" "${HR2}" | log
printf "%s\n" "${H4B}CPU USAGE AND THREAD INFORMATION:${H4E}" | log
printf "\n%s\n" "${cpuusageinfo}" | log
printf "%s\n" "${HR3}" | log
printf "${PREB}" | log
	checkJstacks "2"
	if [ "${CPUUsage}" != "RED" -o "${CPUUsage}" != "YELLOW" ]; then
		healthScore "CPUUsage" "GREEN"
	fi
	printf "${PREE}" | log
}

printStackDifference()
{
printf "\n%s\n" "${HR2}" | log
printf "%s\n" "${H4B}PROCESS DIFFERENCE INFORMATION:${H4E}" | log
printf "\n%s\n" "${processinfo}" | log
printf "%s\n" "${HR3}" | log
printf "${PREB}\n" | log
	if [ "${zeroByteStackTopFile}" = "1" -o "${jstackTestFile}" = "" ]; then
		printf "%s\t%s\n\n" " * Stack files not found." "Not generating stack diffs" | log
		printf "${PREE}" | log
		return 1
	fi

	printf "%s\t%s\n" " * Diffing ../processStats/jstackdump* files" "Creating jstackdiff.* reports (in ../processStats)" | log
	diffTheStacks
	if [ "${differenceFound}" = "1" ]; then
		printf "\n%s\n" " * Process is changing (not hung) " | log
	else
		printf "\n%s\n" " * Process could be idle or hung" | log
	fi
printf "${PREE}" | log
}

printOtherInfo()
{

printf "\n%s\n" "${HR2}" | log
printf "%s\n" "${H4B}OTHER INFORMATION:${H4E}" | log
printf "\n%s\n" "${otherinfo}" | log
printf "%s\n" "${HR3}" | log
printf "${PREB}\n" | log

	checkProdMode "1"

	if [ "${ctsIndexesFound}" = "1" ]; then
		printf "%-15s\t\t%-19s\n" " * AM CTS Instance" "am-cts indexes found." | log
		otherInfoDisplayed=1
	fi
	if [ "${amCfgIndexCount}" -ge "1" ]; then
		printf "%-21s\t\t%-28s\n" " * AM Config Instance" "am-cfg indexes found." | log
		otherInfoDisplayed=1
	fi
	if [ "${identityStoreIndexCount}" -ge "1" ]; then
		printf "%-21s\t\t%-28s\n" " * AM Identity Store" "am-identity-store indexes found." | log
		otherInfoDisplayed=1
	fi
	if [ "${idmRepoIndexCount}" -ge "1" ]; then
		printf "%-21s\t\t%-28s\n" " * IDM Repo" "idm-repo indexes found." | log
		otherInfoDisplayed=1
	fi

	if [ "${ttlEnabledIndexes}" != "NA" ]; then
		for ttlEnabledIndex in ${ttlEnabledIndexes}; do
			printf " * %-19s\t\t%-22s\n" "Time To Live enabled" "TTL index(es) found." | log
		done
		otherInfoDisplayed=1
	fi

	# display profiles
	if [ "${dsprofiles}" != "" ]; then
		for dsprofile in ${dsprofiles}; do
			dsprofile=`echo ${dsprofile} | sed "s/:/ /"`
			printf " * %-20s\t\t%s\n" "DS Profiles found" "$dsprofile" | log
		done
	else
		printf " * %-20s\t\t%s\n" "DS Profiles" "DS was not installed using profiles" | log
	fi

	globalAciCount=`grep -c ds-cfg-global-aci: config.ldif | awk '{print $1}'`
	if [ "${globalAciCount}" != "" ]; then
		printf " * %-20s\t\t%s\n" "Global ACI Count" "$globalAciCount total." | log
		otherInfoDisplayed=1
	fi

	if [ "${dataversion}" != "" ]; then
		dataver=`echo ${dataversion} | cut -c1-5`
		datacommit=`echo ${dataversion} | sed "s/${dataver}.//"`
		printf " * %-17s\t\t%-5s %-42s\n" "Data version" "${dataver}" "${datacommit}" | log
	fi

	if [ "${serverType}" != "Stand Alone/Not replicated" -a "${serverType}" != "Directory Server (DS only)" -a ${ctsIndexCount} -ge "1" -a  "${computechangenumber}" != "disabled" -a "${computechangenumber}" != "false" ]; then
		printf " * %-21s\n" "This CTS is replicated. The ${changenumberindexerattr} may be disabled to increase performance." | log
		printf "\t- %-21s\n" "Verify cn=changelog is not being used, before disabling." | log
		otherInfoDisplayed=1
	fi

	if [ "${otherInfoDisplayed}" = "" ]; then
		printf "%s\n" " * None"
	fi

	if [ "${OtherInfo}" != "RED" -o "${OtherInfo}" != "YELLOW" ]; then
		healthScore "OtherInfo" "GREEN"
	fi
printf "${PREE}" | log
}

printAlerts()
{

	alerts=`echo ${alerts} | sort -u`
alertnumber=0
printf "\n%s\n" "${HR2}" | log
printf "%s\n" "${H4B}ALERTS ENCOUNTERED:${H4E}" | log
printf "%s\n" "${HR3}" | log
printf "${OLB}\n" | log
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
			kb=`grep "${kbi}=" $0 | sed "s/${kbi}=//; s/\"//g" | awk '{print $1}'`
			debug "kb=${kb}"

			kbiTest=`echo ${kb} | grep 'OPENDJ-'`
			if [ $? = 0 ]; then
				alertmsg=`echo ${alertmsg} | sed "s/${kbi}/ See Jira ${kb}/"`
			else
				alertmsg=`echo ${alertmsg} | sed "s/${kbi}/ See KB Article: ${kb}/"`
			fi
		fi
	if [ "${usehtml}" != "1" ]; then
		printf " [%s]\t%-12s %s\n" "${alertnumber}" "${alertcategory}:" "${alertmsg}" | log
	else
		printf " ${LIB}\t%-12s %s${LIE}\n" "${alertcategory}:" "${alertmsg}" | log
	fi
	done

	if [ "${alertnumber}" = "0" ]; then
		if [ "${usehtml}" != "1" ]; then
			printf " [%s]\t%-12s %s\n" "0" "No alerts encountered" | log
		else
			printf " ${ULB}${LIB}\t%-12s %s${LIE}${ULE}\n" "No alerts encountered" | log
		fi
	else
		printf "\n%s\n" "${PB}See all reported values with an asterisk (*)${PEND}" | log
	fi
printf "${OLE}\n" | log

	fatalalerts=`echo ${fatalalerts} | sort -u`
fatalalertnumber=0
printf "\n%s\n" "${HR2}" | log
printf "%s\n" "${H4B}FATAL ERRORS:${H4E}" | log
printf "%s\n" "${HR3}" | log
printf "${OLB}\n" | log
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
			kb=`grep "${kbi}=" $0 | sed "s/${kbi}=//; s/\"//g" | awk '{print $1}'`
			debug "kb=${kb}"

			kbiTest=`echo ${kb} | grep 'OPENDJ-'`
			if [ $? = 0 ]; then
				fatalalertmsg=`echo ${fatalalertmsg} | sed "s/${kbi}/ See Jira ${kb}/"`
			else
				fatalalertmsg=`echo ${fatalalertmsg} | sed "s/${kbi}/ See KB Article: ${kb}/"`
			fi
		fi
	if [ "${usehtml}" != "1" ]; then
		printf " [%s]\t%-12s %s\n" "${fatalalertnumber}" "${fatalalertcategory}:" "${fatalalertmsg}" | log
	else
		printf " ${LIB}\t%-12s %s${LIE}\n" "${fatalalertcategory}:" "${fatalalertmsg}" | log
	fi
	done

	if [ "${fatalalertnumber}" = "0" ]; then
		if [ "${usehtml}" != "1" ]; then
			printf " [%s]\t%-12s %s\n" "0" "No fatal errors encountered" | log
		else
			printf " ${ULB}${LIB}\t%-12s %s${LIE}${ULE}\n" "No fatal errors encountered" | log
		fi
	else
		printf "\n%s\n" "${PB}See all reported values with an asterisk (*)${PEND}" | log
	fi
printf "${OLE}\n" | log

kbasalertnumber=0
printf "\n%s\n" "${HR2}" | log
printf "%s\n" "${H4B}KNOWLEDGE ARTICLES:${H4E}" | log
printf "%s\n" "${HR3}" | log
printf "${OLB}\n" | log

	debug "sorted kbas->[$kbas]"

	# get the lengths for each KB message for proper formatting
	msgLen=0
	for kba in ${kbas}; do
		kbi=`grep "^${kba}=" $0 | sed "s/${kba}=//; s/\"//g" | awk '{print $1}'`
		kbimessage=`grep "${kba}=" $0 | sed "s/\"//g; s/${kba}=${kbi} //"`
		calcLen "$kbimessage"
			if [ "${mylen}" -gt "${msgLen}" ]; then
				msgLen=$mylen
			fi
	done

	for kba in ${kbas}; do
		debug "KBA->$kba"
		kbasalertnumber=`expr ${kbasalertnumber} + 1`
		kbi=`grep "^${kba}=" $0 | sed "s/${kba}=//; s/\"//g" | awk '{print $1}'`
		debug "KBURL->$kburl"
		debug "KBI->$kbi"
		debug "KBI=KBA->${kba}=${kbi}"
		kbimessage=`grep "${kba}=" $0 | sed "s/\"//g; s/${kba}=${kbi} //"`
		debug "KBIMESSAGE->$kbimessage"

		basicversion=`echo ${compactversion} | cut -c1-2`

		msgUrl=`grep "^${kba}URL${basicversion}=" $0 | sed "s/${kba}URL${basicversion}=//; s/\"//g"`
		debug "msgUrl->$msgUrl"
		if [ "${msgUrl}" = "" ]; then
			kbUrlCheck=`echo "${kbi}" | grep "OPENDJ"`
			if [ $? = 0 ]; then
				msgUrl=${jurl}${kbi}
			else
				msgUrl=${kburl}${kbi}
			fi
		fi
	if [ "${usehtml}" != "1" ]; then
		printf " [%s]\t%-${msgLen}s\t%s\n" "${kbasalertnumber}" "${kbimessage}" "(${msgUrl})" | log
	else
		printf " ${LIB}\t%-${msgLen}s\t%s${LIE}\n" "<A TARGET=\"_blank\" HREF=\"${msgUrl}\">${kbimessage}</A>" | log
	fi
	done
printf "${OLE}\n" | log

	if [ "${kbasalertnumber}" = "0" ]; then
		printf " [%s]\t%-12s %s\n" "0" "No KB messages to display" | log
	fi
}

printHealthStatus()
{

printf "\n%s\n" "${HR2}" | log
printf "%s\n" "${H4B}HEALTH STATUS:${H4E}" | log
printf "\n%s\n" "${healthstatusinfo}" | log
printf "%s\n" "${HR3}" | log
printf "${PREB}\n" | log

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
			thisColor="${REDB}${red}"
		elif [ "${sectionScore}" = "YELLOW" ]; then
			thisColor="${YELB}${yellow}"
		else
			thisColor="${GRNB}${green}"
		fi

		printf " [%s]\t%-20s\t\t%s\n" "${hsalertnumber}" "${sectionName}" "(${thisColor}${sectionScore}${nocolor}${FEND})" | log
	done
printf "%s\n" "" | log
printf "%s\n" "Key (Health status)" | log
printf "%s\n" "" | log
printf "%-6s\t\t%s\n" " ${GRNB}${green}GREEN${nocolor}${FEND}" "No issues" | log
printf "%-6s\t\t%s\n" " ${YELB}${yellow}YELLOW${nocolor}${FEND}" "Minor issues, attention recommended" | log
printf "%-6s\t\t%s\n" " ${REDB}${red}RED${nocolor}${FEND}" "Major issues, attention required" | log
printf "${PREE}" | log
}

footer()
{
	printf "\n%s\n" "${HR2}" | log
if [ "${colorDisplay}" = "" ]; then
	printf "%s\n" "Report saved in \"${filename}\""
else
	printf "\n%s\n" "No Report saved. Color was set to ON (-e)"
fi
if [ "${highCpuThreadsFound}" = "1" -a "${colorDisplay}" != "1" ]; then
	(cd ..; zip -rpq ${zipfilename} config/${filename} processStats/high-cpu-threads-*.out )
	printf "%s\n\n" "Report + high-cpu-threads reports saved in \"${zipfilename}\""
fi
if [ "${usehtml}" != "1" ]; then
	printf "\n%-33s\n" "${copyright}" | log
else
	printf "\n%s\n" "<footer>" | log
		printf "%-62s\n" "${HR1}" | log
		printf "%-62s\n" "<TABLE BORDER=0 WIDTH=\"1000\" CELLPADDING=\"0\">" | log
		printf "%-62s\n" "<TR>" | log
		printf "%-62s\n" "<TD COLSPAN=\"100\" ALIGN=\"LEFT\"><H4>ForgeRock Extractor ${version}</H4></TD>" | log
		printf "%-62s\n" "<TD COLSPAN=\"100\" ALIGN=\"RIGHT\"><H4>${copyright}</H4></TD>" | log
		printf "%-62s\n" "</TR>" | log
		printf "%-62s\n" "</TABLE>" | log
	printf "\n%s\n" "</footer>" | log
	printf "%s\n%s" "</BODY>" "</HTML>" | log
fi
}

getReportFileName
checkHtmlFormat
header
printServerInfo
printBackends
printIndexes
printReplicaInfo
printAciInfo
printPasswordPolicyInfo
getCertInfo
getLoggerInfo
getJVMInfo
printStackCpuInfo
printStackDifference
printOtherInfo
printAlerts
printHealthStatus
footer

#EOF

