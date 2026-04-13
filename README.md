# Advanced Bioinformatics 2026 Assessment
R/RStudio assessment section
Author: K25163716

## HTML Output
Click [here](https://htmlpreview.github.io/?https://github.com/mistydna/Advanced-Bioinformatics-2026/blob/main/R-section-of-bioinformatics.html) to view the rendered HTML report for ## 3.1 to 3.15

## Dependencies and Libraries
The following R packages were used for this secction:
- `ggplot2` — data visualisation and plotting
- `DESeq2` — RNA-seq normalisation and differential expression analysis
- `pheatmap` — heatmap generation
- `RColorBrewer` — colour palettes for visualisation
- `BiocManager` — used to install Bioconductor packages

## Data
The RNA-seq data used in ## Tasks 3.8-3.15 was obtained from the 
LMS RNA-seq tutorial and can be accessed [here](https://emckclac-my.sharepoint.com/:u:/g/personal/k2037526_kcl_ac_uk/EYabNsg1JVZHrYzuMKqlHFEB_9WI3aHeNLzvk7eGqX-0yQ?e=GOB5VC).

The `data` folder contains:
- `exercise1_counts.csv` — raw gene count matrix (26,301 genes x 9 samples)
- `exercise1_sample_description.info` — sample metadata including condition and batch information
