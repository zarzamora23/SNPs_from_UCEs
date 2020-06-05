#The GATK uses two files to access and safety check access to the reference files: 
# .dict dictionary of the contig names and sizes 
# .fai fasta index file to allow efficient random access to the reference bases. 
#prepare fasta file to use as reference with picard and samtools. 
java -jar /Users/wtsai/anaconda/pkgs/picard-1.106-0/jar/CreateSequenceDictionary.jar R=/Users/wtsai/DendHum/Dendrortyx/Dend-SNPs/map-to-ref-Dbar_47371/Dbar_47371_PUE.fasta  O=Dbar_47371_PUE.dict 
samtools faidx /Users/wtsai/DendHum/Dendrortyx/Dend-SNPs/map-to-ref-Dbar_47371/Dbar_47371_PUE.fasta

#realigning the mapping produced with BWA with a gap penalty B=10. The minimum number of reads per locus was set to 10
REFERENCE=/Users/wtsai/DendHum/Dendrortyx/Dend-SNPs/map-to-ref-Dbar_47371/Dbar_47371_PUE.fasta
DEDUP_BAMS=/Users/wtsai/DendHum/Dendrortyx/Dend-SNPs/map-to-ref-Dbar_47371/*All_dedup.bam


for sample in $DEDUP_BAMS
do 
#taxon or sample we are working now
    echo "Processing $sample"
#create a variable with the sample name using the name of the dedup bam file. We use the cut command, using the character '/' as field delimiter. In my case, this will cut the taxon path into 9 fields. The command -f9 tells to keep only the 9th field, which is the sample name     
    DEDUPBAMNAME=$(echo $sample | cut -d/ -f8)
    DEDUPBASENAME=$(echo $DEDUPBAMNAME | cut -d. -f1)
#create the name of intervals file    
    INTERVALS_NAME=$DEDUPBASENAME'.intervals'
    echo $INTERVALS_NAME
#create output realigned bams
	REALIGNED_NAME=$DEDUPBASENAME'_realigned.bam'
	echo $REALIGNED_NAME
#execute the command in GATK to create intervals and realign reads
   
   eval $(echo "java -Xmx4g -jar /Users/wtsai/GenomeAnalysisTK-3.4-46/GenomeAnalysisTK.jar -T RealignerTargetCreator -R $REFERENCE -o $INTERVALS_NAME -I $sample --minReadsAtLocus 10")
   eval $(echo "java -Xmx4g -jar /Users/wtsai/GenomeAnalysisTK-3.4-46/GenomeAnalysisTK.jar -T IndelRealigner -R $REFERENCE -I $sample -targetIntervals $INTERVALS_NAME  -o $REALIGNED_NAME -LOD 3.0")
    
done
