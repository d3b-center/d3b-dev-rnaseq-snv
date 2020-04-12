cwlVersion: v1.0
class: CommandLineTool
id: sambamba_sort_mark_dup

requirements:
  - class: DockerRequirement
    dockerPull: 'migbro/sambamba:0.7.1'
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
      -t 16
      -m 10GiB
      -N
      --show-progress
      --tmpdir TMP
      -l 0
      $(inputs.input_bam.path)
      -o /dev/stdout
      | sambamba markdup
      -t 16
      --sort-buffer-size 10000
      --show-progress
      --tmpdir TMP
      -l 0
      /dev/stdin
      /dev/stdout
      | sambamba sort
      -t 16
      -m 10GiB
      --tmpdir TMP
      --show-progress
      /dev/stdin
      -o $(inputs.output_basename).sorted.dup_marked.bam

      sambamba index
      -t 16
      $(inputs.output_basename).sorted.dup_marked.bam
      $(inputs.output_basename).sorted.dup_marked.bam.bai
inputs:
  input_bam: File
  output_basename: string
outputs: 
  output_markduplicates_bam:
    type: File
    outputBinding:
      glob: '*.sorted.dup_marked.bam'
    secondaryFiles: [.bai]
