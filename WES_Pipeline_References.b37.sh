## Resource Directories
export EXOMPPLN="/ifs/scratch/c2b2/af_lab/ads2202/Exome_Seq/scripts/Exome_pipeline_scripts_GATKv3" # Directory containing pipeline shell scripts
export EXOMRES="/ifs/scratch/c2b2/af_lab/ads2202/Exome_Seq/resources" # Directory containing resources/references for pipeline

#jar files
GATKJAR="/ifs/scratch/c2b2/af_lab/ads2202/src/GenomeAnalysisTK_Current/GenomeAnalysisTK.jar" #Current GATK jar file
PICARD="/ifs/scratch/c2b2/af_lab/ads2202/src/picard-tools-1.101/" #directory containing Picard jar files

## References
export BUILD="b37" # shorthand for build
export DBSNP="$EXOMRES/b37/dbsnp_137.b37.vcf" # dbSNP vcf from GATK
export INDEL="$EXOMRES/b37/Mills_and_1000G_gold_standard.indels.b37.vcf" # Gold standard INDEL reference from GATK
export INDEL1KG="$EXOMRES/b37/1000G_phase1.indels.b37.vcf" # INDEL reference from 1000 genomes
export REF="$EXOMRES/b37/human_g1k_v37.fasta" # human 1000 genome assembly from GATK
export HAPMAP="$EXOMRES/b37/hapmap_3.3.b37.vcf" # hapmap vcf from GATK
export TGVCF="$EXOMRES/b37/1000G_omni2.5.b37.vcf" 
export ONEKG="$EXOMRES/b37/1000G_phase1.snps.high_confidence.b37.vcf" # 1000 genome SNPs vcf
export STHSH="$EXOMRES/b37/stampy_b37" # hash file for Stampy - omit ".sthash" extension for compatibility with Stampy
export STIDX="$EXOMRES/b37/stampy_b37" # genome index file for Stampy - omit ".stidx" extension for compatibility with Stampy
export ANNHDB="/ifs/home/c2b2/af_lab/ads2202/scratch/src/annovar/humandb/" #Location of annovar databases

#GATK no-phone-home key
export ETKEY="$EXOMRES/ads2202_c2b2.columbia.edu.key"

#Capture Kit Target Files
export AgtV2="$EXOMRES/SureSelect_All_Exon_V2.hg19.ordered.bed"
export AgtV4="$EXOMRES/SureSelect_All_Exon_V4_hg19.ordered.bed"
export NbgV2="$EXOMRES/SeqCap_EZ_Exome_v2.hg19.targets.bed"
export TGTCODES="AgtV2:AgtV4:NbgV2"