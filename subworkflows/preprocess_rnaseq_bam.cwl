cwlVersion: v1.0
class: Workflow
doc: >-
    "Preprocessing sub workflow for GATK4 RNAseq SNV calling.
    Uses Sambamba for mark dups and sort, GATK SplitNCigarReads for final processed bam output"
id: d3b-sambamba-subwf-wf
label: "Sambamba Sort Mark Dup Sub WF"
requirements:
  - class: ScatterFeatureRequirement
  - class: MultipleInputFeatureRequirement

inputs:
  STAR_sorted_genomic_bam: {type: File, doc: "STAR sorted alignment bam", secondaryFiles: ['^.bai']}
  reference_fasta: {type: File, secondaryFiles: ['^.dict', '.fai'], doc: "Reference genome used"}
  pass_thru: {type: boolean, doc: "Param for whether to skip name sort step before markd dup if source is already name sorted", default: false}
outputs:
  sorted_md_splitn_bam: {type: File, outputSource: gatk_splitntrim/cigar_n_split_bam, secondaryFiles: ['^.bai'], doc: "Dup marked, sorted, Split N trim cigar bam"}

steps:
  sambamba_nsort_bam:
    run: ../tools/sambamba_sort.cwl
    label: "Sambamba Sort Bam"
    in:
      input_bam: STAR_sorted_genomic_bam
      sort_type: {default: "N"}
      pass_thru: pass_thru
    out: [sorted_bam]
  sambamba_md_sorted:
    run: ../tools/sambamba_markdup.cwl
    label: "Sambamba Mardup"
    in:
      input_bam: sambamba_nsort_bam/sorted_bam
    out: [markduplicates_bam]
  sambamba_csort_bam:
    run: ../tools/sambamba_sort.cwl
    label: "Sambamba Sort Bam"
    in:
      input_bam: sambamba_md_sorted/markduplicates_bam
      pass_thru: 
        valueFrom:
          ${return false}
    out: [sorted_bam]
  samtools_index:
    run: ../tools/samtools_index.cwl
    label: "Samtools bam index"
    in:
      input_reads: sambamba_csort_bam/sorted_bam
    out: [bam_file]
  gatk_splitntrim:
    run: ../tools/gatk_splitncigarreads.cwl
    label: "GATK Split N Cigar"
    in:
      reference_fasta: reference_fasta
      dup_marked_bam: samtools_index/bam_file
    out: [cigar_n_split_bam]
