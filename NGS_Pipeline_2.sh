#!/usr/bin/env bash

# This line ensures the pipeline stops immediately if any command
# fails, if an undefined variable is used, or if a pipe fails.
# This prevents errors from propagating silently through the pipeline.
set -euo pipefail

# ============================================================
# NGS PIPELINE - NGS0001 — ALTERNATIVE PIPELINE (BOWTIE2)
# Advanced Bioinformatics Assessment 2026
# Student ID: K25163716
# Module: 7BBG2016
#
# This script is identical to NGS_Pipeline_1.sh except that
# BWA-MEM has been replaced with Bowtie2 as the aligner.
# All other steps remain unchanged.
# ============================================================

# ------------------------------------------------------------
# SECTION 2.1: TOOL INSTALLATION
# Tools are installed primarily via conda (bioconda and
# conda-forge channels) to ensure consistent dependency
# management. Where required, system-level installation is
# used for utilities not available through conda.
#
# The conda build of FreeBayes (v0.9.21) produced segmentation
# faults when used with the --targets option. A static binary
# (v1.3.6) was therefore used as a stable alternative.
# Bowtie2 is the only additional tool required for this
# alternative pipeline and is installed via apt.
# ------------------------------------------------------------

# Add required conda channels
conda config --add channels defaults
conda config --add channels bioconda
conda config --add channels conda-forge

# Install core pipeline tools
conda install -y samtools fastqc trimmomatic picard bedtools

# Install vcffilter (vcflib), tabix and Bowtie2 via apt
# These were not reliably available through conda on this system
sudo apt install -y libvcflib-tools tabix bowtie2

# Install FreeBayes static binary (v1.3.6)
wget https://github.com/freebayes/freebayes/releases/download/v1.3.6/freebayes-1.3.6-linux-amd64-static.gz
gunzip freebayes-1.3.6-linux-amd64-static.gz
chmod +x freebayes-1.3.6-linux-amd64-static
sudo mv freebayes-1.3.6-linux-amd64-static /usr/local/bin/freebayes

# Install snpEff (manual download — not available via conda)
# snpEff is Java-based and does not require compilation
mkdir -p ~/ngs_pipeline_bowtie2/results/annotated/snpeff
wget -P ~/ngs_pipeline_bowtie2/results/annotated/snpeff/ \
    https://github.com/pcingola/SnpEff/releases/download/v5.2/snpEff_v5.2_core.zip
unzip ~/ngs_pipeline_bowtie2/results/annotated/snpeff/snpEff_v5.2_core.zip \
    -d ~/ngs_pipeline_bowtie2/results/annotated/snpeff/

# Install ANNOVAR (manual registration required at
# https://www.openbioinformatics.org/annovar/annovar_download_form.php)
# After downloading, upload to instance and extract:
mkdir -p ~/ngs_pipeline_bowtie2/results/annotated/annovar
tar -zxvf ~/ngs_pipeline_bowtie2/results/annotated/annovar/annovar.latest.tar.gz \
    -C ~/ngs_pipeline_bowtie2/results/annotated/annovar/

# Download ANNOVAR annotation databases
# refGene: gene-based annotation using RefSeq transcripts
perl ~/ngs_pipeline_bowtie2/results/annotated/annovar/annovar/annotate_variation.pl \
    -buildver hg19 -downdb -webfrom annovar refGene \
    ~/ngs_pipeline_bowtie2/results/annotated/annovar/annovar/humandb/

# ensGene: alternative Ensembl-based annotation
perl ~/ngs_pipeline_bowtie2/results/annotated/annovar/annovar/annotate_variation.pl \
    -buildver hg19 -downdb -webfrom annovar ensGene \
    ~/ngs_pipeline_bowtie2/results/annotated/annovar/annovar/humandb/

# clinvar_20180603: known clinically significant variants
perl ~/ngs_pipeline_bowtie2/results/annotated/annovar/annovar/annotate_variation.pl \
    -buildver hg19 -downdb -webfrom annovar clinvar_20180603 \
    ~/ngs_pipeline_bowtie2/results/annotated/annovar/annovar/humandb/

# exac03: population allele frequencies from 60,706 exomes
perl ~/ngs_pipeline_bowtie2/results/annotated/annovar/annovar/annotate_variation.pl \
    -buildver hg19 -downdb -webfrom annovar exac03 \
    ~/ngs_pipeline_bowtie2/results/annotated/annovar/annovar/humandb/

