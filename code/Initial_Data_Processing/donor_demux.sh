#!/bin/bash 

gatk=/mnt/bin/gatk/gatk-4.1.2.0/gatk
picard_jar=/mnt/bin/picard/picard.jar
dropseq_jar=/mnt/users/rachelsavage/software/Drop-seq_tools-2.5.4/jar/dropseq.jar
hg38=/mnt/users/rachelsavage/genomes/terra_hg38/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna
# note to self when downlaoded gatk, had to chmod 777 the file. 

#donor1bulkbam=/mnt/users/rachelsavage/tbo_4sushare/data/20230824_tbo_bulkatac/TBO_donor1/TBO_donor1_S210_001.st.bam
#donor2bulkbam=/mnt/users/rachelsavage/tbo_4sushare/data/20230824_tbo_bulkatac/TBO_donor2/TBO_donor2_S211_001.st.bam

donor1input=/mnt/AlignedData/230906_Bulk/RSav/aligned/MORF_donor1/MORF_donor1_S207_001.st.rmdup.flt.bam
donor2input=/mnt/AlignedData/230906_Bulk/RSav/aligned/MORF_donor2/MORF_donor2_S208_001.st.rmdup.flt.bam
donor3input=/mnt/AlignedData/231016_Bulk/RSav/aligned/RSav_MORF_donor3_reseq/RSav_MORF_donor3_reseq_S1_001.st.rmdup.flt.bam


# rename header, because haplotype wants a SM tag
samtools view -H $donor1input | sed "s,^@RG.*,@RG\tID:MORF_donor1\tSM:MORF_donor1_sample\tLB:None\tPL:Illumina,g" |  samtools reheader - $donor1input > donor1.fix.bam
samtools view -H $donor2input | sed "s,^@RG.*,@RG\tID:MORF_donor2\tSM:MORF_donor2_sample\tLB:None\tPL:Illumina,g" |  samtools reheader - $donor2input > donor2.fix.bam
samtools view -H $donor3input | sed "s,^@RG.*,@RG\tID:RSav_MORF_donor3_reseq\tSM:RSav_MORF_donor3_reseq_sample\tLB:None\tPL:Illumina,g" |  samtools reheader - $donor3input > donor3.fix.bam

bam_files=("donor1.fix.bam" "donor2.fix.bam" "donor3.fix.bam")
old_sample_names=("MORF_donor1_sample" "MORF_donor2_sample" "RSav_MORF_donor3_reseq_sample")
new_sample_names=("donor1" "donor2" "donor3")


for i in "${!bam_files[@]}"; do
  bam="${bam_files[i]}"
  old="${old_sample_names[i]}"
  new="${new_sample_names[i]}"

  echo "Indexing $bam"
  samtools index "$bam"

  base="${bam%.fix.bam}"
  gvcf="${base}.g.vcf.gz"
  fixed_gvcf="${base}.fix.g.vcf.gz"

  echo "Calling HaplotypeCaller for $bam to $gvcf"
  $gatk --java-options "-Xmx32g" HaplotypeCaller \
    -R "$hg38" \
    -I "$bam" \
    -O "$gvcf" \
    -ERC GVCF

  echo "Renaming sample $old to $new in $gvcf"
  java -jar "$picard_jar" RenameSampleInVcf \
    I="$gvcf" \
    O="$fixed_gvcf" \
    OLD_SAMPLE_NAME="$old" \
    NEW_SAMPLE_NAME="$new"

  echo "Indexing $fixed_gvcf"
  tabix -p vcf "$fixed_gvcf"
done

chromosomes=(chr{1..22})

for chr in "${chromosomes[@]}"; do
  echo "Running GATK GenomicsDBImport for $chr..."

  $gatk GenomicsDBImport \
    -V donor1.fix.g.vcf.gz \
    -V donor2.fix.g.vcf.gz \
    -V donor3.fix.g.vcf.gz \
    --genomicsdb-workspace-path donor_"$chr" \
    --intervals "$chr" &
done
wait

# joint genotyping
for chr in "${chromosomes[@]}"; do
  $gatk GenotypeGVCFs \
      -R "$hg38" \
      -V "gendb://donor_${chr}" \
      -O "${chr}.vcf" &
done
wait


bcftools concat chr*.vcf -O z -o final.vcf.gz
bcftools sort final.vcf.gz -O z -o final.sort.vcf.gz
tabix -p vcf final.sort.vcf.gz

mkdir cleanup
mv *.fix.bam* cleanup/
mv *.vcf.gz* cleanup/
mv donor_chr* cleanup/
mv chr*vcf* cleanup/

echo "starting barcode assignment"

barcodefile=/mnt/users/rachelsavage/paper_minimorf/data/initial_filtering/filt.barcodelist.txt
bamdir="/fab/AlignedData/rsav_minimorf/igvf_pipeline/"
bamfiles=$(find "$bamdir" -type f -name "*.bam")

assign_cells() {
    file="$1"
    filename=$(basename "$file")
    name_no_ext="${filename%.bam}"
    outputname="${name_no_ext}.donor.assign.txt"

    echo "Processing $file to  $outputname"
    
    java -Xmx64g -jar $dropseq_jar AssignCellsToSamples \
    --VCF final.sort.vcf.gz \
    --INPUT_BAM $file \
    --OUTPUT $outputname \
    --CELL_BARCODE_TAG CB \
    --CELL_BC_FILE $barcodefile \
    --FRACTION_SAMPLES_PASSING 0.0001 \
    --DNA_MODE true \
    --MOLECULAR_BARCODE_TAG UB \
    --FUNCTION_TAG XF \
    --GQ_THRESHOLD -1 \
    --READ_MQ 10 \
    --RETAIN_MONOMORPIC_SNPS false \
    --IGNORED_CHROMOSOMES X \
    --IGNORED_CHROMOSOMES Y \
    --IGNORED_CHROMOSOMES MT \
    --ADD_MISSING_VALUES true \
    --SNP_LOG_RATE 1000 \
    --GENE_NAME_TAG gn \
    --GENE_STRAND_TAG gs \
    --GENE_FUNCTION_TAG gf \
    --STRAND_STRATEGY SENSE \
    --LOCUS_FUNCTION_LIST CODING \
    --LOCUS_FUNCTION_LIST UTR \
    --LOCUS_FUNCTION_LIST INTERGENIC \
    --LOCUS_FUNCTION_LIST INTRONIC \
    --VALIDATION_STRINGENCY STRICT \
    --COMPRESSION_LEVEL 5 \
    --MAX_RECORDS_IN_RAM 500000



}

export -f assign_cells
export dropseq_jar
export barcodefile

find "$bamdir" -type f -name "*.bam" | parallel -j 2 assign_cells

mv cleanup/final.sort.vcf.gz* .
mkdir -p final_donor_calls
mv SS* final_donor_calls
mv final.sort.vcf.gz donor.genotype.sort.vcf.gz
mv final.sort.vcf.gz.tbi donor.genotype.sort.vcf.gz.tbi

echo "totally done"
