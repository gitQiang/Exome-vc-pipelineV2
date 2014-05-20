#!/bin/bash
#$ -cwd -l mem=10G,time=4:: -N LocRln

#This script takes a bam file and performs local indel realignment using GATK
#The script by default runs across the entire bam in a single pass, for increased speed it can split the job across chromosome. If you wish to run it as an array across 24 Chromosomes simply call the script with "-t 1-24"
#	InpFil - (required) - Path to Bam file to be realigned
#	RefFiles - (required) - shell file to export variables with locations of reference files, jar files, and resource directories; see list below
#	LogFil - (optional) - File for logging progress
#	TgtBed - (optional) - Exome capture kit targets bed file (must end .bed for GATK compatability) 
#	Flag - A - AllowMisencoded - see GATK manual (https://www.broadinstitute.org/gatk/gatkdocs/org_broadinstitute_sting_gatk_CommandLineGATK.html#--allow_potentially_misencoded_quality_scores), causes GATK to ignore abnormally high quality scores that would otherwise indicate that the quality score encoding was incorrect
#	Flag - P - PipeLine - call the next step in the pipeline at the end of the job
#	Flag - B - BadET - prevent GATK from phoning home
#	Flag - F - Fix mis-encoded base quality scores - see GATK manual. GATK will subtract 31 from all quality scores; used to fix encoding in some datasets (especially older Illumina ones) which starts at Q64 (see https://en.wikipedia.org/wiki/FASTQ_format#Encoding)
#	Help - H - (flag) - get usage information

#list of required vairables in reference file:
# $REF - reference genome in fasta format - must have been indexed using 'bwa index ref.fa'
# $INDEL - Gold standard INDEL reference from GATK
# $INDEL1KG - INDEL reference from 1000 genomes
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
 ExmAln.4.LocalRealignment.sh -i <InputFile> -r <reference_file> -t <targetfile> -l <logfile> -PABH
 or
 -t 1-24 ExmAln.4.LocalRealignment.sh -i <InputFile> -r <reference_file> -t <targetfile> -l <logfile> -PABH

	 -i (required) - Path to Bam file or \".list\" file containing a multiple paths
	 -r (required) - shell file to export variables with locations of reference files and resource directories
	 -l (optional) - Log file
	 -t (optional) - Exome capture kit targets or other genomic intervals bed file (must end .bed for GATK compatability); this file is required if calling the pipeline but otherwise can be omitted
	 -P (flag) - Call next step of exome analysis pipeline after completion of script
	 -A (flag) - AllowMisencoded - see GATK manual
	 -B (flag) - Prevent GATK from phoning home
	 -F (flag) - Fix mis-encoded base quality scores - see GATK manual
	 -H (flag) - echo this message and exit
"

AllowMisencoded="false"
PipeLine="false"
BadET="false"
FixMisencoded="false"

#get arguments
while getopts i:r:l:t:PABFH opt; do
	case "$opt" in
		i) InpFil="$OPTARG";;
		r) RefFil="$OPTARG";; 
		l) LogFil="$OPTARG";;
		t) TgtBed="$OPTARG";; 
		P) PipeLine="true";;
		A) AllowMisencoded="true";;
		B) BadET="true";;
		F) FixMisencoded="true";;
		H) echo "$usage"; exit;;
	esac
done

#load settings file
RefFil=`readlink -f $RefFil`
source $RefFil

#Load script library
source $EXOMPPLN/exome.lib.sh #library functions begin "func"

#Set Local Variables
ArrNum=$SGE_TASK_ID
funcGetTargetFile
BamFil=`readlink -f $InpFil` #resolve absolute path to bam
BamNam=`basename $BamFil | sed s/.bam//` #a name to use for the various files
if [[ -z "$LogFil" ]];then LogFil=$BamNam.LocReal.log; fi # a name for the log file
Chr=$(echo $ArrNum | sed s/24/Y/ | sed s/23/X/)
if [[ "$ArrNum" != "undefined" ]]; then 
	ChrNam=".CHR_$Chr"
	RalDir=LocRealign.$BamNam; mkdir -p $RalDir #directory to collect individual chromosome realignments
	RalLst=LocRealign.$BamNam.list #File listing paths to individual chromosome realignmentsfi
