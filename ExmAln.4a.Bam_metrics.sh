#!/bin/bash
#$ -cwd -l mem=8G,time=4:: -N BamMtr 

#This script takes a bam file and generates a insert size, GC content and quality score metrics using Picard
#	InpFil - (required) - Path to Bam file to be aligned or a file containing a list of bam files one per line (file names must end ".list")
#	RefFiles - (required) - shell file to export variables with locations of reference files, jar files, and resource directories; see list below
#	LogFil - (optional) - File for logging progress
#	Flags - G, I, Q - will run GC bias, Insert Size and Quality Distribution; default is to run all metrics, specidfying one or more will only run those specified
#list of required vairables in reference file:
# $REF - reference genome in fasta format - must have been indexed using 'bwa index ref.fa'
# $PICARD - directory containing Picard jar files

#list of required tools:
# java
# Picard

## This file also require exome.lib.sh - which contains various functions used throughout my Exome analysis scripts; this file should be in the same directory as this script

###############################################################

#get arguments
while getopts i:r:l:GIQ opt; do
	case "$opt" in
		i) InpFil="$OPTARG";;
		r) RefFil="$OPTARG";;
		l) LogFil="$OPTARG";;
		G) GCmet="true";;
		I) ISmet="true";;
		Q) QDmet="true";;
	esac
done

#load RefFil file
source $RefFil

#Load script library
source $EXOMPPLN/exome.lib.sh #library functions begin "func"

#Set local Variables
if [[ -z $GCmet ]] && [[ -z $ISmet ]] && [[ -z $QDmet ]]; then #if no flags run all metrics
	ALLmet="true"
fi
echo $ALLmet
funcFilfromList
BamFil=`readlink -f $InpFil` #resolve absolute path to bam
BamNam=`basename ${BamFil/.bam/}` #a name to use for the various output files
BamNam=${BamNam/.list/} 
if [[ -z $LogFil ]];then
	LogFil=$BamNam.BamMetrics.log # a name for the log file
fi
TmpLog=$BamNam.BamMettemp #temporary log file 
TmpDir=$BamNam.BamMettempdir #temp directory for java machine
mkdir -p $TmpDir

#Start Log
ProcessName="Start Get GC metrics with Picard" # Description of the script - used in log
funcWriteStartLog

#Get GC metrics with Picard
if [[ $ALLmet == "true" ]] || [[ $GCmet == "true" ]]; then
	StepName="Get GC Metrics with Picard" # Description of this step - used in log
	StepCmd="java -Xmx4G -Djava.io.tmpdir=$TmpDir -jar $PICARD/CollectGcBiasMetrics.jar INPUT=$BamFil  OUTPUT=$BamNam.GCbias_detail CHART=$BamNam.GCbias.pdf REFERENCE_SEQUENCE=$REF VALIDATION_STRINGENCY=SILENT WINDOW_SIZE=200" #command to be run
	funcRunStep
fi
#Get Insert size metrics with Picard
if [[ $ALLmet == "true" ]] || [[ $ISmet == "true" ]]; then
	StepName="Get Insert Size Metrics with Picard" # Description of this step - used in log
	StepCmd="java -Xmx4G -Djava.io.tmpdir=$TmpDir -jar $PICARD/CollectInsertSizeMetrics.jar INPUT=$BamFil  OUTPUT=$BamNam.InsertSize_detail HISTOGRAM_FILE=$BamNam.InsertSize.pdf VALIDATION_STRINGENCY=SILENT" #command to be run
	funcRunStep
fi

#Quality Score Distribution
if [[ $ALLmet == "true" ]] || [[ $QDmet == "true" ]]; then
	StepName="Get Quality Score Distribution from BAM file using PICARD" # Description of this step - used in log
	StepCmd="java -Xmx4G -Djava.io.tmpdir=$TmpDir -jar $PICARD/QualityScoreDistribution.jar INPUT=$BamFil OUTPUT=$BamNam.QualityDistr CHART_OUTPUT=$BamNam.QualityScoreDistr.pdf REFERENCE_SEQUENCE=$REF VALIDATION_STRINGENCY=SILENT" #command to be run
	funcRunStep
fi
#End Log
funcWriteEndLog

#cleanup
rm -r $TmpLog $TmpDir
