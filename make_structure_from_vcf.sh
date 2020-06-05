#This script converts the vcf file coded as 012 (output of vcftools) to 1 line per individual and two columns per locus structure format. It requires the *.indv vcftools output with taxon labels 

#delete first column of file, as it contains individual numerical id by printing from 2nd column to last

cut -f 2- my_vcf.012 > vcf_012_wo_id.txt

#replace 012 for 01 coding, and -9 for -1 for missing data. This should be done before adding taxa names which might contain numbers in the labels
 
sed -e 's/-1/-9 -9/g' \
-e 's/0/0 0/g' \
-e 's/1/0 1/g' \
-e 's/2/1 1/g' vcf_012_wo_id.txt > structure_01_woID.txt

#optional get number of columns (= number of loci x2 from vcf file). 
#head -1 structure_01_woID.txt | wc -w

#paste individual id name from vcf *.indv

paste -d "\t" my_vcf.indv structure_01_woID.txt > structure012.txt



