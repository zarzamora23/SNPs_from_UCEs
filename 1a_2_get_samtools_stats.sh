 #!/bin/bash
STATS=/Users/zarzafranco/Desktop/RapidGenomics/P7_mapping/*stats.txt

#create file with header

echo "LIBRARY	Total_QC_passed_reads	duplicates	MAPPED	PAIRED	read1	read2	properly_paired	with_itself_mate_paired	singletons	mate_mapped_different_chr	mate_mapped_different_chrQ5" > samtools_stats.txt

for document in $STATS
	do 
	echo $document
#create file name based on document's name. Get path to folder and only keep last field
	FILE_NAME=$(echo $document | cut -d/ -f7)
	echo $FILE_NAME
#create sample name based on files's name.
	SAMPLE_NAME=$(echo $FILE_NAME | cut -d. -f1)
	echo $SAMPLE_NAME

#print line with summary stats

S1=$(sed -n '1p' $document)
S2=$(sed -n '2p' $document)
S3=$(sed -n '3p' $document)
S4=$(sed -n '4p' $document)
S5=$(sed -n '5p' $document)
S6=$(sed -n '6p' $document)
S7=$(sed -n '7p' $document)
S8=$(sed -n '8p' $document)
S9=$(sed -n '9p' $document)
S10=$(sed -n '10p' $document)
S11=$(sed -n '11p' $document)


echo "$SAMPLE_NAME	$S1	$S2	$S3	$S4	$S5	$S6	$S7	$S8	$S9	$S10	$S11" >>samtools_stats.txt

done