# dbnsfp31a_interpro: functional predictions and protein domain annotations
perl ~/ngs_pipeline_bowtie2/results/annotated/annovar/annovar/annotate_variation.pl \
    -buildver hg19 -downdb -webfrom annovar dbnsfp31a_interpro \
    ~/ngs_pipeline_bowtie2/results/annotated/annovar/annovar/humandb/

# ------------------------------------------------------------
# SECTION 2.1: DIRECTORY STRUCTURE
# Separate output directory used to keep Bowtie2 results
# distinct from the main BWA-MEM pipeline outputs.
# ------------------------------------------------------------

mkdir -p ~/ngs_pipeline_bowtie2/data/untrimmed_fastq \
         ~/ngs_pipeline_bowtie2/data/trimmed_fastq \
         ~/ngs_pipeline_bowtie2/data/reference \
         ~/ngs_pipeline_bowtie2/data/reference/bowtie2_index \
         ~/ngs_pipeline_bowtie2/data/aligned_data \
         ~/ngs_pipeline_bowtie2/data/bed \
         ~/ngs_pipeline_bowtie2/results/fastqc/untrimmed \
         ~/ngs_pipeline_bowtie2/results/fastqc/trimmed \
         ~/ngs_pipeline_bowtie2/results/VCF \
         ~/ngs_pipeline_bowtie2/results/stats \
         ~/ngs_pipeline_bowtie2/results/annotated/annovar \
         ~/ngs_pipeline_bowtie2/results/annotated/snpeff \
         ~/ngs_pipeline_bowtie2/logs

# ------------------------------------------------------------
# SECTION 2.1: INPUT DATA
# FASTQ files are provided with a non-standard .qz extension.
# These are gzip-compressed and are renamed to .gz to ensure
# compatibility with downstream tools.
# ------------------------------------------------------------

wget -P ~/ngs_pipeline_bowtie2/data/untrimmed_fastq \
    https://s3-eu-west-1.amazonaws.com/workshopdata2017/NGS0001.R1.fastq.qz
wget -P ~/ngs_pipeline_bowtie2/data/untrimmed_fastq \
    https://s3-eu-west-1.amazonaws.com/workshopdata2017/NGS0001.R2.fastq.qz

mv ~/ngs_pipeline_bowtie2/data/untrimmed_fastq/NGS0001.R1.fastq.qz \
   ~/ngs_pipeline_bowtie2/data/untrimmed_fastq/NGS0001.R1.fastq.gz
mv ~/ngs_pipeline_bowtie2/data/untrimmed_fastq/NGS0001.R2.fastq.qz \
   ~/ngs_pipeline_bowtie2/data/untrimmed_fastq/NGS0001.R2.fastq.gz

# Annotation BED file defines the targeted exome capture regions
wget -P ~/ngs_pipeline_bowtie2/data/bed \
    https://s3-eu-west-1.amazonaws.com/workshopdata2017/annotation.bed

# Download and decompress hg19 reference genome
wget -P ~/ngs_pipeline_bowtie2/data/reference \
    http://hgdownload.cse.ucsc.edu/goldenPath/hg19/bigZips/hg19.fa.gz
gunzip ~/ngs_pipeline_bowtie2/data/reference/hg19.fa.gz

# ============================================================
# SECTION 2.2: PRE-ALIGNMENT QUALITY CONTROL
# ============================================================

# Initial quality assessment of raw reads
# Evaluates base quality, GC distribution, duplication and adapter content
fastqc -t 2 \
    ~/ngs_pipeline_bowtie2/data/untrimmed_fastq/NGS0001.R1.fastq.gz \
    ~/ngs_pipeline_bowtie2/data/untrimmed_fastq/NGS0001.R2.fastq.gz \
    -o ~/ngs_pipeline_bowtie2/results/fastqc/untrimmed/

# Adapter removal and quality trimming using Trimmomatic
# PE mode processes paired reads jointly to maintain read pairing
# ILLUMINACLIP removes Nextera adapter sequences (2:30:10 thresholds)
# TRAILING:25 removes low-quality bases from 3' ends
# MINLEN:50 discards reads too short to align reliably
# The adapter file is located dynamically to ensure reproducibility
# across different trimmomatic installations
trimmomatic PE \
    -threads 4 \
    -phred33 \
    ~/ngs_pipeline_bowtie2/data/untrimmed_fastq/NGS0001.R1.fastq.gz \
    ~/ngs_pipeline_bowtie2/data/untrimmed_fastq/NGS0001.R2.fastq.gz \
    -baseout ~/ngs_pipeline_bowtie2/data/trimmed_fastq/NGS0001 \
    ILLUMINACLIP:$(find ~/anaconda3 -name "NexteraPE-PE.fa" | head -1):2:30:10 \
    TRAILING:25 MINLEN:50

