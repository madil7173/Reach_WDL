version 1.0

####### workflow 
workflow reach {
  input {
    Array[File] samples
    Array[File] bedFiles
  }

    Array[String] chromosomes = ["chr1", "chr2", "chr3", "chr4", "chr5", "chr6", "chr7", "chr8","chr9", 
                                "chr10", "chr11", "chr12", "chr13", "chr14", "chr15","chr16", "chr17", 
                                "chr18", "chr19", "chr20", "chr21", "chrX", "chrY"]
    
    # Software modules/docker containers this workflow has been tested with
    String deepToolsModule = "deepTools/3.5.1-foss-2021b"
    String pythonModule = "Python/3.9.6-GCCcore-11.2.0"


  ## START WORKFLOW
scatter ( bw in samples ) {

    scatter ( bed in bedFiles ) {
    # identify list of cell barcodes with valid enriched library sequencing results
        call computeMatrix {
            input:
            bedIn = bed,
            bigwig = bw,
            taskModule = deepToolsModule,
            threads = 4
        }
        # run cell ranger count on the GEX library 
        call summarize {
            input:
            R1FastqsGEX = R1FastqsGEX,
            taskModule = pythonModule
        }
    }
}


# Outputs that will be retained when execution is complete
output {
  File barcodes = barcodeConsensus.barcodeList
  File cellrangerbam = cellRangerCount.bam
  File cellrangerBai = cellRangerCount.bai
  File cellrangerBarcodes = cellRangerCount.barcodes

  }
}# End workflow

#### TASK DEFINITIONS
task computeMatrix {
  input {
    File bedIn
    File bigwig
    String taskModule
    Int threads
  }
  String stem = basename(bigwig, ".bw")
  String bedstem = basename(bedIn, ".bed")
  String fileName = stem + "_with_" + bedstem

  command {
      set -eo pipefail
      computeMatrix reference-point -R ~{bedIn} -S ~{bigwig} \
        -o ~{fileName}.mtx.gz -b 1005 -a 1005 -bs 15 \
        --referencePoint center -p=~{threads} \
        --outFileNameMatrix ~{fileName}.values.tab \
        --outFileSortedRegions  ~{fileName}.used.bed"
  }
  runtime {
    modules: taskModule
    cpu: threads
  }
  output {
    File something = "~{fileName}.used.bed"
    File somethingelse = "~{fileName}.values.tab"
  }
}


# annotate with annovar
task summarize {
  input {
    File input_vcf
    String taskModule
  }
  String base_vcf_name = basename(input_vcf, ".vcf.gz")
  command {
  set -eo pipefail

  git clone <repo>
  python Matrix_summary_generator.py --input ${file_name}.values.tab \
     --out ${file_name}.summary.txt" >> ${bed_name}.slurm


  }
  output {
    File annotatedVcf = "${base_vcf_name}.${ref_name}_multianno.vcf"
    File annotatedTable = "${base_vcf_name}.${ref_name}_multianno.txt"
  }
  runtime {
    modules: taskModule
    cpu: 1
    memory: "2GB"
  }
}