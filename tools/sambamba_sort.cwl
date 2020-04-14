cwlVersion: v1.0
class: CommandLineTool
id: sambamba_sort

requirements:
  - class: DockerRequirement
    dockerPull: 'kfdrc/sambamba:0.7.1'
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    ramMin: 32000
    coresMin: 16
baseCommand: ["/bin/bash", "-c"]
arguments:
  - position: 1
    shellQuote: false
    valueFrom: >-
      set -eo pipefail
      
      ${
          if (inputs.pass_thru){
              var cmd = "cp " + inputs.input_bam.path + " .; exit 0;"
              return cmd;
          }
          else{
              return "";
          }
      }

      mkdir TMP

      sambamba sort
      -t 16
      -m 30GiB
      ${
          if (inputs.sort_type != null){
              return "-" + inputs.sort_type;
          }
          else{
              return "";
          }
      }
      --show-progress
      --tmpdir TMP
      $(inputs.input_bam.path)
      -o $(inputs.input_bam.nameroot).sorted.bam

inputs:
  input_bam: File
  sort_type: string?
  pass_thru: boolean
outputs: 
  sorted_bam:
    type: File
    outputBinding:
      glob: '*.bam'
