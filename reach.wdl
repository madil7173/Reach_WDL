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
    # Run deeptools compute matrix to extract data from bw at bed sites
        call computeMatrix {
            input:
            bedIn = bed,
            bigwig = bw,
            taskModule = deepToolsModule,
            threads = 4
        }
        # Summarize the extracted data
        call summarize {
            input:
            computeMatrix_file = values_file,
            taskModule = pythonModule
        }
    }
}


# Outputs that will be retained when execution is complete
output {
  File values_file = barcodeConsensus.barcodeList
  File summary_file = cellRangerCount.bam
  File Concat_summary = cellRangerCount.bai

  }
}# End workflow

#### TASK 1 ComputeMatrix
task computeMatrix {
  input {
    File bedIn
    File bigwig
    String taskModule
    Int threads
  }
  String bwstem = basename(bigwig, ".bw")
  String bedstem = basename(bedIn, ".bed")
  String fileName = bwstem + "_with_" + bedstem

  command {
      set -eo pipefail #what does this line do?
      computeMatrix reference-point -R ~{bedIn} -S ~{bigwig} \
        -o ~{fileName}.mtx.gz -b 1005 -a 1005 -bs 15 \
        --referencePoint center -p=~{threads} \
        --outFileNameMatrix ~{fileName}.values.tab \
        --outFileSortedRegions  ~{fileName}.used.bed
  }
  runtime {
    modules: taskModule
    cpu: threads
  }
  output {
    File mtx_file = "~{fileName}.used.bed"
    File values_file = "~{fileName}.values.tab"
  }
}


# Task 2 Summarize
task summarize {
  input {
    File values_file
    String taskModule
  }
  String fileName = bwstem + "_with_" + bedstem
  command {
  set -eo pipefail
  git clone git@github.com:madil7173/Reach_WDL.git ##is this correct?
  python Matrix_summary_generator.py --input ${file_name}.values.tab \
     --out ${file_name}.summary.txt 


  }
  output {
    File summary_file = "{file_name}.summary.txt"
  }
  runtime {
    modules: taskModule
    cpu: 1
    memory: "2GB"
  }
}