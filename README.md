# DatCol_Manuscript

This repository contains all data, analysis code and documentation for the manuscript:

### D-alanine Aminotransferase (Dat) promotes *Staphylococcus aureus* colonization fitness on human nasal respiratory epithelium

The rendered notebooks are available at <https://klemonlab.github.io/DatCol_Manuscript/>.

## Reproducibility

All analyses are provided as individual Quarto (`.qmd`) notebooks, which can be rendered independently. Each notebook reads processed `.rds` files from the `dataframes/` folder and generates publication-quality figures and statistical outputs (Table S2).

To reproduce the analyses:

-   Clone or download this [repository](https://github.com/KLemonLab/DatCol_Manuscript) to your local machine.
-   Install required R packages listed in [R Session Info](https://klemonlab.github.io/DatCol_Manuscript/Manuscript_DatCol_RSession.html) using `renv` or manually.
-   Render the notebooks using Quarto to generate figures and results.

All input data (`dataframes/` and `Tn-Seq/`) is included in the repository. The notebooks read it through the `BOX_PATH` environment variable, which the `.Renviron` file at the repository root already sets to the repository folder (`BOX_PATH="."`), so no setup is needed. If you keep the data elsewhere, change that line to point to the folder that contains `dataframes/` and `Tn-Seq/`, and restart R.

The whole project can be rendered using RStudio's "Render" or "Build" options or in the terminal via:

```bash
quarto render
```

## Repository Structure

This repository is organized as follows:

```
DatCol_Manuscript/
├── .Renviron                 # sets BOX_PATH="." (the repository folder)
├── _quarto.yml               # Quarto book configuration
├── index.qmd                 # overview page
├── Manuscript_DatCol_*.qmd   # analysis notebooks
├── R/
│   └── LMM_functions.R       # shared linear mixed model functions
├── dataframes/               # processed input data (.csv and .rds)
├── Tn-Seq/
│   ├── RefSeqs/              # reference genome, annotation and COG files
│   ├── sites/                # insertion sites and DESeq2 essential gene results
│   ├── scripts/              # TnGeneBin.pl
│   ├── tables/               # STRING enrichment results and generated tables
│   └── figures/              # generated Tn-Seq figures
├── outputs/                  # generated figures and statistics for each assay
├── SupplementalTables/       # Tables S1 and S2 (.xlsx)
├── docs/                     # rendered website (GitHub Pages)
└── renv.lock                 # R package versions
```

### Data folders

-   [dataframes](https://github.com/KLemonLab/DatCol_Manuscript/tree/main/dataframes)/
    -   Contains all processed data used to generate figures and statistical analyses (see Table S2)
    -   Files are provided in `.csv` and `.rds` formats for easy visualization and reproducibility in R
    -   `.rds` file names correspond to their associated `.qmd` analysis notebooks
    -   `DatCol_CFUs_HNO_Chemical.rds` and `DatCol_CFUs_HNO_Genetic.rds` both correspond to the *Complementation* notebook
    -   `DatCol_CFUs_HNO_Controls.rds` contains all monocolonization control data associated with `HNO_Competition.qmd`
-   [Tn-Seq](https://github.com/KLemonLab/DatCol_Manuscript/tree/main/Tn-Seq)/
    -   Raw FASTQ files are available through the SRA \[insert link or BioProject accession\]
    -   Processed insertion site files are included here to reproduce the Essential Gene Analysis and associated figure generation
    -   Subfolders include:
        -   `RefSeqs/`: reference genome, annotation and COG category files
        -   `sites/`: transposon insertion site files and the DESeq2 essential gene results (`*.TRUE.DESeq.csv`) produced by the [Tn-Seq Pipeline](https://klemonlab.github.io/DatCol_Manuscript/Manuscript_DatCol_Tn-Seq_Pipeline.html)
        -   `scripts/`: includes the `TnGeneBin.pl` Perl script used to bin insertion sites for essential gene analysis
        -   `tables/`: STRING enrichment results (`STRING_Enrichment.log2FC_diff_LAC_vs_Input.tsv`) read by the [Tn-Seq Essential Genes Analysis](https://klemonlab.github.io/DatCol_Manuscript/Manuscript_DatCol_Tn-Seq_Figures.html), plus the tables it writes
        -   `figures/`: figures written by the [Tn-Seq Essential Genes Analysis](https://klemonlab.github.io/DatCol_Manuscript/Manuscript_DatCol_Tn-Seq_Figures.html)

### Analysis Notebooks

-   Main Analysis Notebooks:
    -   [Tn-Seq Pipeline](https://klemonlab.github.io/DatCol_Manuscript/Manuscript_DatCol_Tn-Seq_Pipeline.html)
    -   [Tn-Seq Essential Genes Analysis](https://klemonlab.github.io/DatCol_Manuscript/Manuscript_DatCol_Tn-Seq_Figures.html)
    -   [Competition Assays on HNO-ALI](https://klemonlab.github.io/DatCol_Manuscript/Manuscript_DatCol_HNO_Competition.html)
    -   [Complementation Assays on HNO-ALI](https://klemonlab.github.io/DatCol_Manuscript/Manuscript_DatCol_HNO_Complementation.html)
    -   [Growth Curves (OD600)](https://klemonlab.github.io/DatCol_Manuscript/Manuscript_DatCol_Growth_Curves.html)
    -   [Cocolonization Assays with *Corynebacterium pseudodiphtheriticum*](https://klemonlab.github.io/DatCol_Manuscript/Manuscript_DatCol_HNO_Cps.html)
    -   [Cytotoxicity Assays (LDH)](https://klemonlab.github.io/DatCol_Manuscript/Manuscript_DatCol_LDH.html)
    -   [Alanine in HNO-ALI mucus](https://klemonlab.github.io/DatCol_Manuscript/Manuscript_DatCol_HNO_Alanine.html)
-   Other Notebooks:
    -   [Linear Mixed Model Workflow](https://klemonlab.github.io/DatCol_Manuscript/Manuscript_DatCol_LMMStats.html)
    -   [R Session Info](https://klemonlab.github.io/DatCol_Manuscript/Manuscript_DatCol_RSession.html)
    -   [References](https://klemonlab.github.io/DatCol_Manuscript/references.html)
