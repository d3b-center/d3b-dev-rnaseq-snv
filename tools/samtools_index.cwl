cwlVersion: v1.0
class: CommandLineTool
id: samtools_index_bam
requirements:
  - class: ShellCommandRequirement
  - class: DockerRequirement
    dockerPull: 'kfdrc/samtools:1.9'
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    ramMin: 12000
    coresMin: $(inputs.threads)
  
baseCommand: ["/bin/bash -c"]
arguments:
  - position: 1
    shellQuote: false
    valueFrom: >-
      set -eo pipefail

      cp $(inputs.input_reads.path) .

      samtools index -@ 16 $(inputs.input_reads.path) $(inputs.input_reads.nameroot).bai
inputs:
  input_reads: File
  threads:
    type: ['null', int]
    default: 16
outputs:
  bam_file:
    type: File
    outputBinding:
      glob: '*.bam'
    secondaryFiles: [^.bai]
