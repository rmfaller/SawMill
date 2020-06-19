# SawMill

> The code is provided on an "as is" basis, without warranty of any kind, to the fullest extent permitted by law. 
> 
> ForgeRock does not warrant or guarantee the individual success developers may have in implementing the code on their platforms or in production configurations.
> 
> ForgeRock does not warrant, guarantee or make any representations regarding the use, results of use, accuracy, timeliness or completeness of any data or information relating to the alpha release of unsupported code. ForgeRock disclaims all warranties, expressed or implied, and in particular, disclaims all warranties of merchantability, and warranties related to the code, or any service or software related thereto.
> 
> ForgeRock shall not be liable for any direct, indirect or consequential damages or costs of any type arising out of any action taken by you or others related to the code.

Based on the .json file in the configuration directory SawMill can either:

condense a single log file from OpenAM, AM, OpenDJ, DS, OpenIDM, IDM, OpenIG, and IG based on the cut value 

or

combine (laminate) multiple condensed files into a single file based on timestamp.

```
SawMill usage when analyzing a log:
	required for ripping/analyzing:
		--rip         | -r path and filename of log file to analyze
		--poi         | -p path and filename of json configuration file on how to handle the log file to analyze
	Example:
	java -jar ./dist/SawMill.jar --rip /path/to/file_to_analyze --poi /path/to/log_file_configuration.json
	options for ripping:
		--totals      | -t prints a total for each column. Do not use this option when condensing a file to be laminated
		--cut x       | -u where is x an integer and specifies the number of milliseconds used to condense the file by
		--sla         | -s Lists the percentage of times the operation completed within the configured threshold
		                SLAs are assigned within the log_file_configuration.json file
		--filltimegap | -f do not compress time
SawMill usage when laminating together more than one ripped log file:
	required for laminating:
		--laminate    | -l path(s) and filename(s) of log files to laminate
	Example:
	java -jar ./dist/SawMill.jar --laminate /path/to/rippedfile-0 /path/to/rippedfile-1 /path/to/rippedfile-n

	Example of analyzing two log files and then laminating those files together:
		java -jar ./dist/SawMill.jar --rip $HOME/openidm/audit/access.audit.json-1of2 --poi $HOME/SawMill/poi/idm5-log.json > /tmp/idm-1of2.csv
		java -jar ./dist/SawMill.jar --rip $HOME/openidm/audit/access.audit.json-2of2 --poi $HOME/SawMill/poi/idm5-log.json > /tmp/idm-2of2.csv
		java -jar ./dist/SawMill.jar --laminate /tmp/idm-1of2.csv /tmp/idm-2of2.csv > /tmp/idm-combined.csv
```
