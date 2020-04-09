cwlVersion: v1.0
class: CommandLineTool
id: picard_markduplicates_spark

requirements:
  - class: DockerRequirement
    dockerPull: 'kfdrc/gatk:4.1.1.0'
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    ramMin: 32000
    coresMin: 16
baseCommand: [/gatk, MarkDuplicatesSpark]
arguments:
  - position: 1
    shellQuote: false
    valueFrom: >-
      -I=$(inputs.input_bam.path)
      -O=$(inputs.output_basename).sorted.dup_marked.bam
      -OBI
      -M=$(inputs.output_basename).sorted.deduped.metrics
inputs:
  input_bam: File
  output_basename: string
outputs: 
  output_markduplicates_bam:
    type: File
    outputBinding:
      glob: '*.bam'
    secondaryFiles: [.bai]
  metrics:
    type: File
    outputBinding:
      glob: '*.sorted.deduped.metrics'