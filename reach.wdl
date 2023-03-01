version 1.1

####### workflow 
workflow reach {
  input {
    Array[File] samples
    Array[File] bedFiles
  }

    # REsidual handy array of chromosomes in case you want to scatter over them in the future to parallelize
    Array[String] chromosomes = ["chr1", "chr2", "chr3", "chr4", "chr5", "chr6", "chr7", "chr8","chr9", 
                                "chr10", "chr11", "chr12", "chr13", "chr14", "chr15","chr16", "chr17", 
                                "chr18", "chr19", "chr20", "chr21", "chrX", "chrY"]
    
    # Software modules/docker containers this workflow has been tested with
    String bedtoolsModule = "BEDTools/2.30.0-GCC-11.2.0"
    String deepToolsModule = "deepTools/3.5.1-foss-2021b"
    String pythonModule = "Python/3.9.6-GCCcore-11.2.0"
  
  ## START WORKFLOW
  scatter (bedtosort in bedFiles) {
    call sortBed {
      input: 
        bedIn = bedtosort,
        taskModule = bedtoolsModule
    }
  }

scatter (each_sample in samples) {
      bed = Array[File] sortBed.out
      # Prep some filenames
      String bwstem = basename(each_sample, ".bw")

  #  to extract data from bw at bed sites
        call computeMatrix {
            input:
            bedIn = bed,
            bigwig = each_sample,
            fileName = bwstem,
            taskModule = deepToolsModule,
            threads = 4
        }
        # Summarize the extracted data
        #call summarize {
        #    input:
        #    values_file = computeMatrix.values_file,
        #    fileName = bwstem,
        #    taskModule = pythonModule
        #}
    } # end scatter

# Outputs that will be retained when execution is complete
output {
  #Array[File] summary_results = summarize.summary_file
  Array[File] mtx_results = computeMatrix.mtx_file
  Array[File] values_results = computeMatrix.values_file
  }
}# End workflow


## Task defintions, usually in alphabetical order

# Task 2 copute matrix for given bed and bw
task computeMatrix {
  input {
    Array[File] bedIn
    File bigwig
    String taskModule
    String fileName
    Int threads
  }

  command {
      set -eo pipefail 

      computeMatrix reference-point -R ~{bedIn} -S ~{bigwig} \
        -o ~{fileName}.mtx.gz -b 1005 -a 1005 -bs 15 \
        --referencePoint center -p=~{threads} \
        --outFileNameMatrix ~{fileName}.values.tab \
        --outFileSortedRegions  ~{fileName}.used.bed
  }
  runtime {
    modules: taskModule
    cpu: threads
    memory: 2 * threads + "GB" # this will ask for 2GB for each cpu you request
  }
  output {
    File mtx_file = "~{fileName}.used.bed"
    File values_file = "~{fileName}.values.tab"
  }
}

# Task 1 Sort bed file for copute matrix
task sortBed {
  input {
    Array[File] bedsToGroup
    String taskModule
  }

  String bedName = basename(bedIn, ".bed")
  command {
      set -eo pipefail 
      sortBed -i ~{bedIn} > ~{bedName}.sorted.bed
  }
  runtime {
    modules: taskModule
    cpu: 1
    memory: "2GB"
  }
  output {
    File out = "~{bedName}.sorted.bed"
  }
}


# Task 3 Summarize
task summarize {
  input {
    File values_file
    String fileName
    String taskModule
  }

  command {
  set -eo pipefail

  git clone --branch "main" git@github.com:madil7173/Reach_WDL.git

  python Reach_WDL/Matrix_summary_generator.py --input ~{values_file} \
     --out ~{fileName}.summary.txt 
  }
  output {
    File summary_file = "~{fileName}.summary.txt"
  }
  runtime {
    modules: taskModule
    cpu: 1
    memory: "2GB"
  }
}