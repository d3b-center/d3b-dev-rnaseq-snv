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
  STAR_sorted_genomic_bam: {type: File, doc: "STAR sorted alignment bam", secondaryFiles: ['^.bai']}
  reference_fasta: {type: File, secondaryFiles: ['^.dict', '.fai'], doc: "Reference genome used"}
  reference_dict: File
  knownsites: {type: 'File[]', doc: "Population vcfs, based on Broad best practices"}
  dbsnp_vcf: {type: File, secondaryFiles: ['.idx']}
  tool_name: {type: string, doc: "description of tool that generated data, i.e. gatk_haplotypecaller"}
  mode: {type: ['null', {type: enum, name: select_vars_mode, symbols: ["gatk", "grep"]}], doc: "Choose 'gatk' for SelectVariants tool, or 'grep' for grep expression", default: "gatk"}

outputs:
  haplotype_called__vcf: {type: File, outputSource: merge_hc_vcf/merged_vcf, doc: "Haplotype Caller called vcf, after genotyping"}
  filtered_vcf: {type: File, outputSource: gatk_filter_vcf/filtered_vcf, doc: "Called vcf after Broad-recommended hard filters applied"}
  pass_vcf: {type: File, outputSource: gatk_pass_vcf/pass_vcf, doc: "Filtered vcf selected for PASS variants"}

steps:
  python_createsequencegroups:
    run: ../tools/python_createsequencegroups.cwl
    label: "Python Intvl from Dict"
    in:
      ref_dict: reference_dict
    out: [sequence_intervals, sequence_intervals_with_unmapped]
  gatk_markduplicates:
    run: ../tools/picard_markduplicates_spark.cwl
    label: "GATK Mark Duplicates"
    in:
      input_bam: STAR_sorted_genomic_bam
      output_basename: output_basename
    out:
      [output_markduplicates_bam, metrics]
  gatk_splitntrim:
    hints:
      - class: 'sbg:AWSInstanceType'
        value: c5.4xlarge
    run: ../tools/gatk_splitncigarreads.cwl
    label: "GATK Split N Cigar"
    in:
      reference_fasta: reference_fasta
      dup_marked_bam: gatk_markduplicates/output_markduplicates_bam
      interval_bed: python_createsequencegroups/sequence_intervals
      output_basename: output_basename
    scatter: interval_bed
    out: [cigar_n_split_bam]
  gatk_baserecalibrator:
    hints:
      - class: 'sbg:AWSInstanceType'
        value: c5.4xlarge
    run: ../tools/gatk_baserecalibrator.cwl
    label: "GATK BQSR"
    in:
      input_bam: gatk_splitntrim/cigar_n_split_bam
      knownsites: knownsites
      reference: reference_fasta
      # sequence_interval: python_createsequencegroups/sequence_intervals
    scatter: [input_bam]
    out: [output]
  gatk_applybqsr:
    hints:
      - class: 'sbg:AWSInstanceType'
        value: c5.4xlarge
    run: ../tools/gatk_applybqsr.cwl
    label: "GATK Apply BQSR"
    in:
      reference: reference_fasta
      input_bam: gatk_splitntrim/cigar_n_split_bam
      bqsr_report: gatk_baserecalibrator/output
      # sequence_interval: python_createsequencegroups/sequence_intervals_with_unmapped
    scatter: [input_bam, bqsr_report]
    scatterMethod: dotproduct
    out: [recalibrated_bam]
  gatk_haplotype_rnaseq:
    hints:
      - class: 'sbg:AWSInstanceType'
        value: c5.4xlarge
    run: ../tools/gatk_haplotypecaller_rnaseq.cwl
    label: "GATK Haplotype Caller"
    in:
      reference_fasta: reference_fasta
      bqsr_bam: gatk_applybqsr/recalibrated_bam
      dbsnp: dbsnp_vcf
      # genes_bed: python_createsequencegroups/sequence_intervals
      output_basename: output_basename
    scatter: bqsr_bam
    out: [hc_called_vcf]
  merge_hc_vcf:
    run: ../tools/gatk_mergevcfs.cwl
    label: "GAK Merge HC VCF"
    in:
      input_vcfs: gatk_haplotype_rnaseq/hc_called_vcf
      reference_dict: reference_dict
      output_basename: output_basename
      tool_name: tool_name
    out: [merged_vcf]
  gatk_filter_vcf:
    run: ../tools/gatk_filtervariants.cwl
    label: "GATK Hard Filter VCF"
    in:
      reference_fasta: reference_fasta
      hc_vcf: merge_hc_vcf/merged_vcf
      # genes_bed: intervals_bed
      output_basename: output_basename
    out: [filtered_vcf]
  gatk_pass_vcf:
    run: ../tools/gatk_selectvariants.cwl
    label: "GATK Select PASS"
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
    value: 2