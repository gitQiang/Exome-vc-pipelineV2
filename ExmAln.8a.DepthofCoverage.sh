#!/bin/bash
#$ -cwd -l mem=8G,time=4:: -N DepOfCov


#This script takes a bam file and generates depth of coverage statistics using GATK
#	InpFil - (required) - Path to Bam file to be aligned or a file containing a list of bam files one per line (file names must end ".list")
#			if it is a list then call the job as an array job with -t 1:n where n is the number of bams
#	RefFiles - (required) - shell file to export variables with locations of reference files, jar files, and resource directories; see list below
#	TgtBed - (required) - Exome capture kit targets bed file (must end .bed for GATK compatability)
#	LogFil - (optional) - File for logging progress
#	Flag - A - AllowMisencoded - see GATK manual, causes GATK to ignore abnormally high quality scores that would otherwise indicate that the quality score encoding was incorrect
#	Flag - B - BadET - prevent GATK from phoning home
#	Help - H - (flag) - get usage information

#list of required vairables in reference file:
# $TARGET - exome capture intervals bed file or other target file (must end ".bed")
# $EXOMPPLN - directory containing exome analysis pipeline scripts
# $GATK - GATK jar file 
# $ETKEY - GATK key file for switching off the phone home feature, only needed if using the B flag

#list of required tools:
# java <http://www.oracle.com/technetwork/java/javase/overview/index.html>
# GATK <https://www.broadinstitute.org/gatk/> <https://www.broadinstitute.org/gatk/download>

## This file also require exome.lib.sh - which contains various functions used throughout my Exome analysis scripts; this file should be in the same directory as this script

###############################################################

#set default arguments
usage="
ExmAln.8a.DepthofCoverage.sh -i <InputFile> -r <reference_file> -t <targetfile> -l <logfile> -GIQH

	 -i (required) - Path to Bam file or \".list\" file containing a multiple paths
	 -r (required) - shell file to export variables with locations of reference files and resource directories
	 -t (required) - Exome capture kit targets bed file (must end .bed for GATK compatability)
	 -l (optional) - Log file
	 -A (flag) - AllowMisencoded - see GATK manual
	 -B (flag) - Prevent GATK from phoning home
	 -H (flag) - echo this message and exit
"

AllowMisencoded="false"
BadEt="false"

#get arguments
while getopts i:r:t:l:ABH opt; do
	case "$opt" in
		i) InpFil="$OPTARG";;
		r) RefFil="$OPTARG";; 
		t) TgtBed="$OPTARG";; 
		l) LogFil="$OPTARG";;
		A) AllowMisencoded="true";;
		B) BadET="true";;
		H) echo "$usage"; exit;;
	esac
done

#load settings file
source $RefFil

#Load script library
source $EXOMPPLN/exome.lib.sh #library functions begin "func"

#Set Local Variables
funcFilfromList
BamFil=`readlink -f $InpFil` #resolve absolute path to bam
if [[ -z $LogFil ]];then LogFil=$BamFil.DoC.log; fi # a name for the log file
OutFil=$BamFil.DoC #prefix used in names of output files
GatkLog=$BamNam.DoC.gatklog #a log for GATK to output to, this is then trimmed and added to the script log
TmpLog=$BamNam.DoC.temp.log #temporary log file 
TmpDir=$BamNam.DoC.tempdir; mkdir -p $TmpDir #temporary directory

#Start Log
ProcessName="Depth of Coverage with GATK" # Description of the script - used in log
funcWriteStartLog

#Calculate depth of coverage statistics
StepName="Calculate depth of coverage statistics using GATK DepthOfCoverage" # Description of this step - used in log
StepCmd="java -Xmx5G -Djava.io.tmpdir=$TmpDir -jar $GATKJAR -T DepthOfCoverage -R $REF -I $BamFil -L $TgtBed -o $OutFil -ct 1  -ct 5 -ct 10 -ct 15 -ct 20 -omitIntervals -log $GatkLog" #command to be run
funcGatkAddArguments
funcRunStep

#End Log
funcWriteEndLog