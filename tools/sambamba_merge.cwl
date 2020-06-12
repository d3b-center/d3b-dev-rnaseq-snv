cwlVersion: v1.0
class: CommandLineTool
id: sambamba_merge

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
      
      mkdir TMP

      sambamba sort
      $(inputs.output_basename).bam
      -t 16
      -m 30GiB
      --show-progress
      --tmpdir TMP

  - position: 3
    shellQuote: false
    valueFrom: >-
      mv $(inputs.output_basename).bam.bai $(inputs.output_basename).bai

inputs:
  input_bams:
    type:
      type: array
      items: File
      inputBinding:
        separate: false
        position: 1
  output_basename: string
outputs: 
  merged_bam:
    type: File
    outputBinding:
      glob: '*.bam'
    secondaryFiles: ['^.bai']
