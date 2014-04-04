#!/bin/bash
#$ -cwd -pe smp 6 -l mem=2G,time=24:: -N HCgVCF

#This script takes a list of gVCF files generated by the HaplotypeCaller (filename must end ".list") and performs the multi-sample joint aggregation step and merges the records together.
#	InpFil - (required) - List of gVCF files. List file name must end ".list"
#	RefFiles - (required) - shell file to export variables with locations of reference files, jar files, and resource directories; see list below
#	TgtBed - (optional) - Exome capture kit targets bed file (must end .bed for GATK compatability) - only required if calling pipeline
#	LogFil - (optional) - File for logging progress
#	Flag - P - PipeLine - call the next step in the pipeline at the end of the job
#	Flag - B - BadET - prevent GATK from phoning home
#	Help - H - (flag) - get usage information

#list of required vairables in reference file:
# $REF - reference genome in fasta format - must have been indexed using 'bwa index ref.fa'
# $DBSNP - dbSNP vcf from GATK
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
ExmVC.1.HaplotypeCaller_GVCFmode.sh -i <InputFile> -r <reference_file> -t <targetfile> -l <logfile> -PABH

	 -i (required) - Path to Bam file for variant calling or \".list\" file containing a multiple paths
	 -r (required) - shell file to export variables with locations of reference files and resource directories
	 -t (required) - Exome capture kit targets or other genomic intervals bed file (must end .bed for GATK compatability)
	 -l (optional) - Log file
	 -P (flag) - Call next step of exome analysis pipeline after completion of script
	 -A (flag) - AllowMisencoded - see GATK manual
	 -B (flag) - Prevent GATK from phoning home
	 -H (flag) - echo this message and exit
"

AllowMisencoded="false"
PipeLine="false"
BadET="false"

PipeLine="false"
while getopts i:r:l:t:PABH opt; do
	case "$opt" in
		i) InpFil="$OPTARG";;
		r) RefFil="$OPTARG";; 
		l) LogFil="$OPTARG";;
		t) TgtBed="$OPTARG";; 
		P) PipeLine="true";;
		B) BadET="true";;
		H) echo "$usage"; exit;;
  esac
done

#load settings file
source $RefFil

#Load script library
source $EXOMPPLN/exome.lib.sh #library functions begin "func"


#Set local Variables
VcfNam=`basename $InpFil` 
VcfNam=${VcfNam/.list/} # a name for the output files
if [[ -z $LogFil ]]; then LogFil=$VcfNam.GgVCF.log; fi # a name for the log file
VcfFil=$VcfDir/VcfNam.vcf #Output File
GatkLog=$VcfNam.GgVCF.gatklog #a log for GATK to output to, this is then trimmed and added to the script log
TmpLog=$VcfNam.GgVCF.temp.log #temporary log file
TmpDir=$VcfNam.GgVCF.tempdir; mkdir -p $TmpDir #temporary directory
infofields="-A AlleleBalance -A BaseQualityRankSumTest -A Coverage -A HaplotypeScore -A HomopolymerRun -A MappingQualityRankSumTest -A MappingQualityZero -A QualByDepth -A RMSMappingQuality -A SpanningDeletions -A FisherStrand -A InbreedingCoeff" #Annotation fields to output into vcf files

#Start Log File
ProcessName="Genomic VCF generatation with GATK HaplotypeCaller" # Description of the script - used in log
funcWriteStartLog

##Run Joint Variant Calling
StepNam"gVCF generation with GATK HaplotypeCaller..." >> $TmpLog
StepCmd="$JAVA7BIN -Xmx7G -Djava.io.tmpdir=$TmpDir -jar $GATKJAR
 -T HaplotypeCaller
 -R $REF
 -L $TgtBed
 -nct 6
 -I $VcfFil
 --genotyping_mode DISCOVERY
 -stand_emit_conf 10
 -stand_call_conf 30
 --emitRefConfidence GVCF
 --variant_index_type LINEAR
 --variant_index_parameter 128000
 -o $VcfFil
 -D $DBSNP
 --comp:HapMapV3 $HpMpV3 
 -pairHMM VECTOR_LOGLESS_CACHING
 -rf BadCigar
 $infofields" #command to be run
funcGatkAddArguments
funcRunStep

#Call next step
#NextJob="Get basic Vcf metrics"
#QsubCmd="qsub -o stdostde/ -e stdostde/ $EXOMPPLN/ExmAln.3a.Vcf_metrics.sh -i $RclLst -r $RefFil -l $LogFil -Q"
#funcPipeLine

#End Log
funcWriteEndLog