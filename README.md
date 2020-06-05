# SNPs from UCEs
This repository contains scripts used in [Zarza et al. 2016](https://onlinelibrary.wiley.com/doi/full/10.1111/mec.13813) to extract Single nucleotide polymorphism from ultraconserved elements sequence data. Some of these scripts can be found in:

Zarza, Eugenia et al. (2016), Data from: Hidden histories of gene flow in highland birds revealed with genomic markers, Dryad, Dataset, https://doi.org/10.5061/dryad.s8v80

Here you can file the following files:

**11-16-15_Dend_SNPS_Dbar.txt** - Brief instructions on running the scripts and in what order by WLET

**1a_0_bwa_mapping_loop.sh** - Script to map reads to reference with BWA

**1a_1_get_mapping_stats.sh** - Script to get mapping statists

**1a_2_get_samtools_stats.sh** - Script to get statistcs from samtools

**1_mapping-WLET_copy.sh** - Script to map reads to reference with BWA modified by WLET

**2_indelrealigner-WLET_copy.sh** - Script to realign reads with GATK

**3_genotype-recal-WLET_copy.sh** - Script to recalibrate genotypes with GATK

**extract-fasta.txt** - Phyluce commands to extract data from alignments

**get_DPs.sh** - Script o calculate SNP read depth

**make_structure_from_vcf.sh** - Script to get Structure input file from vcf file

**README.md** - This file

**vcf_command.sh** - Commands to convert and filtrate SNPs

**SNAPP_maker**: Directory including scripts and blocks to create a SNAPP input file.

  -- **header.txt** - SNAPP file header block

  -- **mcmc_end_block.txt** - SNAPP mcmc block

  -- **parameters_block.txt** - SNAPP parameter block

  -- **SNAPP_from_nexus.sh** - Script to create SNAPP input file from nexus file


 With contribution from Eugenia Zarza and Whitney L.E. Tsai
