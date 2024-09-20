
cwlVersion: v1.2
class: CommandLineTool
id: sentieon-dedup
label: Sentieon DEDUP
doc: |-
  Remove PCR duplicates using Senteion LocusCollector + Dedup

requirements:
- class: ShellCommandRequirement
- class: ResourceRequirement
  coresMin: $(Math.max(inputs.threads, 8))
  ramMin: $(inputs.ram * 1000)
- class: DockerRequirement
  dockerPull: pgc-images.sbgenomics.com/hdchen/sentieon:202308.03
- class: EnvVarRequirement
  envDef:
  - envName: SENTIEON_LICENSE
    envValue: $(inputs.sentieon_license)
- class: InlineJavascriptRequirement

arguments:
- position: 0
  shellQuote: false
  valueFrom: >-
    sentieon driver
    -t $(inputs.threads)
    -i $(inputs.sorted_align.path)
    --reference $(inputs.reference.path)
- position: 1
  shellQuote: false
  valueFrom: >-
    --algo LocusCollector
    --fun score_info $(inputs.sorted_align.nameroot).gz
- position: 2
  shellQuote: false
  valueFrom: >-
    && sentieon driver
    -t $(inputs.threads)
    -i $(inputs.sorted_align.path)
    --reference $(inputs.reference.path)
    --algo Dedup
    --score_info $(inputs.sorted_align.nameroot).gz
- position: 3
  shellQuote: false
  valueFrom: >-
    --metrics $(inputs.sorted_align.nameroot).dedup.metrics.txt $(inputs.sorted_align.nameroot).mkdup.bam

inputs:
  sentieon_license: { type: string, doc: "Sentieon license server and port, in format 0.0.0.0:0000 " }
  ram: { type: 'int?', doc: "RAM in GB to make available to this task", default: 16 }
  threads: { type: 'int?', doc: "number of computing threads that will be used by the software to run parallel processes",
    default: 8 }
  reference: { type: File, secondaryFiles: ['.fai'],  doc: "location of the reference FASTA file. Use if input is cram" }
  sorted_align: { type: File, secondaryFiles: [{pattern: ".bai", required: false}, {pattern: "^.bai", required: false}, {pattern: ".crai", required: false},
      {pattern: "^.crai", required: false}] }
  rna: { type: 'boolean?', doc: "Set if align file came from STAR", inputBinding: { position: 1, prefix: "--rna"} }
  rm_dup: { type: 'boolean?', inputBinding: { position: 2, prefix: "--rmdup"} }
outputs:
  score_info: { type: File, outputBinding: { glob: "$(inputs.sorted_align.nameroot).gz" }}
  metrics: { type: File, outputBinding: { glob: "$(inputs.sorted_align.nameroot).dedup.metrics.txt" }}
  rmdup_bam: { type: File, outputBinding: { glob: "$(inputs.sorted_align.nameroot).mkdup.bam"}, secondaryFiles: ['^.bai'] }

