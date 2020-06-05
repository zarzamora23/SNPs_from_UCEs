 #!/bin/bash
METRICS=/Users/zarzafranco/Desktop/RapidGenomics/P7_mapping/*dedup_metricsfile

#create file with header

echo "LIBRARY	UNPAIRED_READS_EXAMINED	READ_PAIRS_EXAMINED	UNMAPPED_READS	UNPAIRED_READ_DUPLICATES	READ_PAIR_DUPLICATES	READ_PAIR_OPTICAL_DUPLICATES	PERCENT_DUPLICATION	ESTIMATED_LIBRARY_SIZE" > metrics_stats.txt

for document in $METRICS
	do 
	echo $document
#create file name based on document's name. Get path to folder and only keep last field
	FILE_NAME=$(echo $document | cut -d/ -f7)
	echo $FILE_NAME
#create sample name based on files's name.
	SAMPLE_NAME=$(echo $FILE_NAME | cut -d. -f1)
	echo $SAMPLE_NAME

#print line with summary stats

SUMMARY=$(sed -n '8p' $document)

echo "$SAMPLE_NAME$SUMMARY" >>metrics_stats.txt

done
