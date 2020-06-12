cwlVersion: v1.0
class: CommandLineTool
id: gatk-splitbambyreads
requirements:
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    ramMin: 8000
    coresMin: 4
  - class: DockerRequirement
    dockerPull: 'kfdrc/gatk:4.1.7.0R'
baseCommand: [/gatk, SplitSamByNumberOfReads]
arguments:
  - position: 1
    shellQuote: false
    valueFrom: >-
      --java-options "-Xmx7500m
      -XX:+PrintFlagsFinal
      -Xloggc:gc_log.log
      -XX:GCTimeLimit=50
      -XX:GCHeapFreeLimit=10"
      -I $(inputs.dup_marked_bam.path)
      -O ./
      --SPLIT_TO_N_FILES $(inputs.num_split)
      --CREATE_INDEX true
inputs:
  dup_marked_bam: File
  num_split: {type: int?, doc: "Nunber of files to split the bam into", default: 50}
outputs:
  split_bams:
    type: File[]
    outputBinding:
      glob: '*.bam'
    secondaryFiles: ['^.bai']
