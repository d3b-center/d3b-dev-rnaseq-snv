
cwlVersion: v1.2
class: CommandLineTool
id: sentieon-split-reads
label: Sentieon RNASplitReadsAtJunction
doc: |-
  Remove PCR duplicates using Senteion LocusCollector + Dedup

requirements:
- class: ShellCommandRequirement
- class: ResourceRequirement
  coresMin: $(Math.max(inputs.threads, 8))
  ramMin: $(inputs.ram * 1000)
- class: DockerRequirement
  dockerPull: pgc-images.sbgenomics.com/hdchen/sentieon:202308.02_cavatica
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
- position: 1
  shellQuote: false
  valueFrom: >-
    --algo RNASplitReadsAtJunction
    --reassign_mapq 255:60
    $(inputs.rmdup_align.nameroot).rdsplit.bam

inputs:
  sentieon_license: { type: string, doc: "Sentieon license server and port, in format 0.0.0.0:0000" }
  ram: { type: 'int?', doc: "RAM in GB to make available to this task", default: 16 }
  threads: { type: 'int?', doc: "number of computing threads that will be used by the software to run parallel processes",
    default: 8, inputBinding: { position: 0, prefix: "-t" } }
  reference: { type: File, secondaryFiles: ['.fai'],  doc: "location of the reference FASTA file. Use if input is cram",
    inputBinding: { position: 0, prefix: "--reference"} }
  rmdup_align: { type: File, secondaryFiles: [{pattern: ".bai", required: false}, {pattern: "^.bai", required: false}, {pattern: ".crai", required: false},
      {pattern: "^.crai", required: false}], inputBinding: { position: 0, prefix: "-i"} }
outputs:
  split_bam: { type: File, outputBinding: { glob: "$(inputs.rmdup_align.nameroot).rdsplit.bam"}, secondaryFiles: [{pattern: ".bai", required: false}, {pattern: "^.bai", required: false}] }

