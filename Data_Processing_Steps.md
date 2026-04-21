
# General Data Structure
There are 37 sublibraries. Each sublibrary contains unique cells. Each sublibrary has associated ATAC, RNA, and TF-barcode data. (Due to a wet lab error, I lost one ATAC sublibrary, so there are 36 ATAC sublibraries.) 

The sublibraries were pooled and sequenced over multiple NovaX runs and lanes. Therefore, there will be multiple fastqs associated with each sublibrary, corresponding to the NovaX run and lane that the particular cells were sequenced on.

# Initial Data processing 
### Workflow Steps:  
1. Filter cells based on ATAC
	- [code/Initial_Data_Processing/Filter_Cells.ipynb](code/Initial_Data_Processing/Filter_Cells.ipynb)
 		- Here we do a preliminary filter of cells. We load in the metadata of the atac librarys from the files ending in `*barcode.summary.csv`. We construct knee plots based on total mapped reads per cell, to filter out low quality cells. We use a generic T cell peak set to calculate (you can also easily use here encode cCRE peaks) the fraction of reads falling in peaks (FRIP). Debris, and dying cells get tagmented everywhere in their genome, so have low FRIP. We then filter cells based on FRIP and unique reads. 
2. Create RNA matrices using filtered cells
	- [code/Initial_Data_Processing/Filter_Cells_RNA.ipynb](code/Initial_Data_Processing/Filter_Cells_RNA.ipynb)
 		- Using the barcodes that passed the final ATAC filtering, we create counts matrices for RNA using only these cell barcodes.  
3. Call the donor based on genotype demulitplexing
	- [code/Initial_Data_Processing/donor_demux.sh](code/Initial_Data_Processing/donor_demux.sh)
 		- This is a shell script that calls genotype of the 3 donors, given 3 bam files that we generated using bulk-ATAC of the donors. Then, we input the bam files from the SHARE-seq, and demultiplex each single cell by its donor using Dropseq tools. 
	- [code/Initial_Data_Processing/Donor_calling_and_doublet.ipynb](code/Initial_Data_Processing/Donor_calling_and_doublet.ipynb)
 		- After calling the donors, this just makes the data structure more manageable, and sets padj cutoffs for final donor calls.  
4. Call the TFs
	- [code/Initial_Data_Processing/Create_Custom_TF_Genome.ipynb](code/Initial_Data_Processing/Create_Custom_TF_Genome.ipynb)
 		- To get started, we download the MORF library barcodes. This is located in the [addgene website](https://www.addgene.org/pooled-library/human-morf-library/) in a [XLSX file](https://media.addgene.org/cms/filer_public/5e/22/5e22c6a5-d186-4c54-95c0-8314db54bfbe/200102_tf_orf_library.xlsx).
	   - This code takes as input the morf library info, then filters by TFs that were used in the experiment and turns it into a fasta file and GTF.
	- [create_custom_genome.sh](create_custom_genome.sh)
 		- Creates a custom genome using starsolo, with inputs of the gtf and fasta generated above. 
 	- Align TF fastqs using starsolo
  		- We have a R1 and R2 fastq from each sublibrary of the TF barcodes. These fastq files have the UMI and cell barcode already appended to them (these were sequenced from the I1 and I2). This website is a great reference for understanding the structure of the share-seq final file. (https://teichlab.github.io/scg_lib_structs/methods_html/SHARE-seq.html)
		- We use as input the R1 and R2 fastq, and use starsolo to align them to the custom genome we created. 
 	- [code/Initial_Data_Processing/TF_calling.ipynb](code/Initial_Data_Processing/TF_calling.ipynb)
  		- This script actually doesn't generate anyhting, it's just a visualization of the rational for all the filtering steps within  (code/Initial_Data_Processing/TF_calling_all.ipynb). 
	- [code/Initial_Data_Processing/TF_calling_all.ipynb](code/Initial_Data_Processing/TF_calling_all.ipynb)
		- Wow. such an important step. 
5. Combine metadata
	- [code/Initial_Data_Processing/metadata.extraction.ipynb](code/Initial_Data_Processing/metadata.extraction.ipynb)
6. Call peaks
	- [code/Initial_Data_Processing/callpeaks.ipynb](code/Initial_Data_Processing/callpeaks.ipynb)
	- [code/Initial_Data_Processing/filterpeaks.ipynb](code/Initial_Data_Processing/filterpeaks.ipynb)
7. Create cells x peak matrix for atac with new peakset
	- [code/Initial_Data_Processing/makeatacmatrix.ipynb](code/Initial_Data_Processing/makeatacmatrix.ipynb)
 	- Here i'm also removing doublets, that I called based on genotyping from: [code/Initial_Data_Processing/Donor_calling_and_doublet.ipynb](code/Initial_Data_Processing/Donor_calling_and_doublet.ipynb)
8. Create cells x genes matrix for RNA
	- [code/Initial_Data_Processing/makernamatrix.ipynb](code/Initial_Data_Processing/makernamatrix.ipynb)
10. Compile everything for single cell metadata
    - [code/Initial_Data_Processing/metadata.extraction.ipynb](code/Initial_Data_Processing/metadata.extraction.ipynb)




