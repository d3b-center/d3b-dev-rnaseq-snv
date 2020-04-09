cwlVersion: v1.0
class: Workflow
doc: >-
    "GATK RNAseq SNV Calling Workflow"
id: d3b-gatk-rnaseq-snv-wf
label: "GATK RNAseq SNV Calling Workflow"
requirements:
  - class: ScatterFeatureRequirement
  - class: MultipleInputFeatureRequirement

inputs:
  output_basename: string
  STAR_sorted_genomic_bam: {type: File, doc: "STAR sorted alignment bam"}
  reference_fasta: {type: File, secondaryFiles: ['^.dict', '.fai'], doc: "Reference genome used"}
  intervals_bed: {type: File?, doc: "bed file with intervals to evaluate instead of evaluating all"}
  knownsites: File[]
  tool_name: {type: string, doc: "description of tool that generated data, i.e. gatk_haplotypecaller"}
  mode: {type: ['null', {type: enum, name: select_vars_mode, symbols: ["gatk", "grep"]}], doc: "Choose 'gatk' for SelectVariants tool, or 'grep' for grep expression", default: "gatk"}

outputs:
  genotyped_vcf: {type: File, outputSource: gatk_gt_vcf/gt_vcf, doc: "Haplotype Caller called vcf, after genotyping"}
  filtered_vcf: {type: File, outputSource: gatk_filter_vcf/filtered_vcf, doc: "Called vcf after Broad-recommended hard filters applied"}
  pass_vcf: {type: File, outputSource: gatk_pass_vcf/pass_vcf, doc: "Filtered vcf selected for PASS variants"}

steps:
  gatk_markduplicates:
    run: ../tools/picard_markduplicates_spark.cwl
    in:
      input_bam: STAR_sorted_genomic_bam
      output_basename: output_basename
    out:
      [output_markduplicates_bam, metrics]
  gatk_splitntrim:
    run: ../tools/gatk_splitncigarreads.cwl
    in:
      reference_fasta: reference_fasta
      dup_marked_bam: gatk_markduplicates/output_markduplicates_bam
      interval_bed: intervals_bed
      output_basename: output_basename
    out: [cigar_n_split_bam]
  gatk_baserecalibrator:
    run: ../tools/gatk_baserecalibrator.cwl
    in:
      input_bam: gatk_splitntrim/cigar_n_split_bam
      knownsites: knownsites
      reference: reference_fasta
      # sequence_interval: python_createsequencegroups/sequence_intervals
    # scatter: [sequence_interval]
    out: [output]
  gatk_applybqsr:
    run: ../tools/gatk_applybqsr.cwl
    in:
      reference: reference_fasta
      input_bam: gatk_splitntrim/cigar_n_split_bam
      bqsr_report: gatk_baserecalibrator/output
      # sequence_interval: intervals_bed
    out: [recalibrated_bam]
  gatk_haplotype_rnaseq:
    run: ../tools/gatk_haplotypecaller_rnaseq.cwl
    in:
      reference_fasta: reference_fasta
      bqsr_bam: gatk_applybqsr/recalibrated_bam
      # genes_bed: intervals_bed
      output_basename: output_basename
    out: [hc_called_vcf]
  gatk_gt_vcf:
    run: ../tools/gatk_gt_vcf.cwl
    in:
      reference_fasta: reference_fasta
      hc_called_vcf: gatk_haplotype_rnaseq/hc_called_vcf
      # genes_bed: intervals_bed
      output_basename: output_basename
    out:
     [gt_vcf]
  gatk_filter_vcf:
    run: ../tools/gatk_filtervariants.cwl
    in:
      reference_fasta: reference_fasta
      gt_vcf: gatk_gt_vcf/gt_vcf
      # genes_bed: intervals_bed
      output_basename: output_basename
    out: [filtered_vcf]
  gatk_pass_vcf:
    run: ../tools/gatk_selectvariants.cwl
    in:
      input_vcf: gatk_filter_vcf/filtered_vcf
      output_basename: output_basename
      tool_name: tool_name
      mode: mode
    out: [pass_vcf]

$namespaces:
  sbg: https://sevenbridges.com
hints:
  - class: 'sbg:maxNumberOfParallelInstances'
    value: 3