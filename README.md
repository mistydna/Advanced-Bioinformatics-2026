# Advanced Bioinformatics 2026 Assessment
**Student ID:** K25163716  
**Module:** 7BBG2016

This repository contains all scripts, code and outputs for the Advanced Bioinformatics 2026 assessment, organised into two sections.

---

## Repository Structure

### 📁 NGS_Pipelines
Contains two bash scripts implementing a full NGS pipeline for paired-end Illumina WES data (sample NGS0001), from raw reads through to variant annotation and prioritisation.

- **NGS_Pipeline_1.sh** — Main pipeline using **BWA-MEM** as the aligner
- **NGS_Pipeline_2.sh** — Alternative pipeline using **Bowtie2** as the aligner (Section 2.6)

Both pipelines cover:
- Tool installation and directory setup
- Pre-alignment QC (FastQC, Trimmomatic)
- Alignment, duplicate marking and BAM filtering (samtools, Picard)
- Variant calling with FreeBayes (v1.3.6)
- VCF filtering with vcffilter
- Variant annotation with ANNOVAR and snpEff/SnpSift
- Variant prioritisation (exonic, novel variants)

> **Note:** ANNOVAR requires manual registration at [openbioinformatics.org](https://www.openbioinformatics.org/annovar/annovar_download_form.php) before the tarball can be placed at the expected path.

---

### 📁 R_RStudio
Contains the R Markdown script and rendered HTML output for the R/RStudio section of the assessment (Tasks 3.1–3.15).

#### HTML Output
Click [here](https://htmlpreview.github.io/?https://github.com/mistydna/Advanced-Bioinformatics-2026/blob/main/R_RStudio/R-section-of-bioinformatics.html) to view the rendered HTML report.

#### Dependencies and Libraries
The following R packages were used:
- `ggplot2` — data visualisation and plotting
- `DESeq2` — RNA-seq normalisation and differential expression analysis
- `pheatmap` — heatmap generation
- `RColorBrewer` — colour palettes for visualisation
- `BiocManager` — used to install Bioconductor packages

#### Data
The RNA-seq data used in Tasks 3.8–3.15 was obtained from the LMS RNA-seq tutorial and can be accessed [here](https://emckclac-my.sharepoint.com/:u:/g/personal/k2037526_kcl_ac_uk/EYabNsg1JVZHrYzuMKqlHFEB_9WI3aHeNLzvk7eGqX-0yQ?e=GOB5VC).

The `data` folder contains:
- `exercise1_counts.csv` — raw gene count matrix (26,301 genes x 9 samples)
- `exercise1_sample_description.info` — sample metadata including condition and batch information
