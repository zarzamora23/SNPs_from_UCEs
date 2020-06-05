#Indexing reference library for outgroup Aphelocoma californica nevadae in current directory or copy previously indexed files *.amb,*.ann,*.bwt,*.pac,*.sa.

#Consider adding a line to remove *.sam files and *. sorted.bam to release disk space

bwa index -p Dbar_47371_PUE -a is /Users/wtsai/DendHum/Dendrortyx/Dend-SNPs/map-to-ref-Dbar_47371/Dbar_47371_PUE.fasta


READS_FOLDER=/Users/wtsai/DendHum/Dendrortyx/illumi_test/UCEtrimmed_crop220/*

#run for loop for all samples. 

for folder in $READS_FOLDER
	do 
	echo $folder
#create sample name based on folder's name. Get path to folder and only keep last field (6th in my case)
	SAMPLE_NAME=$(echo $folder | cut -d/ -f8)
	echo $SAMPLE_NAME
	
#map reads with algorithm mem for illumina reads 70bp-1Mb; 
eval $(echo "bwa mem -B 10 -M -R '@RG\tID:$SAMPLE_NAME\tSM:$SAMPLE_NAME\tPL:Illumina' Dbar_47371_PUE $folder/split-adapter-quality-trimmed/$SAMPLE_NAME-READ1.fastq.gz $folder/split-adapter-quality-trimmed/$SAMPLE_NAME-READ2.fastq.gz > $SAMPLE_NAME.pair.sam") 
eval $(echo "bwa mem -B 10 -M -R '@RG\tID:$SAMPLE_NAME\tSM:$SAMPLE_NAME\tPL:Illumina' Dbar_47371_PUE $folder/split-adapter-quality-trimmed/$SAMPLE_NAME-READ-singleton.fastq.gz > $SAMPLE_NAME.single.sam") 

#sort reads
eval $(echo "samtools view -bS $SAMPLE_NAME.pair.sam| samtools sort -m 30000000000 - $SAMPLE_NAME.pair_sorted")
eval $(echo "samtools view -bS $SAMPLE_NAME.single.sam | samtools sort -m 30000000000 - $SAMPLE_NAME.single_sorted")

#mark duplicates
eval $(echo "java -Xmx4g -jar /Users/wtsai/anaconda/jar/MarkDuplicates.jar INPUT=$SAMPLE_NAME.pair_sorted.bam INPUT=$SAMPLE_NAME.single_sorted.bam OUTPUT=$SAMPLE_NAME.All_dedup.bam METRICS_FILE=$SAMPLE_NAME.All_dedup_metricsfile MAX_FILE_HANDLES_FOR_READ_ENDS_MAP=250 ASSUME_SORTED=true VALIDATION_STRINGENCY=SILENT REMOVE_DUPLICATES=True")

#index bam file
eval $(echo "java -Xmx4g -jar /Users/wtsai/anaconda/jar/BuildBamIndex.jar INPUT=$SAMPLE_NAME.All_dedup.bam")

eval $(echo "samtools flagstat $SAMPLE_NAME.All_dedup.bam > $SAMPLE_NAME.All_dedup_stats.txt")

done

#rm *.sam
#rm  *sorted.bam