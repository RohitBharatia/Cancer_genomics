# Cancer Genomics Practicals
This course follows the practicals for the Cancer Genomics course for the Bioinformatics Masters at the unibe.   

## Group members
Group #6  
Andy Mucyo Nkunzimana: 19-325-760   
Andri Levi Widmer: 20-105-581  
Rohit Mohan Bharatia: 25-114-455   

## Organisational Matters:
#### File structure
```
project/
├── data/                    # Data
├── scripts/                 # Analysis scripts
├── results/                 # Output results
│   ├── quality_control/     # Quality Control      
│   │  ├── fastQC/
│   │  ├── fastp/
│   │  └── MultiQC/
│   ├── reads_alignment/     # Read alignment 
│   ├── BAM_processing/      # Evaluation results
│   └── quality_calibration/ # Quality calibration
│      ├── BaseRecalibrator/
│      └── ApplyBQSR/
└── README.md                # Documentation
```

#### Scripts
Scripts are numbered in the order of the practicals

#### Data
Data obtained from <add directory here> repository on the UNIBE cluster and symlinked to data in the project directory.


### Tools:
Analysis was done on the University of Bern's HPC cluster. 
The following tools and packages were used: 
##### Part 1: Variant calling
Initial QC:
- FastQC: - https://www.bioinformatics.babraham.ac.uk/projects/fastqc/
- fastp: - https://github.com/OpenGene/fastp 
- MultiQC - https://seqera.io/multiqc/ 

Read Alignment: bwa-mem2: - https://github.com/bwa-mem2/bwa-mem2
BAM Processing: MarkDuplicates: - https://gatk.broadinstitute.org/hc/en-us/articles/360037052812-MarkDuplicates-Picard
Quality Calibration
- BaseRecalibrator: - https://gatk.broadinstitute.org/hc/en-us/articles/360036898312-BaseRecalibrator
- ApplyBQSR: - https://gatk.broadinstitute.org/hc/en-us/articles/360037055712-ApplyBQSR
