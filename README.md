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

- or -

combine (laminate) multiple condensed files into a single file based on timestamp.

SawMill usage:
java -jar SawMill.jar --condense file_to_condense --configuration configuration/log_file_configuration.json
	options when condensing:
		--totals : prints a total for each column. Do not use this option when condensing a file to be laminated.
		--cut x  : where is x an integer and specifies the number of milliseconds used to condense the file by.
		--sla    : includes the number of operations the meet SLAs, exceeded SLAs, and a percentage of operations that met SLAs.
		           SLAs are assigned within the log_file_configuration.

or

java -jar SawMill.jar --laminate condensedfile0 condensedfile1 condensedfilen...
```
