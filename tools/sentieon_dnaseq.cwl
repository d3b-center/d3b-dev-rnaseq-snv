cwlVersion: v1.2
class: CommandLineTool
id: sentieon-dnaseq
label: Sentieon Haplotyper
doc: |-
  Variant Calling using Haplotyper

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
- position: 1
  shellQuote: false
  valueFrom: >-
    --algo Haplotyper
    --trim_soft_clip
    --call_conf 20
    --emit_conf 20
- position: 2
  shellQuote: false
  valueFrom: >-
    $(inputs.output_basename).dnaseq.vcf.gz

inputs:
  sentieon_license: { type: string, doc: "Sentieon license server and port, in format 0.0.0.0:0000" }
  ram: { type: 'int?', doc: "RAM in GB to make available to this task", default: 64 }
  threads: { type: 'int?', doc: "number of computing threads that will be used by the software to run parallel processes",
    default: 32, inputBinding: { position: 0, prefix: "-t" } }
  reference: { type: File, secondaryFiles: ['.fai'],  doc: "location of the reference FASTA file. Use if input is cram",
    inputBinding: { position: 0, prefix: "--reference"} }
  recal_data_table: { type: 'File?', doc: "BQSR results, if run",
    inputBinding: { position: 0, prefix: "-q"} }
  dbsnp_vcf: { type: 'File?', doc: "Optional dbSNP file with known variants",
    inputBinding: { position: 1, prefix: "-d" } }
  output_basename: { type: 'string?', doc: "basename of output vcf file. suffix .dnaseq.vcf.gz will be added to it",
    default: $(inputs.split_align.nameroot) }
  split_align: { type: File, secondaryFiles: [{pattern: ".bai", required: false}, {pattern: "^.bai", required: false}, {pattern: ".crai", required: false},
      {pattern: "^.crai", required: false}], inputBinding: { position: 0, prefix: "-i"} }
outputs:
  rna_snv_vcf: { type: File, outputBinding: { glob: "$(inputs.output_basename).dnaseq.vcf.gz"}, secondaryFiles: [".tbi"] }