else
	RalDir=.
fi
if [[ "$BUILD" = "hg19" ]]; then Chr=chr$Chr; fi
RalFil=$RalDir/$BamNam.realigned$ChrNam.bam # the output - a realigned bam file for the CHR
TgtFil=$RalDir/$BamNam.target_intervals$ChrNam.list #target intervals file created by GATK RealignerTargetCreator
GatkLog=$BamNam.LocReal$ChrNam.gatklog #a log for GATK to output to, this is then trimmed and added to the script log
TmpLog=$LogFil.LocReal$ChrNam.temp.log #temporary log file 
TmpDir=$BamNam.LocReal$ChrNam.tempdir; mkdir -p $TmpDir #temporary directory

#Start Log
ProcessName="Local Realignment around InDels" # Description of the script - used in log
funcWriteStartLog

#Generate target file
StepName="Create target interval file using GATK RealignerTargetCreator" # Description of this step - used in log
StepCmd="java -Xmx7G -Djava.io.tmpdir=$TmpDir -jar $GATKJAR
 -T RealignerTargetCreator
 -R $REF
 -I $BamFil
 -known $INDEL
 -known $INDEL1KG
 -o $TgtFil
 --filter_mismatching_base_and_quals
 -log $GatkLog" #command to be run
 
if [[ "$ArrNum" == "undefined" ]]; then 
StepCmd=$StepCmd" -L $TgtBed"
else
StepCmd=$StepCmd" -L $Chr"
fi
funcGatkAddArguments
funcRunStep

#Realign InDels
StepName="Realign InDels file using GATK IndelRealigner" # Description of this step - used in log
StepCmd="java -Xmx7G -Djava.io.tmpdir=$TmpDir -jar $GATKJAR
 -T IndelRealigner
 -R $REF
 -I $BamFil
 -targetIntervals $TgtFil
 -known $INDEL
 -known $INDEL1KG
 -o $RalFil
 --filter_mismatching_base_and_quals
 -log $GatkLog" #command to be run
if [[ "$ArrNum" == "undefined" ]]; then 
StepCmd=$StepCmd" -L $TgtBed"
else
StepCmd=$StepCmd" -L $Chr"
fi
funcGatkAddArguments
funcRunStep

#Call next step - if array by chromosome only the first job of the array calls the next job and it is called with a hold until all of the array jobs are finished
if [[ "$ArrNum" -eq 1 ]]; then
	find `pwd` | grep -E bam$ | grep $RalDir | sort -V > $RalLst #generate realigned file list
	NextJob="Generate Base Quality Score Recalibration table"
	QsubCmd="qsub -hold_jid $JOB_ID -o stdostde/ -e stdostde/ $EXOMPPLN/ExmAln.5.GenerateBQSRTable.sh -i $RalLst -r $RefFil -t $TgtBed -l $LogFil -P"
	if [[ "$AllowMisencoded" == "true" ]]; then QsubCmd=$QsubCmd" -A"; fi
	if [[ "$BadET" == "true" ]]; then QsubCmd=$QsubCmd" -B"; fi
	funcPipeLine
elif [[ "$ArrNum" == "undefined"  ]]; then
	NextJob="Generate Base Quality Score Recalibration table"
	QsubCmd="qsub -o stdostde/ -e stdostde/ $EXOMPPLN/ExmAln.5.GenerateBQSRTable.sh -i $RalFil -r $RefFil -t $TgtBed -l $LogFil -P"
	if [[ "$AllowMisencoded" == "true" ]]; then QsubCmd=$QsubCmd" -A"; fi
	if [[ "$BadET" == "true" ]]; then QsubCmd=$QsubCmd" -B"; fi
	funcPipeLine
fi

#End Log
funcWriteEndLog

#Clean up
rm $TgtFil
#if [[ -e $RalFil ]]; then rm $BamFil ${BamFil/bam/bai}; fi
