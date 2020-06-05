#This script will transform a simple nexus file into an xml file to run SNAPP, generated with pyhluce script phyluce_snp_convert_vcf_to_snapp. 
#This is useful if you want to create taxon sets with only one taxon and default snapp options. Otherwise the nexus file is the input for beauti
#You will need to modify the location of the working directory (7th line), the number of lines with data (see line 12-15 and modify 18) and the name you want to give to the data matrix (47th line). 
#The script will concatenate xml blocks with different kind of information, make sure you have them all. The script assumes you are working in the 'working_folder' and that this one contains xml blocks

#indicate the working directory
working_folder=/path/to/folder_where_you_want_to_work/

#create a variable to refer to the new snps_file
only_snps_file=$working_folder/your_only_snps_file_without_nexus_header.txt 

#use sed to extract only lines with taxa labels and sequences and to remove the nexus header and last '; end ;'
#in the generalized sed command below, M is the first line with data and N is the last line with data (if phyluce was to used to generate the nexus file, then N = number of taxa +5)
#sed -n ‘M,N’p your_nexus_file > $only_snps_file
#see example below for a matrix with 15 taxa

#example: print only lines that contain taxa labels and data from nexus file, adjust numbers in between ' ' to include all taxa lines as explained above
sed -n '6,20'p $working_folder/your_input_nexus_file.nex > $only_snps_file

#generate data set and taxon set block with a while loop

#read each line (i.e. each individual) of the only_snps_file 
while read line
	do 
	#get taxon/individual name
	individual=$(echo "$line" | cut -d' ' -f1)
	echo $individual
	#get snps for individual. Use cut command but reverse string and select first field (this was the last field before reversing), reverse the string back
	snps=$(echo "$line" | rev | cut -d' ' -f1 | rev) 
    
    #add SNAPP identifiers. This will create the data block. Make sure output file does not exist before running loop. This command will not overwrite previously created files, resulting in errors.
    echo '<sequence id="seq_'$individual'" taxon="'$individual'" totalcount="3" value="'$snps'"/>' >> $working_folder/data_block.txt


	#generate taxon set block. #Append output of all lines to a taxon_set_block. Make sure output file does not exist before running loop. This command will not overwrite previously created files, resulting in errors.

	echo '<taxonset id="set_'$individual'" spec="TaxonSet"> <taxon id="'$individual'" spec="Taxon"/> </taxonset>' >> $working_folder/taxon_set_block.txt

#close loop
done < $snps_file

#concatenate blocks . These are blocks forming the xml file, you will need to modify length of mcmc, sampling intervals, etc
cat $working_folder/header.txt $working_folder/data_block.txt $working_folder/parameters_block.txt $working_folder/taxon_set_block.txt $working_folder/mcmc_end_block.txt > $working_folder/pre_snap_file.txt

#and replace MATRIX_NAME for user matrix name, we chose to call it Dendro_snps

sed 's/MATRIX_NAME/mytaxon_snps/g' $working_folder/pre_snap_file.txt >  $working_folder/mytaxon_snps_for_SNAPP.xml
