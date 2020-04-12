cwlVersion: v1.0
class: Workflow
doc: >-
    "Strelka2 SNV Calling Workflow"
id: d3b-strelka2-rnaseq-snv-wf
label: "Strelka2 RNAseq SNV Calling Workflow"
requirements:
  - class: ScatterFeatureRequirement
  - class: MultipleInputFeatureRequirement

inputs:
  output_basename: string
  STAR_sorted_genomic_bam: {type: File, doc: "STAR sorted alignment bam", secondaryFiles: ['^.bai']}
  reference_fasta: {type: File, secondaryFiles: ['.fai'], doc: "Reference genome used"}
  tool_name: {type: string, doc: "description of tool that generated data, i.e. gatk_haplotypecaller"}
  mode: {type: ['null', {type: enum, name: select_vars_mode, symbols: ["gatk", "grep"]}], doc: "Choose 'gatk' for SelectVariants tool, or 'grep' for grep expression", default: "gatk"}

outputs:
  strelka2_prepass_vcf: {type: File, outputSource: strelka2_rnaseq/output_vcf, doc: "Strelka2 SNV calls"}
  strelka2_pass_vcf: {type: File, outputSource: gatk_pass_vcf/pass_vcf, doc: "Strelka2 calls filtered on PASS"}

steps:
  strelka2_rnaseq:
    run: ../tools/strelka2_rnaseq.cwl
    label: Strelka2
    in:
      reference: reference_fasta
      input_rna_bam: STAR_sorted_genomic_bam
      # strelka2_bed: {type: File?, secondaryFiles: [.tbi], label: gzipped bed file}
      output_basename: output_basename
    out: [output_vcf]

  gatk_pass_vcf:
    run: ../tools/gatk_selectvariants.cwl
    label: "GATK Select PASS"
    in:
      input_vcf: strelka2_rnaseq/output_vcf
      output_basename: output_basename
      tool_name: tool_name
      mode: mode
    out: [pass_vcf]