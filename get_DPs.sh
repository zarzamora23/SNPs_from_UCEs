#!/bin/bash

#Filtered file used to calculate DP (Read depth = only filtered reads used for calling) among loci and samples after renamed: /Users/zarzafranco/Desktop/Aphelocoma2/K51_L100/bwa_mapping/B10_snps_complete_nonALT_thin.recode.vcf

#print only lines with UCE information
#sed -n '/PASS/ p' /Users/zarzafranco/Desktop/Aphelocoma2/K51_L100/bwa_mapping/file_to_estimate_DP.vcf > UCE_lines.txt

#split into columns and print only DP info
#awk -F":" '{print $7,$11,$15,$19,$23,$27,$31,$35,$39,$43,$47,$51,$55,$59,$63,$67,$71,$75,$79,$83,$87,$91,$95,$99}' OFS=" " UCE_lines.txt >UCE_DP_24columns.txt

#print UCE name and position of SNP
#awk -F" " '{print $1,$2}' OFS=" " UCE_lines.txt > UCE_name.txt

#paste UCE_name.txt UCE_DP_24columns.txt | awk '{print 0}' > UCE_DP_values.txt

#calculate average per column = per sample among UCEs
awk '
   BEGIN { FS = " "; }
   NR == 1 { print; next; }
  { for (i = 3; i <= NF; i++) { sum[i] += $i; } }
  END {
    printf "\t";
    for (i = 3; i <= NF; i++) { printf "\t%.4g", sum[i] / (NR - 1); }
    print "";
  }
' UCE_DP_values.txt > DP_values_per_sample.txt


#calculate average per raw = per UCE among samples
#awk 'NR==1 { next }
 #       { T=0
 #          for(N=2; N<=NF; N++) T+=$N;
 #          T/=(NF-1)
 #          print $1, T }' file > outfile
           
           