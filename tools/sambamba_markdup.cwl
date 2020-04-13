cwlVersion: v1.0
class: CommandLineTool
id: sambamba_sort_mark_dup

requirements:
  - class: DockerRequirement
    dockerPull: 'migbro/sambamba:0.7.1'
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    ramMin: 8000
    coresMin: 4
baseCommand: ["/bin/bash", "-c"]
arguments:
  - position: 1
    shellQuote: false
    valueFrom: >-
      set -eo pipefail

      mkdir TMP

      sambamba markdup
      -t 4
      --sort-buffer-size 7500
      --show-progress
      --tmpdir TMP
      $(inputs.input_bam.path)
      $(inputs.input_bam.nameroot).md.bam

inputs:
  input_bam: File
outputs: 
  markduplicates_bam:
    type: File
    outputBinding:
      glob: '*.bam'