# Post-trimming quality assessment
# Confirms adapter removal and improvement in base quality scores
fastqc -t 2 \
    ~/ngs_pipeline_bowtie2/data/trimmed_fastq/NGS0001_1P \
    ~/ngs_pipeline_bowtie2/data/trimmed_fastq/NGS0001_2P \
    -o ~/ngs_pipeline_bowtie2/results/fastqc/trimmed/

# ============================================================
# SECTION 2.3: ALIGNMENT WITH BOWTIE2
# Bowtie2 replaces BWA-MEM as the aligner.
# All post-alignment steps remain identical to NGS_Pipeline_1.sh.
# ============================================================

# Index reference genome
# samtools faidx creates .fai index required by FreeBayes
# bowtie2-build creates the Bowtie2-specific FM-index
samtools faidx ~/ngs_pipeline_bowtie2/data/reference/hg19.fa

bowtie2-build \
    ~/ngs_pipeline_bowtie2/data/reference/hg19.fa \
    ~/ngs_pipeline_bowtie2/data/reference/bowtie2_index/hg19

# Alignment with Bowtie2
# Read group tags are identical to the main pipeline to ensure
# consistency with downstream Picard and FreeBayes requirements
# -x      : Bowtie2 index base name
# -1/-2   : paired-end input files
# -p 4    : use 4 threads
# --rg-id : read group ID
# --rg    : additional read group fields (SM, PL, LB, PU, DT)
# -S      : output SAM file
bowtie2 \
    -x ~/ngs_pipeline_bowtie2/data/reference/bowtie2_index/hg19 \
    -1 ~/ngs_pipeline_bowtie2/data/trimmed_fastq/NGS0001_1P \
    -2 ~/ngs_pipeline_bowtie2/data/trimmed_fastq/NGS0001_2P \
    -p 4 \
    --rg-id HWI-D0011.50.H7AP8ADXX.1.NGS0001 \
    --rg SM:NGS0001 \
    --rg PL:ILLUMINA \
    --rg LB:nextera-ngs0001-blood \
    --rg PU:11V6WR1 \
    --rg DT:2017-02-23 \
    -S ~/ngs_pipeline_bowtie2/data/aligned_data/NGS0001_bowtie2.sam

# Convert SAM to BAM, sort by coordinate and index
# Coordinate sorting and indexing is required by all downstream tools
samtools view -h -b \
    ~/ngs_pipeline_bowtie2/data/aligned_data/NGS0001_bowtie2.sam \
    > ~/ngs_pipeline_bowtie2/data/aligned_data/NGS0001_bowtie2.bam

samtools sort \
    ~/ngs_pipeline_bowtie2/data/aligned_data/NGS0001_bowtie2.bam \
    > ~/ngs_pipeline_bowtie2/data/aligned_data/NGS0001_bowtie2_sorted.bam

samtools index ~/ngs_pipeline_bowtie2/data/aligned_data/NGS0001_bowtie2_sorted.bam

# The intermediate SAM and unsorted BAM files are no longer needed
# at this point and can be removed if disk space is limited:
# rm ~/ngs_pipeline_bowtie2/data/aligned_data/NGS0001_bowtie2.sam
# rm ~/ngs_pipeline_bowtie2/data/aligned_data/NGS0001_bowtie2.bam

# Duplicate marking to reduce bias from PCR amplification
picard MarkDuplicates \
    I=~/ngs_pipeline_bowtie2/data/aligned_data/NGS0001_bowtie2_sorted.bam \
    O=~/ngs_pipeline_bowtie2/data/aligned_data/NGS0001_bowtie2_sorted_marked.bam \
    M=~/ngs_pipeline_bowtie2/results/stats/NGS0001_bowtie2_marked_dup_metrics.txt

samtools index ~/ngs_pipeline_bowtie2/data/aligned_data/NGS0001_bowtie2_sorted_marked.bam

# Alignment filtering
# -F 1796 excludes unmapped, non-primary, QC-failed and duplicate reads
# -q 20 retains only reads with mapping quality of 20 or above
samtools view \
    -F 1796 \
    -q 20 \
    -o ~/ngs_pipeline_bowtie2/data/aligned_data/NGS0001_bowtie2_sorted_filtered.bam \
    ~/ngs_pipeline_bowtie2/data/aligned_data/NGS0001_bowtie2_sorted_marked.bam

samtools index ~/ngs_pipeline_bowtie2/data/aligned_data/NGS0001_bowtie2_sorted_filtered.bam

