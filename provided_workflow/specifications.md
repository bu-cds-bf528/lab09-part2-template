
# Objective

A nextflow pipeline that takes a genome and index, a BED file from UCSC gencode with
transcripts, and extracts the sequence and scans for CRISPR PAM motifs (NGG), returning
a list of possible guide sites and guides

# Inputs

- A fasta file
- A BED file with gene coordinates from UCSC
- A transcript specified as a string in the config

# Outputs

Per gene:

Returns a list containing all possible guide sequences, the chromosome, and the start and
stop of the guide. The search should use the cds start and end. 

# Pipeline Steps

## Pipeline Table

| Step | Tool | Input | Output | Depends on |
|---|---|---|---|---|
| Get genome  | Provided |  -  |  -  | -  |
| Index Genome | Samtools faidx | fasta | fasta + fai | Genome |
| Get cds  | Python | Chosen transcript | Chr + start and stop | bed and choose transcript |
| Choose transcript | Provided | - | - | - |
| Extract the sequence | samtools faidx | fasta + fai + chr start and stop | fasta with gene sequence | index genome and get gene locations |
| Find target sites | seqkit | gene sequence | list of target sites from gene reported as genomic coordinates written out | extracted sequence | 

# Environment and Reproducibility

Samtools: envs/samtools_env.yml
Seqkit: envs/seqkit_env.yml
Python: envs/python_env.yml

# Resource Requirements

Labels in nextflow.config

# Implementation Conventions

None

# Design Choices


# Success Criteria

The pipeline returns the right amount of sites for the synthetic data, the small 
real biological data, and then matches the results from ChopChop.

# Out of Scope

- Files are provided so one genome and one gene at a time
- Verification will be done manually 
- Only search for the canonical PAM motif (NGG)
