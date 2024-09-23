cwlVersion: v1.2
class: CommandLineTool
id: strelka2-rnaseq
requirements:
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    ramMin: ${return inputs.ram * 1000}
    coresMin: $(inputs.cores)
  - class: DockerRequirement
    dockerPull: "pgc-images.sbgenomics.com/d3b-bixu/strelka:v2.9.10"


baseCommand: [/strelka-2.9.10.centos6_x86_64/bin/configureStrelkaGermlineWorkflow.py]
arguments:
  - position: 0
    shellQuote: false
    valueFrom: >-
      --runDir ./
  - position: 1
    shellQuote: false
    valueFrom: >-
      && ./runWorkflow.py
      -m local
  - position: 2
    shellQuote: false
    valueFrom: >-
      && mv results/variants/variants.vcf.gz $(inputs.output_basename).strelka2.rnaseq.vcf.gz
      && mv results/variants/variants.vcf.gz.tbi $(inputs.output_basename).strelka2.rnaseq.vcf.gz.tbi

inputs:
  reference: { type: File, secondaryFiles: ['.fai'], doc: "Reference that input file was aligned against",
    inputBinding: { position: 0, prefix: "--reference"}}
  input_rna_align: {type: File, secondaryFiles: [{pattern: ".bai", required: false}, {pattern: "^.bai", required: false}, {pattern: ".crai", required: false},
      {pattern: "^.crai", required: false}], inputBinding: { position: 0, prefix: "--bam"}}
  strelka2_bed: { type: 'File?', secondaryFiles: [.tbi], doc: "gzipped bed file, if relevant",
    inputBinding: { position: 0, prefix: "--callRegions"} }
  is_rna: { type: 'boolean?', doc: "Flag to turn on RNA flag depths and model", default: true,
    inputBinding: { position: 0, prefix: "--rna"} }
  cores: {type: 'int?', default: 16, doc: "Num cores to use",
    inputBinding: { position: 1, prefix: "-j"} }
  ram: {type: 'int?', default: 30, doc: "Max mem to use in GB",
   inputBinding: { position: 1, prefix: "-g"} }
  output_basename: { type: 'string?', doc: "Output vcf prefix for filename. Will have suffix of .strelka2.rnaseq.vcf.gz",
    default: $(inputs.input_rna_align.nameroot) }
outputs:
  output_vcf:
    type: File
    outputBinding:
      glob: '*.strelka2.rnaseq.vcf.gz'
    secondaryFiles: [.tbi]