# Alignment statistics
samtools flagstat \
    ~/ngs_pipeline_bowtie2/data/aligned_data/NGS0001_bowtie2_sorted_filtered.bam \
    > ~/ngs_pipeline_bowtie2/results/stats/NGS0001_bowtie2_flagstat.txt

samtools idxstats \
    ~/ngs_pipeline_bowtie2/data/aligned_data/NGS0001_bowtie2_sorted_filtered.bam \
    > ~/ngs_pipeline_bowtie2/results/stats/NGS0001_bowtie2_idxstats.txt

picard CollectInsertSizeMetrics \
    I=~/ngs_pipeline_bowtie2/data/aligned_data/NGS0001_bowtie2_sorted_filtered.bam \
    O=~/ngs_pipeline_bowtie2/results/stats/NGS0001_bowtie2_insert_size_metrics.txt \
    H=~/ngs_pipeline_bowtie2/results/stats/NGS0001_bowtie2_insert_size_histogram.pdf \
    M=0.5

# Depth of coverage across all positions
# Note: this reports genome-wide depth; exome-specific depth
# assessment would require restricting to BED-defined regions
samtools depth \
    -a \
    ~/ngs_pipeline_bowtie2/data/aligned_data/NGS0001_bowtie2_sorted_filtered.bam \
    > ~/ngs_pipeline_bowtie2/results/stats/NGS0001_bowtie2_depth.txt

# ============================================================
# SECTION 2.4: VARIANT CALLING AND FILTERING
# ============================================================

# FreeBayes variant calling restricted to targeted capture regions
# --targets restricts calling to BED-defined regions, reducing
# runtime and excluding unreliable off-target calls
# Full path used to ensure v1.3.6 static binary is called
# rather than the older conda version
/usr/local/bin/freebayes \
    --bam ~/ngs_pipeline_bowtie2/data/aligned_data/NGS0001_bowtie2_sorted_filtered.bam \
    --fasta-reference ~/ngs_pipeline_bowtie2/data/reference/hg19.fa \
    --targets ~/ngs_pipeline_bowtie2/data/bed/annotation.bed \
    --vcf ~/ngs_pipeline_bowtie2/results/VCF/NGS0001_bowtie2.vcf

# Compress and index the raw VCF
bgzip ~/ngs_pipeline_bowtie2/results/VCF/NGS0001_bowtie2.vcf
tabix -p vcf ~/ngs_pipeline_bowtie2/results/VCF/NGS0001_bowtie2.vcf.gz

# Hard filtering to remove low-confidence variant calls
# QUAL > 20: retains calls with <1% probability of error
# QUAL / AO > 10: ensures quality is supported per observation
# SAF > 0 & SAR > 0: requires evidence on both strands
# RPR > 1 & RPL > 1: requires balanced read support on both flanks
vcffilter -f "QUAL > 20 & QUAL / AO > 10 & SAF > 0 & SAR > 0 & RPR > 1 & RPL > 1" \
    ~/ngs_pipeline_bowtie2/results/VCF/NGS0001_bowtie2.vcf.gz \
    > ~/ngs_pipeline_bowtie2/results/VCF/NGS0001_bowtie2_filtered.vcf

bgzip ~/ngs_pipeline_bowtie2/results/VCF/NGS0001_bowtie2_filtered.vcf
tabix -p vcf ~/ngs_pipeline_bowtie2/results/VCF/NGS0001_bowtie2_filtered.vcf.gz

# ============================================================
# SECTION 2.5: VARIANT ANNOTATION AND PRIORITISATION
# ============================================================

# ------------------------------------------------------------
# ANNOVAR ANNOTATION
# Annotates variants against multiple curated databases
# simultaneously for gene-level, clinical, population
# frequency and functional prediction information
# ------------------------------------------------------------

# Convert filtered VCF to ANNOVAR input format
perl ~/ngs_pipeline_bowtie2/results/annotated/annovar/annovar/convert2annovar.pl \
    -format vcf4 \
    ~/ngs_pipeline_bowtie2/results/VCF/NGS0001_bowtie2_filtered.vcf.gz \
    > ~/ngs_pipeline_bowtie2/results/annotated/annovar/NGS0001_bowtie2_filtered.avinput

