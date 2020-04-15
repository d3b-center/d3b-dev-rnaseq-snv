cwlVersion: v1.0
class: CommandLineTool
id: bedtools_gtf_to_bed
requirements:
  - class: ShellCommandRequirement
  - class: DockerRequirement
    dockerPull: 'kfdrc/bedops:2.4.36'
  - class: ResourceRequirement
    ramMin: 8000
    coresMin: 4
  - class: InlineJavascriptRequirement
baseCommand: [/bin/bash, -c]
arguments:
  - position: 1
    shellQuote: false
    valueFrom: >-
      set -eo pipefail
      
      ${
          if(inputs.input_bed_gtf.nameext == '.bed'){
              var cmd = "cp " + inputs.input_bed_gtf.path + " .; exit 0;"
          }
      }

      cat $(inputs.input_bed_gtf.path) | grep -vE "^#" | cut -f 1,4,5 | awk '{OFS = "\t";a=$2-1;print $1,a,$3; }'
      | bedtools sort
      | bedtools merge > $(inputs.input_bed_gtf.basename).bed

inputs:
  input_bed_gtf: {type: File, doc: "GTF File to convert to merged and sorted bed file. If a bed file, will pass thru"}
outputs:
  run_bed:
    type: File
    outputBinding:
      glob: '*.bed'
