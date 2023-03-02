ml BEDTools/2.30.0-GCC-11.2.0
cp /fh/fast/haffner_m/user/madil/scripts/MultiBed_Matrix_summary_generator.py ./
bed_path="/fh/scratch/delete90/haffner_m/TFBS_beds/GTRD/hg19/beds_top10k/hg19LO_beds/"
mkdir Summary_files
for i in ${bed_path}*.bed;
do
    bed_name=${i#"$bed_path"}
    bed_name=${bed_name%.bed}
    sortBed -i $i > ${bed_name}.sorted.bed
done
##generate slurm files
bw_path="/fh/scratch/delete90/haffner_m/user/madil/Methylation_profiles/LuCaP/bw_files/"
for j in ${bw_path}*bw;
do
    bw_name=${j#"$bw_path"}
    bw_name=${bw_name%.bw}
    touch ${bw_name}.slurm;
    echo '#!/bin/bash' >> ${bw_name}.slurm;
    echo '#SBATCH -c 2' >> ${bw_name}.slurm;
    echo '#SBATCH -t 0-30:00' >> ${bw_name}.slurm;
    echo '#SBATCH -o slurm.%j.out' >> ${bw_name}.slurm;
    echo '#SBATCH -e slurm.%j.err' >> ${bw_name}.slurm;
    echo '#SBATCH --mail-type=ALL' >> ${bw_name}.slurm;
    echo '#SBATCH -A haffner_m' >> ${bw_name}.slurm;
    echo "ml deepTools/3.5.1-foss-2021b" >> ${bw_name}.slurm;
    echo "ml Python/3.9.6-GCCcore-11.2.0" >> ${bw_name}.slurm;
    #echo "${bw_name}"
    echo "${bw_name}"
    echo "computeMatrix reference-point -R *.sorted.bed -S $j -o ${bw_name}.mtx.gz -b 1005 -a 1005 -bs 15 --referencePoint center -p=20 --outFileNameMatrix ${bw_name}.values.tab --outFileSortedRegions  ${bw_name}.used.bed" >> ${bw_name}.slurm;  
    echo "python MultiBed_Matrix_summary_generator.py --values_file ${bw_name}.values.tab --out ./Summary_files/" >> ${bw_name}.slurm;  
done

out_put_matrix_name="EPIC_LUCAP_GTRD_top10k_hg19"
cat *.summary.txt > ${out_put_matrix_name}.values.summary.txt