#Indexing reference library for outgroup Aphelocoma californica nevadae in current directory or copy previously indexed files *.amb,*.ann,*.bwt,*.pac,*.sa.

#Consider adding a line to remove *.sam files and *. sorted.bam to release disk space

bwa index -p nevadae -a is /Users/zarzafranco/Desktop/Aphelocoma2/Outgroups/nevadae_fasta/nevadae_UCEs.fasta 


READS_FOLDER=/Users/zarzafranco/Desktop/RapidGenomics/P7_trimmed/*

#run for loop for all samples. 

for folder in $READS_FOLDER
	do 
	echo $folder
#create sample name based on folder's name. Get path to folder and only keep last field (7th in my case)
	SAMPLE_NAME=$(echo $folder | cut -d/ -f7)
	echo $SAMPLE_NAME
	
#map reads with algorithm mem for illumina reads 70bp-1Mb; 
eval $(echo "bwa mem -B 10 -M -R '@RG\tID:$SAMPLE_NAME\tSM:$SAMPLE_NAME\tPL:Illumina' nevadae $folder/split-adapter-quality-trimmed/$SAMPLE_NAME-READ1.fastq.gz $folder/split-adapter-quality-trimmed/$SAMPLE_NAME-READ2.fastq.gz > $SAMPLE_NAME.nev_pair.sam") 
eval $(echo "bwa mem -B 10 -M -R '@RG\tID:$SAMPLE_NAME\tSM:$SAMPLE_NAME\tPL:Illumina' nevadae $folder/split-adapter-quality-trimmed/$SAMPLE_NAME-READ-singleton.fastq.gz > $SAMPLE_NAME.nev_single.sam") 

#sort reads
eval $(echo "samtools view -bS $SAMPLE_NAME.nev_pair.sam| samtools sort -m 30000000000 - $SAMPLE_NAME.nev_pair_sorted")
eval $(echo "samtools view -bS $SAMPLE_NAME.nev_single.sam | samtools sort -m 30000000000 - $SAMPLE_NAME.nev_single_sorted")

#mark duplicates
eval $(echo "java -Xmx2g -jar /Users/zarzafranco/miniconda/jar/MarkDuplicates.jar INPUT=$SAMPLE_NAME.nev_pair_sorted.bam INPUT=$SAMPLE_NAME.nev_single_sorted.bam OUTPUT=$SAMPLE_NAME.nev_All_dedup.bam METRICS_FILE=$SAMPLE_NAME.nev_All_dedup_metricsfile MAX_FILE_HANDLES_FOR_READ_ENDS_MAP=250 ASSUME_SORTED=true VALIDATION_STRINGENCY=SILENT REMOVE_DUPLICATES=True")

#index bam file
eval $(echo "java -Xmx2g -jar /Users/zarzafranco/miniconda/jar/BuildBamIndex.jar INPUT=$SAMPLE_NAME.nev_All_dedup.bam")

eval $(echo "samtools flagstat $SAMPLE_NAME.nev_All_dedup.bam > $SAMPLE_NAME.nev_All_dedup_stats.txt")


#get stats only for paired files before removing duplicates
#eval $(echo "samtools flagstat $SAMPLE_NAME.nev_pair_sorted.bam > $SAMPLE_NAME.nev_pair_stats.txt")

#get depth with samtool. Denominator should be the length of the genome used as reference, in this case navadae sequences add up 2890195; calculated with: samtools view -H *bamfile* | grep -P '^@SQ' | cut -f 3 -d ':' | awk '{sum+=$1} END {print sum}'

samtools depth $SAMPLE_NAME.nev_All_dedup.bam  |  awk '{sum+=$3; sumsq+=$3*$3} END { print  "Average = ",sum/2890195; print "Stdev = ",sqrt(sumsq/2890195 - (sum/2890195)**2)}' >> depth_stats.txt

done

#rm *.sam
#rm  *sorted.bam