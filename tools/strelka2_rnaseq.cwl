cwlVersion: v1.0
class: CommandLineTool
id: strelka2-rnaseq
requirements:
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    ramMin: ${return inputs.ram * 1000}
    coresMin: $(inputs.cores)
  - class: DockerRequirement
    dockerPull: 'migbro/strelka2:2.9.10'

baseCommand: [/strelka-2.9.10.centos6_x86_64/bin/configureStrelkaGermlineWorkflow.py]
arguments:
  - position: 1
    shellQuote: false
    valueFrom: >-
      --bam $(inputs.input_rna_bam.path)
      --reference $(inputs.reference.path)
      --callRegions $(inputs.strelka2_bed.path)
      --rna
      --runDir ./
      && ./runWorkflow.py
      -m local
      -j $(inputs.cores)
      -g $(input.ram)

inputs:
  reference: { type: File, secondaryFiles: [.fai] }
  input_rna_bam: {type: File, secondaryFiles: [^.bai]}
  strelka2_bed: {type: File, secondaryFiles: [.tbi], label: gzipped bed file}
  cores: {type: ['null', int], default: 16, doc: "Num cores to use"}
  ram: {type: ['null', int], default: 30, doc: "Max mem to use in GB"}
outputs:
  output_vcf:
    type: File
    outputBinding:
      glob: 'results/variants/*.variants.vcf.gz'
    secondaryFiles: [.tbi]

