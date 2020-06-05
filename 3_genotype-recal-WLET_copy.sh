#realigning the mapping produced with BWA with a gap penalty B=10. The minimum number of reads per locus was set to 10

#reference taxon
REFERENCE=/Users/wtsai/DendHum/Dendrortyx/Dend-SNPs/map-to-ref-Dbar_47371/Dbar_47371_PUE.fasta

#realigned bams after removing duplicates with picard
REALIGNED_BAMS=/Users/wtsai/DendHum/Dendrortyx/Dend-SNPs/map-to-ref-Dbar_47371/*realigned.bam


for sample in $REALIGNED_BAMS
do 
#taxon or sample we are working now
    echo "Processing $sample"
#create a variable with the sample name using the name of the dedup bam file. We use the cut command, using the character '/' as field delimiter. In my case, this will cut the taxon path into 9 fields. The command -f8 tells to keep only the 9th field, which is the sample name     
    OUTPUT_BASENAME=$(echo $sample | cut -d/ -f8)
    echo $OUTPUT_BASENAME
    OUTPUT_NAME=$(echo $OUTPUT_BASENAME | cut -d. -f1)'.g.vcf'
    echo $OUTPUT_NAME

#execute the command in GATK for haplotype call. Variant discovery with HaplotypeCaller. Normal mode can process all samples merged in one file. with gVCF each sample needs to be processed at a time. This is the mode needed to serve as input for GenotypeGVCF
   
   eval $(echo "java -Xmx4g -jar /Users/wtsai/GenomeAnalysisTK-3.4-46/GenomeAnalysisTK.jar -T HaplotypeCaller -R $REFERENCE -I $sample -o $OUTPUT_NAME --emitRefConfidence GVCF --variant_index_type LINEAR --variant_index_parameter 128000 --contamination_fraction_to_filter 0.0002 --min_base_quality_score 20 --phredScaledGlobalReadMismappingRate 30 --standard_min_confidence_threshold_for_calling 40.0 --standard_min_confidence_threshold_for_emitting 40.0")
   
done

#Get the names of the vcf files to be used in the next step
ls -d -1 $PWD/*.g.vcf > gvcf.list


#Genotyping with GVCF in all the variant files produced by HaplotypeCaller gvcf; merges files and contains only variable sites. Create 
java -Xmx4g -jar /Users/wtsai/GenomeAnalysisTK-3.4-46/GenomeAnalysisTK.jar  -R $REFERENCE -T GenotypeGVCFs \
--standard_min_confidence_threshold_for_calling 40.0 --standard_min_confidence_threshold_for_emitting 40.0 \
-V gvcf.list \
-o genotyped_X_samples.g.vcf

 #Extract the SNPs from the call set
java -jar /Users/wtsai/GenomeAnalysisTK-3.4-46/GenomeAnalysisTK.jar \
-T SelectVariants \
-R $REFERENCE  \
-V genotyped_X_samples.g.vcf \
-selectType SNP \
-o genotyped_X_samples_snps.vcf


#Extract the indels from the call set
java -jar /Users/wtsai/GenomeAnalysisTK-3.4-46/GenomeAnalysisTK.jar \
-T SelectVariants \
-R $REFERENCE  \
-V genotyped_X_samples.g.vcf \
-selectType INDEL \
-o genotyped_X_samples_indels.vcf

#filter SNP calls around indels and apply quality filters following Faircloth https://gist.github.com/brantfaircloth/4315737 and http://gatkforums.broadinstitute.org/discussion/3286/quality-score-recalibration-for-non-model-organisms   

java -jar /Users/wtsai/GenomeAnalysisTK-3.4-46/GenomeAnalysisTK.jar \
-T VariantFiltration \
-R $REFERENCE  \
-V genotyped_X_samples_snps.vcf \
--mask genotyped_X_samples_indels.vcf \
--maskExtension 5 \
--maskName InDel \
--clusterWindowSize 10 \
--filterExpression "MQ0 >= 4 && ((MQ0 / (1.0 * DP)) > 0.1)" \
--filterName "BadValidation" \
--filterExpression "QUAL < 30.0" \
--filterName "LowQual" \
--filterExpression "QD < 5.0" \
--filterName "LowVQCBD" \
--filterExpression "FS > 60" \
--filterName "FisherStrand" \
-o genotyped_X_samples_filtered_1st.vcf

# get only pass snps
cat genotyped_X_samples_filtered_1st.vcf | grep 'PASS\|^#' > genotyped_X_samples_only_PASS_snp.vcf

#base recalibration loop

for sample in $REALIGNED_BAMS
do 
#taxon or sample we are working now
    echo "Processing $sample"
#create a variable with the sample name using the name of the dedup bam file. We use the cut command, using the character '/' as field delimiter. In my case, this will cut the taxon path into 9 fields. The command -f8 tells to keep only the 9th field, which is the sample name     
    FILE_BASENAME=$(echo $sample | cut -d/ -f8)
    echo $FILE_BASENAME
   TABLE_NAME=$(echo $FILE_BASENAME | cut -d. -f1)'.table'
    echo $TABLE_NAME
    RECAL_OUT=$(echo $FILE_BASENAME | cut -d. -f1)'_recal.bam'
    RECAL_OUT_bai=$(echo $FILE_BASENAME | cut -d. -f1)'_recal.bai'

#execute the command in GATK for base recalibration
   
   eval $(echo "java -jar /Users/wtsai/GenomeAnalysisTK-3.4-46/GenomeAnalysisTK.jar -T BaseRecalibrator -R $REFERENCE -I $sample -knownSites genotyped_X_samples_only_PASS_snp.vcf -o $TABLE_NAME")  
   eval $(echo "java -jar /Users/wtsai/GenomeAnalysisTK-3.4-46/GenomeAnalysisTK.jar -T PrintReads -R $REFERENCE -I $sample -BQSR $TABLE_NAME -o $RECAL_OUT")

	#mv $RECAL_OUT ${RECAL_OUT//All_dedup_realigned_recal/recal}
	#mv $RECAL_OUT_bai ${RECAL_OUT_bai//All_dedup_realigned_recal/recal}
done

RECAL_BAMS=/Users/wtsai/DendHum/Dendrortyx/Dend-SNPs/map-to-ref-Dbar_47371/*_recal.bam

#Haplotype calling on 1st recalibrated bam

for bam_recal in $RECAL_BAMS
do 
#taxon or sample we are working now
    echo "Processing $bam_recal"
#create a variable with the sample name using the name of the recalibrated bam file. We use the cut command, using the character '/' as field delimiter. In my case, this will cut the taxon path into 9 fields. The command -f8 tells to keep only the 9th field, which is the sample name     
    RECAL1_BASENAME=$(echo $bam_recal | cut -d/ -f8)
    echo $RECAL1_BASENAME
    RECAL1_NAME=$(echo $RECAL1_BASENAME | cut -d. -f1)'.g.vcf'
    echo $RECAL1_NAME

#execute the command in GATK for haplotype call on recalibrated bams. 
   
   eval $(echo "java -Xmx4g -jar /Users/wtsai/GenomeAnalysisTK-3.4-46/GenomeAnalysisTK.jar -T HaplotypeCaller -R $REFERENCE -I $bam_recal -o $RECAL1_NAME --emitRefConfidence GVCF --variant_index_type LINEAR --variant_index_parameter 128000 --contamination_fraction_to_filter 0.0002 --min_base_quality_score 20 --phredScaledGlobalReadMismappingRate 30 --standard_min_confidence_threshold_for_calling 40.0 --standard_min_confidence_threshold_for_emitting 40.0")
   
   
done

#Get the names of the recal vcf files to be used in the next step
ls -d -1 $PWD/*_recal.g.vcf > recal_vcf.list

#Genotyping with GVCF in all the variant files produced by HaplotypeCaller gvcf; merges files and contains only variable sites
java -Xmx4g -jar /Users/wtsai/GenomeAnalysisTK-3.4-46/GenomeAnalysisTK.jar  -R $REFERENCE -T GenotypeGVCFs \
--standard_min_confidence_threshold_for_calling 40.0 --standard_min_confidence_threshold_for_emitting 40.0 \
-V recal_vcf.list \
-o genotyped_X_samples_recal.g.vcf

 #Extract the SNPs from the call set
java -jar /Users/wtsai/GenomeAnalysisTK-3.4-46/GenomeAnalysisTK.jar \
-T SelectVariants \
-R $REFERENCE  \
-V genotyped_X_samples_recal.g.vcf \
-selectType SNP \
-o genotyped_X_samples_recal_snps.vcf


#Extract the indels from the call set
java -jar /Users/wtsai/GenomeAnalysisTK-3.4-46/GenomeAnalysisTK.jar \
-T SelectVariants \
-R $REFERENCE  \
-V genotyped_X_samples_recal.g.vcf \
-selectType INDEL \
-o genotyped_X_samples_recal_indels.vcf

#filter SNP calls around indels and apply quality filters following Faircloth https://gist.github.com/brantfaircloth/4315737 and http://gatkforums.broadinstitute.org/discussion/3286/quality-score-recalibration-for-non-model-organisms   

java -jar /Users/wtsai/GenomeAnalysisTK-3.4-46/GenomeAnalysisTK.jar \
-T VariantFiltration \
-R $REFERENCE  \
-V genotyped_X_samples_recal_snps.vcf \
--mask genotyped_X_samples_recal_indels.vcf \
--maskExtension 5 \
--maskName InDel \
--clusterWindowSize 10 \
--filterExpression "MQ0 >= 4 && ((MQ0 / (1.0 * DP)) > 0.1)" \
--filterName "BadValidation" \
--filterExpression "QUAL < 30.0" \
--filterName "LowQual" \
--filterExpression "QD < 5.0" \
--filterName "LowVQCBD" \
--filterExpression "FS > 60" \
--filterName "FisherStrand" \
-o genotyped_X_samples_filtered_2nd.vcf

# get only pass snps
cat genotyped_X_samples_filtered_2nd.vcf | grep 'PASS\|^#' > genotyped_X_samples_only_PASS_snp_2nd.vcf


#base recalibration loop 2nd recalibration on uncalibrated bams!

for sample in $REALIGNED_BAMS
do 
# taxon or sample we are working now
    echo "Processing $sample"
# create a variable with the sample name using the name of the original bam file. We use the cut command, using the character '/' as field delimiter. In my case, this will cut the taxon path into 9 fields. The command -f8 tells to keep only the 9th field, which is the sample name     
    FILE2_BASENAME=$(echo $sample | cut -d/ -f8)
    echo $FILE2_BASENAME
    TABLE2_NAME=$(echo $FILE2_BASENAME | cut -d. -f1)'2.table'
    echo $TABLE2_NAME
    RECAL2_OUT=$(echo $FILE2_BASENAME | cut -d. -f1)'_2recal.bam'
    RECAL2_OUT_bai=$(echo $FILE2_BASENAME | cut -d. -f1)'_2recal.bai'

# execute the command in GATK for base recalibration
   
   eval $(echo "java -jar /Users/wtsai/GenomeAnalysisTK-3.4-46/GenomeAnalysisTK.jar -T BaseRecalibrator -R $REFERENCE -I $sample -knownSites genotyped_X_samples_only_PASS_snp_2nd.vcf -o $TABLE2_NAME")  
   eval $(echo "java -jar /Users/wtsai/GenomeAnalysisTK-3.4-46/GenomeAnalysisTK.jar -T PrintReads -R $REFERENCE -I $sample -BQSR $TABLE2_NAME -o $RECAL2_OUT")

	#mv $RECAL2_OUT ${RECAL2_OUT//All_dedup_realigned_2recal/2recal}
	echo RECAL_OUT_bai 
    #mv $RECAL2_OUT_bai ${RECAL2_OUT_bai//All_dedup_realigned_2recal/2recal}
    
done

RECAL2_BAMS=/Users/wtsai/DendHum/Dendrortyx/Dend-SNPs/map-to-ref-Dbar_47371/*_2recal.bam

# Haplotype calling on 2nd recalibrated bam

for bam2_recal in $RECAL2_BAMS
do 
# taxon or sample we are working now
    echo "Processing $bam2_recal"
# create a variable with the sample name using the name of the recalibrated bam file. We use the cut command, using the character '/' as field delimiter. In my case, this will cut the taxon path into 9 fields. The command -f8 tells to keep only the 9th field, which is the sample name     
    RECAL2_BASENAME=$(echo $bam2_recal | cut -d/ -f8)
	echo $RECAL2_BASENAME
   	RECAL2_NAME=$(echo $RECAL2_BASENAME | cut -d. -f1)'.g.vcf'
    echo $RECAL2_NAME

#execute the command in GATK for haplotype call on 2nd recalibrated bams. 
   
   eval $(echo "java -Xmx4g -jar /Users/wtsai/GenomeAnalysisTK-3.4-46/GenomeAnalysisTK.jar -T HaplotypeCaller -R $REFERENCE -I $bam2_recal -o $RECAL2_NAME --emitRefConfidence GVCF --variant_index_type LINEAR --variant_index_parameter 128000 --contamination_fraction_to_filter 0.0002 --min_base_quality_score 20 --phredScaledGlobalReadMismappingRate 30 --standard_min_confidence_threshold_for_calling 40.0 --standard_min_confidence_threshold_for_emitting 40.0")
   
   #mv $RECAL2_NAME ${RECAL2_NAME//_recal_2recal/_2recal}
   #mv $RECAL2_NAME'.idx' ${RECAL2_NAME//_recal_2recal/_2recal}'.idx'
done

#get list of files produced from 2nd recalibration to be used in next step
ls -d -1 $PWD/*_2recal.g.vcf > recal2_vcf.list


#Genotyping with GVCF in all the variant files produced by HaplotypeCaller gvcf; merges files and contains only variable sites
java -Xmx4g -jar /Users/wtsai/GenomeAnalysisTK-3.4-46/GenomeAnalysisTK.jar  -R $REFERENCE -T GenotypeGVCFs \
--standard_min_confidence_threshold_for_calling 40.0 --standard_min_confidence_threshold_for_emitting 40.0 \
-V recal2_vcf.list \
-o genotyped_X_samples_2recal.g.vcf

# Extract the SNPs from the call set
java -jar /Users/wtsai/GenomeAnalysisTK-3.4-46/GenomeAnalysisTK.jar \
-T SelectVariants \
-R $REFERENCE  \
-V genotyped_X_samples_2recal.g.vcf \
-selectType SNP \
-o genotyped_X_samples_2recal_snps.vcf


# Extract the indels from the call set
java -jar /Users/wtsai/GenomeAnalysisTK-3.4-46/GenomeAnalysisTK.jar \
-T SelectVariants \
-R $REFERENCE  \
-V genotyped_X_samples_2recal.g.vcf \
-selectType INDEL \
-o genotyped_X_samples_2recal_indels.vcf

# filter SNP calls around indels and apply quality filters following Faircloth https://gist.github.com/brantfaircloth/4315737 and http://gatkforums.broadinstitute.org/discussion/3286/quality-score-recalibration-for-non-model-organisms   

java -jar /Users/wtsai/GenomeAnalysisTK-3.4-46/GenomeAnalysisTK.jar \
-T VariantFiltration \
-R $REFERENCE  \
-V genotyped_X_samples_2recal_snps.vcf \
--mask genotyped_X_samples_2recal_indels.vcf \
--maskExtension 5 \
--maskName InDel \
--clusterWindowSize 10 \
--filterExpression "MQ0 >= 4 && ((MQ0 / (1.0 * DP)) > 0.1)" \
--filterName "BadValidation" \
--filterExpression "QUAL < 30.0" \
--filterName "LowQual" \
--filterExpression "QD < 5.0" \
--filterName "LowVQCBD" \
--filterExpression "FS > 60" \
--filterName "FisherStrand" \
-o genotyped_X_samples_filtered_3rd.vcf

# get only pass snps
cat genotyped_X_samples_filtered_3rd.vcf | grep 'PASS\|^#' > genotyped_X_samples_only_PASS_snp_3rd.vcf

#base recalibration loop 3rd recalibration

for sample in $REALIGNED_BAMS
do 
#taxon or sample we are working now
    echo "Processing $sample"
#create a variable with the sample name using the name of the 2nd recalibrated  bam file. We use the cut command, using the character '/' as field delimiter. In my case, this will cut the taxon path into 9 fields. The command -f8 tells to keep only the 9th field, which is the sample name     
    FILE3_BASENAME=$(echo $sample | cut -d/ -f8)
    echo $FILE3_BASENAME
    TABLE3_NAME=$(echo $FILE3_BASENAME | cut -d. -f1)'3.table'
    echo $TABLE3_NAME
    RECAL3_OUT=$(echo $FILE3_BASENAME | cut -d. -f1)'_3recal.bam'
    RECAL3_OUT_bai=$(echo $FILE3_BASENAME | cut -d. -f1)'_3recal.bai'

#execute the command in GATK for base recalibration
   
   eval $(echo "java -jar /Users/wtsai/GenomeAnalysisTK-3.4-46/GenomeAnalysisTK.jar -T BaseRecalibrator -R $REFERENCE -I $sample -knownSites genotyped_X_samples_only_PASS_snp_3rd.vcf -o $TABLE3_NAME")  
   eval $(echo "java -jar /Users/wtsai/GenomeAnalysisTK-3.4-46/GenomeAnalysisTK.jar -T PrintReads -R $REFERENCE -I $sample -BQSR $TABLE3_NAME -o $RECAL3_OUT")

	#mv $RECAL3_OUT ${RECAL3_OUT//All_dedup_realigned_3recal/3recal}
	#mv $RECAL3_OUT_bai ${RECAL3_OUT_bai//All_dedup_realigned_3recal/3recal}
done

RECAL3_BAMS=/Users/wtsai/DendHum/Dendrortyx/Dend-SNPs/map-to-ref-Dbar_47371/*_3recal.bam

# Haplotype calling on 3rd recalibrated bam

for bam3_recal in $RECAL3_BAMS
do 
# taxon or sample we are working now
    echo "Processing $bam3_recal"
# create a variable with the sample name using the name of the recalibrated bam file. We use the cut command, using the character '/' as field delimiter. In my case, this will cut the taxon path into 9 fields. The command -f8 tells to keep only the 9th field, which is the sample name     
    RECAL3_BASENAME=$(echo $bam3_recal | cut -d/ -f8)
    echo $RECAL3_BASENAME
    RECAL3_NAME=$(echo $RECAL3_BASENAME | cut -d. -f1)'.g.vcf'
    echo $RECAL3_NAME

#execute the command in GATK for haplotype call on 3rd recalibrated bams. 
   
   eval $(echo "java -Xmx4g -jar /Users/wtsai/GenomeAnalysisTK-3.4-46/GenomeAnalysisTK.jar -T HaplotypeCaller -R $REFERENCE -I $bam3_recal -o $RECAL3_NAME --emitRefConfidence GVCF --variant_index_type LINEAR --variant_index_parameter 128000 --contamination_fraction_to_filter 0.0002 --min_base_quality_score 20 --phredScaledGlobalReadMismappingRate 30 --standard_min_confidence_threshold_for_calling 40.0 --standard_min_confidence_threshold_for_emitting 40.0")
   
done

#get list of files produced from 3rd recalibration to be used in next step
ls -d -1 $PWD/*_3recal.g.vcf > recal3_vcf.list


#Genotyping with GVCF in all the variant files produced by HaplotypeCaller gvcf; merges files and contains only variable sites
java -Xmx4g -jar /Users/wtsai/GenomeAnalysisTK-3.4-46/GenomeAnalysisTK.jar  -R $REFERENCE -T GenotypeGVCFs \
--standard_min_confidence_threshold_for_calling 40.0 --standard_min_confidence_threshold_for_emitting 40.0 \
-V recal3_vcf.list \
-o genotyped_X_samples_3recal.g.vcf

# Extract the SNPs from the call set
java -jar /Users/wtsai/GenomeAnalysisTK-3.4-46/GenomeAnalysisTK.jar \
-T SelectVariants \
-R $REFERENCE  \
-V genotyped_X_samples_3recal.g.vcf \
-selectType SNP \
-o genotyped_X_samples_3recal_snps.vcf


# Extract the indels from the call set
java -jar /Users/wtsai/GenomeAnalysisTK-3.4-46/GenomeAnalysisTK.jar \
-T SelectVariants \
-R $REFERENCE  \
-V genotyped_X_samples_3recal.g.vcf \
-selectType INDEL \
-o genotyped_X_samples_3recal_indels.vcf

# filter SNP calls around indels and apply quality filters following Faircloth https://gist.github.com/brantfaircloth/4315737 and http://gatkforums.broadinstitute.org/discussion/3286/quality-score-recalibration-for-non-model-organisms   

java -jar /Users/wtsai/GenomeAnalysisTK-3.4-46/GenomeAnalysisTK.jar \
-T VariantFiltration \
-R $REFERENCE  \
-V genotyped_X_samples_3recal_snps.vcf \
--mask genotyped_X_samples_3recal_indels.vcf \
--maskExtension 5 \
--maskName InDel \
--clusterWindowSize 10 \
--filterExpression "MQ0 >= 4 && ((MQ0 / (1.0 * DP)) > 0.1)" \
--filterName "BadValidation" \
--filterExpression "QUAL < 30.0" \
--filterName "LowQual" \
--filterExpression "QD < 5.0" \
--filterName "LowVQCBD" \
--filterExpression "FS > 60" \
--filterName "FisherStrand" \
-o genotyped_X_samples_filtered_4th.vcf

# get only pass snps
cat genotyped_X_samples_filtered_4th.vcf | grep 'PASS\|^#' > genotyped_X_samples_only_PASS_snp_4th.vcf

#base recalibration loop 4th recalibration. Final recalibration

for sample in $REALIGNED_BAMS
do 
#taxon or sample we are working now
    echo "Processing $sample"
#create a variable with the sample name using the name of the original  bam file. We use the cut command, using the character '/' as field delimiter. In my case, this will cut the taxon path into 9 fields. The command -f8 tells to keep only the 9th field, which is the sample name     
    FILE4_BASENAME=$(echo $sample | cut -d/ -f8)
    echo $FILE4_BASENAME
    TABLE4_NAME=$(echo $FILE4_BASENAME | cut -d. -f1)'4.table'
    echo $TABLE4_NAME
    RECAL4_OUT=$(echo $FILE4_BASENAME | cut -d. -f1)'_4recal.bam'
    RECAL4_OUT_bai=$(echo $FILE4_BASENAME | cut -d. -f1)'_4recal.bai'

#execute the command in GATK for base recalibration
   
   eval $(echo "java -jar /Users/wtsai/GenomeAnalysisTK-3.4-46/GenomeAnalysisTK.jar -T BaseRecalibrator -R $REFERENCE -I $sample -knownSites genotyped_X_samples_only_PASS_snp_4th.vcf -o $TABLE4_NAME")  
   eval $(echo "java -jar /Users/wtsai/GenomeAnalysisTK-3.4-46/GenomeAnalysisTK.jar -T PrintReads -R $REFERENCE -I $sample -BQSR $TABLE4_NAME -o $RECAL4_OUT")

	#mv $RECAL4_OUT ${RECAL4_OUT//All_dedup_realigned_4recal/4recal}
	#mv $RECAL4_OUT_bai ${RECAL4_OUT_bai//All_dedup_realigned_4recal/4recal}
done

RECAL4_BAMS=/Users/wtsai/DendHum/Dendrortyx/Dend-SNPs/map-to-ref-Dbar_47371/*_4recal.bam

# Haplotype calling on 4th recalibrated bam

for bam4_recal in $RECAL4_BAMS
do 
# taxon or sample we are working now
    echo "Processing $bam4_recal"
# create a variable with the sample name using the name of the recalibrated bam file. We use the cut command, using the character '/' as field delimiter. In my case, this will cut the taxon path into 9 fields. The command -f8 tells to keep only the 9th field, which is the sample name     
    RECAL4_BASENAME=$(echo $bam4_recal | cut -d/ -f8)
    echo $RECAL4_BASENAME
    RECAL4_NAME=$(echo $RECAL4_BASENAME | cut -d. -f1)'.g.vcf'
    echo $RECAL4_NAME

#execute the command in GATK for haplotype call on 4th recalibrated bams. 
   
   eval $(echo "java -Xmx4g -jar /Users/wtsai/GenomeAnalysisTK-3.4-46/GenomeAnalysisTK.jar -T HaplotypeCaller -R $REFERENCE -I $bam4_recal -o $RECAL4_NAME --emitRefConfidence GVCF --variant_index_type LINEAR --variant_index_parameter 128000 --contamination_fraction_to_filter 0.0002 --min_base_quality_score 20 --phredScaledGlobalReadMismappingRate 30 --standard_min_confidence_threshold_for_calling 40.0 --standard_min_confidence_threshold_for_emitting 40.0")
   
done

#get list of files produced from 4th recalibration to be used in next step
ls -d -1 $PWD/*_4recal.g.vcf > recal4_vcf.list


#Genotyping with GVCF in all the variant files produced by HaplotypeCaller gvcf; merges files and contains only variable sites
java -Xmx4g -jar /Users/wtsai/GenomeAnalysisTK-3.4-46/GenomeAnalysisTK.jar  -R $REFERENCE -T GenotypeGVCFs \
--standard_min_confidence_threshold_for_calling 40.0 --standard_min_confidence_threshold_for_emitting 40.0 \
-V recal4_vcf.list \
-o genotyped_X_samples_4recal.g.vcf

# Extract the SNPs from the call set
java -jar /Users/wtsai/GenomeAnalysisTK-3.4-46/GenomeAnalysisTK.jar \
-T SelectVariants \
-R $REFERENCE  \
-V genotyped_X_samples_4recal.g.vcf \
-selectType SNP \
-o genotyped_X_samples_4recal_snps.vcf


# Extract the indels from the call set
java -jar /Users/wtsai/GenomeAnalysisTK-3.4-46/GenomeAnalysisTK.jar \
-T SelectVariants \
-R $REFERENCE  \
-V genotyped_X_samples_4recal.g.vcf \
-selectType INDEL \
-o genotyped_X_samples_4recal_indels.vcf

# filter SNP calls around indels and apply quality filters following Faircloth https://gist.github.com/brantfaircloth/4315737 and http://gatkforums.broadinstitute.org/discussion/3286/quality-score-recalibration-for-non-model-organisms   

java -jar /Users/wtsai/GenomeAnalysisTK-3.4-46/GenomeAnalysisTK.jar \
-T VariantFiltration \
-R $REFERENCE  \
-V genotyped_X_samples_4recal_snps.vcf \
--mask genotyped_X_samples_4recal_indels.vcf \
--maskExtension 5 \
--maskName InDel \
--clusterWindowSize 10 \
--filterExpression "MQ0 >= 4 && ((MQ0 / (1.0 * DP)) > 0.1)" \
--filterName "BadValidation" \
--filterExpression "QUAL < 30.0" \
--filterName "LowQual" \
--filterExpression "QD < 5.0" \
--filterName "LowVQCBD" \
--filterExpression "FS > 60" \
--filterName "FisherStrand" \
-o genotyped_X_samples_filtered_5th.vcf

# get only pass snps
cat genotyped_X_samples_filtered_5th.vcf | grep 'PASS\|^#' > genotyped_X_samples_only_PASS_snp_5th.vcf

#proceed to process the last 5th.vcf file for further analysis (e.g. SNAPP) or use the *4recal.bam files as input for ANGSD