# Multi-database annotation
# refGene/ensGene: gene-based annotation (exonic, intronic, splicing)
# clinvar_20180603: known clinically interpreted variants
# exac03: population allele frequencies
# dbnsfp31a_interpro: functional predictions and protein domains
# -operation g,g,f,f,f: gene-based then filter-based annotation
# -nastring .: missing values represented as dots
# -csvout: output as CSV for downstream review
perl ~/ngs_pipeline_bowtie2/results/annotated/annovar/annovar/table_annovar.pl \
    ~/ngs_pipeline_bowtie2/results/annotated/annovar/NGS0001_bowtie2_filtered.avinput \
    ~/ngs_pipeline_bowtie2/results/annotated/annovar/annovar/humandb/ \
    -buildver hg19 \
    -out ~/ngs_pipeline_bowtie2/results/annotated/annovar/NGS0001_bowtie2_filtered \
    -remove \
    -protocol refGene,ensGene,clinvar_20180603,exac03,dbnsfp31a_interpro \
    -operation g,g,f,f,f \
    -otherinfo \
    -nastring . \
    -csvout

# ------------------------------------------------------------
# SNPEFF ANNOTATION
# Provides complementary functional annotation, particularly
# for splice site and regulatory effects. Output is processed
# by SnpSift for database cross-referencing and filtering.
# ------------------------------------------------------------

# Annotate variants using snpEff against GRCh37.75 (hg19 equivalent)
java -jar ~/ngs_pipeline_bowtie2/results/annotated/snpeff/snpEff/snpEff.jar \
    -c ~/ngs_pipeline_bowtie2/results/annotated/snpeff/snpEff/snpEff.config \
    -v GRCh37.75 \
    ~/ngs_pipeline_bowtie2/results/VCF/NGS0001_bowtie2_filtered.vcf.gz \
    > ~/ngs_pipeline_bowtie2/results/annotated/snpeff/NGS0001_bowtie2_snpeff.ann.vcf

# Download and index dbSNP common variants (build 151, GRCh37)
# Used to identify previously reported variants
wget -P ~/ngs_pipeline_bowtie2/results/annotated/snpeff/ \
    https://ftp.ncbi.nih.gov/snp/organisms/human_9606_b151_GRCh37p13/VCF/00-common_all.vcf.gz

# tabix index required by SnpSift for fast random access
tabix -p vcf \
    ~/ngs_pipeline_bowtie2/results/annotated/snpeff/00-common_all.vcf.gz

# Cross-reference with dbSNP to add rsID annotations
# -Xmx8g allocates 8GB RAM for processing the large dbSNP file
java -Xmx8g \
    -jar ~/ngs_pipeline_bowtie2/results/annotated/snpeff/snpEff/SnpSift.jar annotate \
    -v ~/ngs_pipeline_bowtie2/results/annotated/snpeff/00-common_all.vcf.gz \
    ~/ngs_pipeline_bowtie2/results/annotated/snpeff/NGS0001_bowtie2_snpeff.ann.vcf \
    > ~/ngs_pipeline_bowtie2/results/annotated/snpeff/NGS0001_bowtie2_snpsift_dbsnp.ann.vcf

# ------------------------------------------------------------
# VARIANT PRIORITISATION
# Two-step filtering to identify rare potentially pathogenic
# variants in exonic regions not present in common dbSNP
# ------------------------------------------------------------

# Step 1: filter to exonic (coding-effect) variants
java -jar ~/ngs_pipeline_bowtie2/results/annotated/snpeff/snpEff/SnpSift.jar filter \
    "(ANN[*].EFFECT has 'missense_variant') | \
     (ANN[*].EFFECT has 'synonymous_variant') | \
     (ANN[*].EFFECT has 'stop_gained') | \
     (ANN[*].EFFECT has 'stop_lost') | \
     (ANN[*].EFFECT has 'start_lost') | \
     (ANN[*].EFFECT has 'frameshift_variant') | \
     (ANN[*].EFFECT has 'inframe_insertion') | \
     (ANN[*].EFFECT has 'inframe_deletion')" \
    ~/ngs_pipeline_bowtie2/results/annotated/snpeff/NGS0001_bowtie2_snpsift_dbsnp.ann.vcf \
    > ~/ngs_pipeline_bowtie2/results/annotated/snpeff/NGS0001_bowtie2_exonic.ann.vcf

# Step 2: remove variants present in dbSNP
java -jar ~/ngs_pipeline_bowtie2/results/annotated/snpeff/snpEff/SnpSift.jar filter \
    -n "(ID =~ 'rs')" \
    ~/ngs_pipeline_bowtie2/results/annotated/snpeff/NGS0001_bowtie2_exonic.ann.vcf \
    > ~/ngs_pipeline_bowtie2/results/annotated/snpeff/NGS0001_bowtie2_exonic_novel.ann.vcf
