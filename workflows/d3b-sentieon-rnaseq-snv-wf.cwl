cwlVersion: v1.2
class: Workflow
id: d3b-sentieon-rnaseq-snv-wf

requirements:
- class: MultipleInputFeatureRequirement
- class: InlineJavascriptRequirement
- class: StepInputExpressionRequirement

inputs:
  sorted_align: { type: File, secondaryFiles: [{pattern: ".bai", required: false}, {pattern: "^.bai", required: false}, {pattern: ".crai", required: false},
      {pattern: "^.crai", required: false}] }
  reference: { type: File, secondaryFiles: ['.fai'],  doc: "location of the reference FASTA file. Use if input is cram" }
  sentieon_license: {type: 'string?', doc: "License server host and port", default: "10.5.64.221:8990"}
  output_basename: { type: 'string?' }

outputs:
  dnascope_rnaseq_vcf: {type: File, outputSource: sentieon_dnascope/rna_snv_vcf }

steps:
  samtools_cram2bam:
    when: $(inputs.input_reads.basename.search(/.cram$/) != -1)
    run: ../tools/samtools_cram2bam.cwl
    in:
      input_reads: sorted_align
      reference: reference
    out: [bam_file]
  sambamba_markdup:
    run: ../tools/sambamba_markdup.cwl
    in:
      sorted_align:
        source: [samtools_cram2bam/bam_file, sorted_align]
        pickValue: first_non_null
    out: [markduplicates_bam]
  sentieon_split_reads:
    run: ../tools/sentieon_split_reads.cwl
    in:
      sentieon_license: sentieon_license
      reference: reference
      rmdup_align: sambamba_markdup/markduplicates_bam
    out: [split_bam]
  sentieon_dnascope:
    run: ../tools/sentieon_dnascope.cwl
    in:
      sentieon_license: sentieon_license
      reference: reference
      split_align: sentieon_split_reads/split_bam
      output_basename: output_basename
    out: [rna_snv_vcf]