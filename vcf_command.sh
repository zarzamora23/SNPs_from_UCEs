
#no missing data allowed; only non-ref alleles are not allowed (in our case possible erroneous mismatch between assembled reference and mapped reads); Thin sites so that no two sites are within the specified distance from one another i.e. 900 to obtain one snp per uce
/Users/zarzafranco/vcftools_0.1.12b/bin/vcftools  --vcf /Users/zarzafranco/Desktop/Aphelocoma2/K51_L100/Structure_analysis/Structure_Nevadae/genotyped_20_samples_only_PASS_snp_4th.vcf --max-missing 1 --max-non-ref-af 0.99 --thin 900 --recode --out /Users/zarzafranco/Desktop/Aphelocoma2/K51_L100/Structure_analysis/Structure_Nevadae/nevadae_recalibrated_filtered_snps

#optional convert to 123 format
/Users/zarzafranco/vcftools_0.1.12b/bin/vcftools  --vcf /Users/zarzafranco/Desktop/Aphelocoma2/K51_L100/bwa_mapping/B10_snps_complete_nonALT_thin.recode.vcf --012 --out B10_012_snp_superfiltered

