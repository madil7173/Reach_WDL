ml BEDTools/2.30.0-GCC-11.2.0
cp /fh/fast/haffner_m/user/madil/scripts/Matrix_summary_generator.py ./
bed_path="/fh/scratch/delete90/haffner_m/TFBS_beds/GTRD/hg19/beds_top10k/hg19LO_beds/"

for i in ${bed_path}*.bed;
do
    bed_name=${i#"$bed_path"}
    bed_name=${bed_name%.bed}
    sortBed -i $i > ${bed_name}.sorted.bed
done
##generate slurm files
bw_path="/fh/scratch/delete90/haffner_m/user/madil/WGBS_Atlas_GSE186458/bw/"
for i in *.bed;
do
    bed_name=${i%.sorted.bed}
    #echo "${bed_name}"
    touch ${bed_name}.slurm;
    echo '#!/bin/bash' >> ${bed_name}.slurm;
    echo '#SBATCH -c 4' >> ${bed_name}.slurm;
    echo '#SBATCH -t 0-10:00' >> ${bed_name}.slurm;
    echo '#SBATCH -o slurm.%j.out' >> ${bed_name}.slurm;
    echo '#SBATCH -e slurm.%j.err' >> ${bed_name}.slurm;
    echo '#SBATCH --mail-type=ALL' >> ${bed_name}.slurm;
    echo '#SBATCH -A haffner_m' >> ${bed_name}.slurm;
    echo '#SBATCH -p restart-new' >> ${bed_name}.slurm;
    echo '#SBATCH -q restart-new' >> ${bed_name}.slurm;
    echo "ml deepTools/3.5.1-foss-2021b" >> ${bed_name}.slurm;
    echo "ml Python/3.9.6-GCCcore-11.2.0" >> ${bed_name}.slurm;
    for j in ${bw_path}*bigwig; 
    do
        bw_name=${j#"$bw_path"}
        bw_name=${bw_name%.bigwig}
        spacer="_with_"
        file_name="$bed_name$spacer$bw_name"
        #echo "${bw_name}"
        echo "${file_name}"
        echo "computeMatrix reference-point -R $i -S $j -o ${file_name}.mtx.gz -b 1005 -a 1005 -bs 15 --referencePoint center -p=4 --outFileNameMatrix ${file_name}.values.tab --outFileSortedRegions  ${file_name}.used.bed" >> ${bed_name}.slurm;  
        echo "python Matrix_summary_generator.py --input ${file_name}.values.tab --out ${file_name}.summary.txt" >> ${bed_name}.slurm;
    done
    #echo "wait" >> ${bed_name}.slurm;
    #echo "cat *.summary.txt > ${out_put_matrix_name}.values.summary.txt" >> ${bed_name}.slurm;
done

out_put_matrix_name="WGBS_Atlas_GTRD_top10"
cat *.summary.txt > ${out_put_matrix_name}.values.summary.txt