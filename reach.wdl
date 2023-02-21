version 1.0

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

  scatter (bedtosort in bedFiles) {
    call sortBed {
      input: 
        bedIn = bedtosort,
        taskModule = bedtoolsModule
    }
  }

  # This is a slightly "fancy" way to create all the combinations of two arrays and lets you parallellize over 
  # a larger number of combinations with less complex workflow language.  This uses the array of sorted bed files as an input. 
  Array[Pair[File, File]] all_combinations = cross( samples, sortBed.out )

  ## START WORKFLOW
scatter ( combo in all_combinations ) {

      # Since the combinations of all your bw's and bed's is an array of 'pairs' of files, since "samples"
      # came first in the cross above, it is the "left" entry in each pair, while the sorted bedfiles was second
      # so it's the "right" entry in each pair. You don't have to reassign them to variables like I'm doing
      # here but I thought it's slightly easier to read this way.  
      File bw = combo.left
      File bed = combo.right

      # Prep some filenames
      String bwstem = basename(bw, ".bw")
      String bedstem = basename(bed, ".bed")

  #  to extract data from bw at bed sites
        call computeMatrix {
            input:
            bedIn = bed,
            bigwig = bw,
            fileName = bwstem + "_with_" + bedstem,
            taskModule = deepToolsModule,
            threads = 4
        }
        # Summarize the extracted data
        call summarize {
            input:
            values_file = computeMatrix.values_file,
            fileName = bwstem + "_with_" + bedstem,
            taskModule = pythonModule
        }
    } # end scatter

# Outputs that will be retained when execution is complete
output {
  Array[Array[File]] summary_results = summarize.summary_file
  Array[Array[File]] mtx_results = computeMatrix.mtx_file
  Array[Array[File]] values_results = computeMatrix.values_file
  }
}# End workflow


## Task defintions, usually in alphabetical order

#### ComputeMatrix
task computeMatrix {
  input {
    File bedIn
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

task sortBed {
  input {
    File bedIn
    String taskModule
  }

  String bedName = basename(bedIn, "bed")
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


# Task 2 Summarize
task summarize {
  input {
    File values_file
    String fileName
    String taskModule
  }

  command {
  set -eo pipefail

  git clone --branch "main" git@github.com:madil7173/Reach_WDL.git

  python Matrix_summary_generator.py --input ~{fileName}.values.tab \
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