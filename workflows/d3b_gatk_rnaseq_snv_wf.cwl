cwlVersion: v1.0
class: Workflow
doc: |-
    GATK RNAseq SNV Calling Workflow
    The overall [workflow](https://gatk.broadinstitute.org/hc/en-us/articles/360035531192-RNAseq-short-variant-discovery-SNPs-Indels-) picks up from post-STAR alignment, starting at Picard mark duplicates.
    For the most part, tool parameters follow defaults from the GATK Best Practices [WDL](https://github.com/gatk-workflows/gatk4-rnaseq-germline-snps-indels/blob/master/gatk4-rna-best-practices.wdl), written in cwl with added optimatization for use on the Cavatica platform.
    The git repo serving this app and related tools can be found [here](https://github.com/d3b-center/d3b-dev-rnaseq-snv)
    `workflows/d3b_gatk_rnaseq_snv_wf.cwl` is the wrapper cwl used to run all tools for GAT4.

    ### Inputs
    ```yaml
    inputs:
      output_basename: string
      STAR_sorted_genomic_bam: {type: File, doc: "STAR sorted alignment bam", secondaryFiles: ['^.bai']}
      sample_name: string
      reference_fasta: {type: File, secondaryFiles: ['.fai', '^.dict'], doc: "Reference genome used"}
      reference_dict: File
      vardict_min_vaf: {type: ['null', float], doc: "Min variant allele frequency for vardict to consider.  Recommend 0.2", default: 0.2}
      vardict_cpus: {type: ['null', int], default: 4}
      vardict_ram: {type: ['null', int], default: 8, doc: "In GB"}
      call_bed_file: {type: File, doc: "BED or GTF intervals to make calls"}
      tool_name: {type: string, doc: "description of tool that generated data, i.e. gatk_haplotypecaller"}
      padding: {type: ['null', int], doc: "Padding to add to input intervals, recommened 0 if intervals already padded, 150 if not", default: 150}
      mode: {type: ['null', {type: enum, name: select_vars_mode, symbols: ["gatk", "grep"]}], doc: "Choose 'gatk' for SelectVariants tool, or 'grep' for grep expression", default: "gatk"}
    ```

    ### Outputs
    ```yaml
    outputs:
      haplotype_called__vcf: {type: File, outputSource: merge_hc_vcf/merged_vcf, doc: "Haplotype Caller called vcf, after genotyping"}
      filtered_vcf: {type: File, outputSource: gatk_filter_vcf/filtered_vcf, doc: "Called vcf after Broad-recommended hard filters applied"}
      pass_vcf: {type: File, outputSource: gatk_pass_vcf/pass_vcf, doc: "Filtered vcf selected for PASS variants"}
    ```

    ### Docker Pulls
    - `kfdrc/sambamba:0.7.1`
    - `kfdrc/gatk:4.1.1.0`
    - `kfdrc/python:2.7.13`

    ### Simulated bash calls

    | Step                                               | Type         | Num scatter            | Command                                                                                                                                                                                                         |
    | -------------------------------------------------- | ------------ | ---------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
    | sambamba_sort_gatk_md_subwf_sambamba_nsort_bam                                               | run step         | NA            | /bin/bash -c set -eo pipefail                                                                                                                                                                                                         |
    | sambamba_sort_gatk_md_subwf_sambamba_nsort_bam                                               | run step         | NA            |                                                                                                                                                                                                          |
    | sambamba_sort_gatk_md_subwf_sambamba_nsort_bam                                               | run step         | NA            | mkdir TMP                                                                                                                                                                                                         |
    | sambamba_sort_gatk_md_subwf_sambamba_nsort_bam                                               | run step         | NA            | sambamba sort -t 16 -m 30GiB -N --show-progress --tmpdir TMP /sbgenomics/Projects/598f0ba4-d8a8-45e7-8bf2-1fe004e4979a/da63df67-62a4-487b-aa68-d7f139809160.Aligned.out.sorted.bam -o da63df67-62a4-487b-aa68-d7f139809160.Aligned.out.sorted.sorted.bam                                                                                                                                                                                                         |
    | bedtools_gtf_to_bed                                               | run step         | NA            | /bin/bash -c set -eo pipefail                                                                                                                                                                                                         |
    | bedtools_gtf_to_bed                                               | run step         | NA            | null                                                                                                                                                                                                         |
    | bedtools_gtf_to_bed                                               | run step         | NA            | cat /sbgenomics/Projects/598f0ba4-d8a8-45e7-8bf2-1fe004e4979a/gencode.v33.primary_assembly.annotation.gtf | grep -vE "^#" | cut -f 1,4,5 | awk '{OFS = "\t";a=$2-1;print $1,a,$3; }' | bedtools sort | bedtools merge > gencode.v33.primary_assembly.annotation.gtf.bed                                                                                                                                                                                                         |
    | gatk_intervallisttools                                               | run step         | NA            | /bin/bash -c set -eo pipefail                                                                                                                                                                                                         |
    | gatk_intervallisttools                                               | run step         | NA            | /gatk BedToIntervalList -I /sbgenomics/workspaces/598f0ba4-d8a8-45e7-8bf2-1fe004e4979a/tasks/3c20cc8e-18d7-43f2-bc2c-4a76d38a88f8/bedtools_gtf_to_bed/gencode.v33.primary_assembly.annotation.gtf.bed -O gencode.v33.primary_assembly.annotation.gtf.interval_list -SD /sbgenomics/Projects/598f0ba4-d8a8-45e7-8bf2-1fe004e4979a/GRCh38.primary_assembly.genome.dict; LIST=gencode.v33.primary_assembly.annotation.gtf.interval_list;BANDS=0;                                                                                                                                                                                                         |
    | gatk_intervallisttools                                               | run step         | NA            | /gatk IntervalListTools --java-options "-Xmx2000m" --SCATTER_COUNT=50 --SUBDIVISION_MODE=BALANCING_WITHOUT_INTERVAL_SUBDIVISION_WITH_OVERFLOW --UNIQUE=true --SORT=true --BREAK_BANDS_AT_MULTIPLES_OF=$BANDS --INPUT=$LIST --OUTPUT=.;CT=`find . -name 'temp_0*' | wc -l`;seq -f "%04g" $CT | xargs -I N -P 4 /gatk IntervalListToBed --java-options -Xmx100m -I temp_N_of_$CT/scattered.interval_list -O temp_N_of_$CT/scattered.interval_list.N.bed;mv temp_0*/*.bed .;                                                                                                                                                                                                         |
    | sambamba_sort_gatk_md_subwf_gatk_md_sorted                                               | run step         | NA            | mkdir TMP                                                                                                                                                                                                         |
    | sambamba_sort_gatk_md_subwf_gatk_md_sorted                                               | run step         | NA            | /gatk MarkDuplicatesSpark --java-options "-Xmx30000m -XX:+PrintFlagsFinal -Xloggc:gc_log.log -XX:GCTimeLimit=50 -XX:GCHeapFreeLimit=10" --tmp-dir TMP -I=/sbgenomics/workspaces/598f0ba4-d8a8-45e7-8bf2-1fe004e4979a/tasks/3c20cc8e-18d7-43f2-bc2c-4a76d38a88f8/sambamba_sort_gatk_md_subwf_sambamba_nsort_bam/da63df67-62a4-487b-aa68-d7f139809160.Aligned.out.sorted.sorted.bam -O=da63df67-62a4-487b-aa68-d7f139809160.Aligned.out.sorted.sorted.dup_marked.bam                                                                                                                                                                                                         |
    | sambamba_sort_gatk_md_subwf_sambamba_csort_bam                                               | run step         | NA            | /bin/bash -c set -eo pipefail                                                                                                                                                                                                         |
    | sambamba_sort_gatk_md_subwf_sambamba_csort_bam                                               | run step         | NA            |                                                                                                                                                                                                          |
    | sambamba_sort_gatk_md_subwf_sambamba_csort_bam                                               | run step         | NA            | mkdir TMP                                                                                                                                                                                                         |
    | sambamba_sort_gatk_md_subwf_sambamba_csort_bam                                               | run step         | NA            | sambamba sort -t 16 -m 30GiB  --show-progress --tmpdir TMP /sbgenomics/workspaces/598f0ba4-d8a8-45e7-8bf2-1fe004e4979a/tasks/3c20cc8e-18d7-43f2-bc2c-4a76d38a88f8/sambamba_sort_gatk_md_subwf_gatk_md_sorted/da63df67-62a4-487b-aa68-d7f139809160.Aligned.out.sorted.sorted.dup_marked.bam -o da63df67-62a4-487b-aa68-d7f139809160.Aligned.out.sorted.sorted.dup_marked.sorted.bam                                                                                                                                                                                                         |
    | sambamba_sort_gatk_md_subwf_samtools_index                                               | run step         | NA            | /bin/bash -c set -eo pipefail                                                                                                                                                                                                         |
    | sambamba_sort_gatk_md_subwf_samtools_index                                               | run step         | NA            | cp /sbgenomics/workspaces/598f0ba4-d8a8-45e7-8bf2-1fe004e4979a/tasks/3c20cc8e-18d7-43f2-bc2c-4a76d38a88f8/sambamba_sort_gatk_md_subwf_sambamba_csort_bam/da63df67-62a4-487b-aa68-d7f139809160.Aligned.out.sorted.sorted.dup_marked.sorted.bam .                                                                                                                                                                                                         |
    | sambamba_sort_gatk_md_subwf_samtools_index                                               | run step         | NA            | samtools index -@ 16 /sbgenomics/workspaces/598f0ba4-d8a8-45e7-8bf2-1fe004e4979a/tasks/3c20cc8e-18d7-43f2-bc2c-4a76d38a88f8/sambamba_sort_gatk_md_subwf_sambamba_csort_bam/da63df67-62a4-487b-aa68-d7f139809160.Aligned.out.sorted.sorted.dup_marked.sorted.bam da63df67-62a4-487b-aa68-d7f139809160.Aligned.out.sorted.sorted.dup_marked.sorted.bai                                                                                                                                                                                                         |
    | gatk_splitntrim                                               | scatter         | 50            | /gatk SplitNCigarReads --java-options "-Xmx7500m -XX:+PrintFlagsFinal -Xloggc:gc_log.log -XX:GCTimeLimit=50 -XX:GCHeapFreeLimit=10" --max-reads-in-memory 300000 -R /sbgenomics/Projects/598f0ba4-d8a8-45e7-8bf2-1fe004e4979a/GRCh38.primary_assembly.genome.fa -I /sbgenomics/workspaces/598f0ba4-d8a8-45e7-8bf2-1fe004e4979a/tasks/3c20cc8e-18d7-43f2-bc2c-4a76d38a88f8/sambamba_sort_gatk_md_subwf_samtools_index/da63df67-62a4-487b-aa68-d7f139809160.Aligned.out.sorted.sorted.dup_marked.sorted.bam -L /sbgenomics/workspaces/598f0ba4-d8a8-45e7-8bf2-1fe004e4979a/tasks/3c20cc8e-18d7-43f2-bc2c-4a76d38a88f8/gatk_intervallisttools/scattered.interval_list.0001.bed -OBI -O GATK4_NEW_SPLIT.sorted.dup_marked.splitn.bam                                                                                                                                                                                                         |
    | gatk_baserecalibrator                                               | scatter         | 50            | /gatk BaseRecalibrator --java-options "-Xmx7500m -XX:GCTimeLimit=50 -XX:GCHeapFreeLimit=10 -XX:+PrintFlagsFinal -XX:+PrintGCTimeStamps -XX:+PrintGCDateStamps -XX:+PrintGCDetails -Xloggc:gc_log.log" -R /sbgenomics/Projects/598f0ba4-d8a8-45e7-8bf2-1fe004e4979a/GRCh38.primary_assembly.genome.fa -I /sbgenomics/workspaces/598f0ba4-d8a8-45e7-8bf2-1fe004e4979a/tasks/3c20cc8e-18d7-43f2-bc2c-4a76d38a88f8/gatk_splitntrim_10_s/GATK4_NEW_SPLIT.sorted.dup_marked.splitn.bam --use-original-qualities -O GATK4_NEW_SPLIT.sorted.dup_marked.splitn.recal_data.csv  --known-sites /sbgenomics/Projects/598f0ba4-d8a8-45e7-8bf2-1fe004e4979a/1000G_omni2.5.hg38.vcf.gz --known-sites /sbgenomics/Projects/598f0ba4-d8a8-45e7-8bf2-1fe004e4979a/1000G_phase1.snps.high_confidence.hg38.vcf.gz --known-sites /sbgenomics/Projects/598f0ba4-d8a8-45e7-8bf2-1fe004e4979a/Homo_sapiens_assembly38.known_indels.vcf.gz --known-sites /sbgenomics/Projects/598f0ba4-d8a8-45e7-8bf2-1fe004e4979a/Mills_and_1000G_gold_standard.indels.hg38.vcf.gz                                                                                                                                                                                                         |
    | gatk_applybqsr                                               | scatter         | 50            | /gatk ApplyBQSR --java-options "-Xms3000m -XX:+PrintFlagsFinal -XX:+PrintGCTimeStamps -XX:+PrintGCDateStamps -XX:+PrintGCDetails -Xloggc:gc_log.log -XX:GCTimeLimit=50 -XX:GCHeapFreeLimit=10" --create-output-bam-md5 --add-output-sam-program-record -R /sbgenomics/Projects/598f0ba4-d8a8-45e7-8bf2-1fe004e4979a/GRCh38.primary_assembly.genome.fa -I /sbgenomics/workspaces/598f0ba4-d8a8-45e7-8bf2-1fe004e4979a/tasks/3c20cc8e-18d7-43f2-bc2c-4a76d38a88f8/gatk_splitntrim_20_s/GATK4_NEW_SPLIT.sorted.dup_marked.splitn.bam --use-original-qualities -O GATK4_NEW_SPLIT.sorted.dup_marked.splitn.aligned.duplicates_marked.recalibrated.bam -bqsr /sbgenomics/workspaces/598f0ba4-d8a8-45e7-8bf2-1fe004e4979a/tasks/3c20cc8e-18d7-43f2-bc2c-4a76d38a88f8/gatk_baserecalibrator_20_s/GATK4_NEW_SPLIT.sorted.dup_marked.splitn.recal_data.csv                                                                                                                                                                                                         |
    | gatk_haplotype_rnaseq                                               | scatter         | 50            | /gatk HaplotypeCaller -R /sbgenomics/Projects/598f0ba4-d8a8-45e7-8bf2-1fe004e4979a/GRCh38.primary_assembly.genome.fa -I /sbgenomics/workspaces/598f0ba4-d8a8-45e7-8bf2-1fe004e4979a/tasks/3c20cc8e-18d7-43f2-bc2c-4a76d38a88f8/gatk_applybqsr_19_s/GATK4_NEW_SPLIT.sorted.dup_marked.splitn.aligned.duplicates_marked.recalibrated.bam --standard-min-confidence-threshold-for-calling 20  -O GATK4_NEW_SPLIT.gatk.hc.called.vcf.gz --dbsnp /sbgenomics/Projects/598f0ba4-d8a8-45e7-8bf2-1fe004e4979a/Homo_sapiens_assembly38.dbsnp138.vcf                                                                                                                                                                                                         |
    | merge_hc_vcf                                               | run step         | NA            | /gatk MergeVcfs --java-options "-Xmx2000m" --TMP_DIR=./TMP --CREATE_INDEX=true --SEQUENCE_DICTIONARY=/sbgenomics/Projects/598f0ba4-d8a8-45e7-8bf2-1fe004e4979a/GRCh38.primary_assembly.genome.dict --OUTPUT=GATK4_NEW_SPLIT.gatk.hc.merged.vcf.gz  -I /sbgenomics/workspaces/598f0ba4-d8a8-45e7-8bf2-1fe004e4979a/tasks/3c20cc8e-18d7-43f2-bc2c-4a76d38a88f8/gatk_haplotype_rnaseq_1_s/GATK4_NEW_SPLIT.gatk.hc.called.vcf.gz -I /sbgenomics/workspaces/598f0ba4-d8a8-45e7-8bf2-1fe004e4979a/tasks/3c20cc8e-18d7-43f2-bc2c-4a76d38a88f8/gatk_haplotype_rnaseq_2_s/GATK4_NEW_SPLIT.gatk.hc.called.vcf.gz -I /sbgenomics/workspaces/598f0ba4-d8a8-45e7-8bf2-1fe004e4979a/tasks/3c20cc8e-18d7-43f2-bc2c-4a76d38a88f8/gatk_haplotype_rnaseq_3_s/GATK4_NEW_SPLIT.gatk.hc.called.vcf.gz -I /sbgenomics/workspaces/598f0ba4-d8a8-45e7-8bf2-1fe004e4979a/tasks/3c20cc8e-18d7-43f2-bc2c-4a76d38a88f8/gatk_haplotype_rnaseq_4_s/GATK4_NEW_SPLIT.gatk.hc.called.vcf.gz                                                                                                                                                                                                          |
    | gatk_filter_vcf                                               | run step         | NA            | /gatk VariantFiltration -R /sbgenomics/Projects/598f0ba4-d8a8-45e7-8bf2-1fe004e4979a/GRCh38.primary_assembly.genome.fa -V /sbgenomics/workspaces/598f0ba4-d8a8-45e7-8bf2-1fe004e4979a/tasks/3c20cc8e-18d7-43f2-bc2c-4a76d38a88f8/merge_hc_vcf/GATK4_NEW_SPLIT.gatk.hc.merged.vcf.gz --window 35 --cluster 3 --filter-name "FS" --filter "FS > 30.0" --filter-name "QD" --filter "QD < 2.0"  -O GATK4_NEW_SPLIT.gatk.hc.filtered.vcf.gz                                                                                                                                                                                                         |
    | gatk_pass_vcf                                               | run step         | NA            | /bin/bash -c set -eo pipefail                                                                                                                                                                                                         |
    | gatk_pass_vcf                                               | run step         | NA            | /gatk SelectVariants --java-options "-Xmx7500m" -V /sbgenomics/workspaces/598f0ba4-d8a8-45e7-8bf2-1fe004e4979a/tasks/3c20cc8e-18d7-43f2-bc2c-4a76d38a88f8/gatk_filter_vcf/GATK4_NEW_SPLIT.gatk.hc.filtered.vcf.gz -O GATK4_NEW_SPLIT.gatk.hc.PASS.vcf.gz --exclude-filtered TRUE                                                                                                                                                                                                         |


id: d3b-gatk-rnaseq-snv-wf
label: "GATK RNAseq SNV Calling Workflow"
requirements:
  - class: ScatterFeatureRequirement
  - class: MultipleInputFeatureRequirement
  - class: SubworkflowFeatureRequirement

inputs:
  output_basename: string
  pass_thru: {type: boolean, doc: "Param for whether to skip name sort step before markd dup if source is already name sorted", default: false}
  STAR_sorted_genomic_bam: {type: File, doc: "STAR sorted alignment bam", secondaryFiles: ['^.bai']}
  reference_fasta: {type: File, secondaryFiles: ['^.dict', '.fai'], doc: "Reference genome used"}
  reference_dict: File
  call_bed_file: {type: File, doc: "BED or GTF intervals to make calls"}
  exome_flag: {type: string?, default: "Y", doc: "Whether to run in exome mode for callers. Should be Y or leave blank as default is Y. Only make N if you are certain"}
  knownsites: {type: 'File[]', doc: "Population vcfs, based on Broad best practices"}
  dbsnp_vcf: {type: File, secondaryFiles: ['.idx']}
  tool_name: {type: string, doc: "description of tool that generated data, i.e. gatk_haplotypecaller"}
  mode: {type: ['null', {type: enum, name: select_vars_mode, symbols: ["gatk", "grep"]}], doc: "Choose 'gatk' for SelectVariants tool, or 'grep' for grep expression", default: "gatk"}

outputs:
  haplotype_called__vcf: {type: File, outputSource: merge_hc_vcf/merged_vcf, doc: "Haplotype Caller called vcf, after genotyping"}
  filtered_vcf: {type: File, outputSource: gatk_filter_vcf/filtered_vcf, doc: "Called vcf after Broad-recommended hard filters applied"}
  pass_vcf: {type: File, outputSource: gatk_pass_vcf/pass_vcf, doc: "Filtered vcf selected for PASS variants"}

steps:
  bedtools_gtf_to_bed:
    run: ../tools/bedtools_gtf_to_bed.cwl
    in:
      input_bed_gtf: call_bed_file
    out: [run_bed]
  gatk_intervallisttools:
    run: ../tools/gatk_intervallisttool.cwl
    in:
      interval_list: bedtools_gtf_to_bed/run_bed
      reference_dict: reference_dict
      exome_flag: exome_flag
      scatter_ct:
        valueFrom: ${return 50}
      bands:
        valueFrom: ${return 80000000}
    out: [output]
  sambamba_sort_gatk_md_subwf:
    run: ../subworkflows/sambamba_sort_gatk_md_sub_wf.cwl
    label: "SAMBAMBA Sort GATK Mark Duplicates"
    in:
      STAR_sorted_genomic_bam: STAR_sorted_genomic_bam
      pass_thru: pass_thru
    out:
      [sorted_md_bam]
  gatk_splitntrim:
    hints:
      - class: 'sbg:AWSInstanceType'
        value: c5.4xlarge
    run: ../tools/gatk_splitncigarreads.cwl
    label: "GATK Split N Cigar"
    in:
      reference_fasta: reference_fasta
      dup_marked_bam: sambamba_sort_gatk_md_subwf/sorted_md_bam
      interval_bed: gatk_intervallisttools/output
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
      # genes_bed: gatk_intervallisttools/output
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