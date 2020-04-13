cwlVersion: v1.0
class: Workflow
doc: >-
    "Sambamba Sort Mark Dup Sub WF"
id: d3b-sambamba-subwf-wf
label: "Sambamba Sort Mark Dup Sub WF"
requirements:
  - class: ScatterFeatureRequirement
  - class: MultipleInputFeatureRequirement

inputs:
  STAR_sorted_genomic_bam: {type: File, doc: "STAR sorted alignment bam", secondaryFiles: ['^.bai']}
  pass_thru: {type: boolean, doc: "Param for whether to skip name sort step before markd dup if source is already name sorted", default: false}

outputs:
  sorted_md_bam: {type: File, outputSource: samtools_index/bam_file, doc: "Dup marked and sorted bam"}

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