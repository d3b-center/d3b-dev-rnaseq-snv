cwlVersion: v1.2
class: CommandLineTool
id: sambamba-markdup

requirements:
  - class: DockerRequirement
    dockerPull: 'pgc-images.sbgenomics.com/brownm28/sambamba:1.0.1'
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    ramMin: 16000
    coresMin: 8
arguments:
  - position: 0
    shellQuote: false
    valueFrom: >-
      mkdir TMP
      && sambamba markdup
      --tmpdir TMP
  - position: 2
    shellQuote: false
    valueFrom: >-
      $(inputs.sorted_align.nameroot).md.bam

inputs:
  sorted_align: { type: File, secondaryFiles: [{pattern: ".bai", required: false}, {pattern: "^.bai", required: false}],
    inputBinding: { position: 1} }
  ram: { type: 'int?', doc: "RAM in GB to make available to this task", default: 16 }
  threads: { type: 'int?', doc: "number of computing threads that will be used by the software to run parallel processes",
    default: 8, inputBinding: { position: 0, prefix: "-t"} }

outputs: 
  markduplicates_bam:
    type: File
    outputBinding:
      glob: '*.bam'
