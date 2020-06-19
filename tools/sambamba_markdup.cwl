cwlVersion: v1.0
class: CommandLineTool
id: sambamba_sort_mark_dup

requirements:
  - class: DockerRequirement
    dockerPull: 'kfdrc/sambamba:0.7.1'
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    ramMin: 16000
    coresMin: 8
baseCommand: ["/bin/bash", "-c"]
arguments:
  - position: 1
    shellQuote: false
    valueFrom: >-
      set -eo pipefail

      mkdir TMP

      sambamba markdup
      -t 8
      --sort-buffer-size 15000
      --tmpdir TMP
      $(inputs.input_bam.path)
      $(inputs.input_bam.nameroot).md.bam

      mv $(inputs.input_bam.nameroot).md.bam.bai $(inputs.input_bam.nameroot).md.bai

inputs:
  input_bam: File
outputs: 
  markduplicates_bam:
    type: File
    outputBinding:
      glob: '*.bam'
