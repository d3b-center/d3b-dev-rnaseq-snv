# RNAseq SNV Calling Workflow
This repo contains snv calling methods using Broad GATK best practices, Strelka2, and VarDict

<p align="center">
  <img alt="Logo for The Center for Data Driven Discovery" src="https://raw.githubusercontent.com/d3b-center/handbook/master/website/static/img/chop_logo.svg?sanitize=true" width="400px" />
</p>

For all workflows,input bams should be indexed beforehand.  This tool is provided in `tools/samtools_index.cwl`

## GATK4 v4.1.1.0
The overall [workflow](https://gatk.broadinstitute.org/hc/en-us/articles/360035531192-RNAseq-short-variant-discovery-SNPs-Indels-) picks up from post-STAR alignment, starting at Picard mark duplicates.
For the most part, tool parameters follow defaults from the GATK Best Practices [WDL](https://github.com/gatk-workflows/gatk4-rnaseq-germline-snps-indels/blob/master/gatk4-rna-best-practices.wdl), written in cwl with added optimatization for use on the Cavatica platform.
`workflows/d3b_gatk_rnaseq_snv_wf.cwl` is the wrapper cwl used to run all tools for GAT4.

### Inputs
```yaml
inputs:
  output_basename: string
  pass_thru: {type: boolean, doc: "Param for whether to skip name sort step before markd dup if source is already name sorted", default: false}
  STAR_sorted_genomic_bam: {type: File, doc: "STAR sorted alignment bam", secondaryFiles: ['^.bai']}
  reference_fasta: {type: File, secondaryFiles: ['^.dict', '.fai'], doc: "Reference genome used"}
  reference_dict: File
  knownsites: {type: 'File[]', doc: "Population vcfs, based on Broad best practices"}
  dbsnp_vcf: {type: File, secondaryFiles: ['.idx']}
  tool_name: {type: string, doc: "description of tool that generated data, i.e. gatk_haplotypecaller"}
  mode: {type: ['null', {type: enum, name: select_vars_mode, symbols: ["gatk", "grep"]}], doc: "Choose 'gatk' for SelectVariants tool, or 'grep' for grep expression", default: "gatk"}
```

### Outputs
```yaml
outputs:
  haplotype_called__vcf: {type: File, outputSource: merge_hc_vcf/merged_vcf, doc: "Haplotype Caller called vcf, after genotyping"}
  filtered_vcf: {type: File, outputSource: gatk_filter_vcf/filtered_vcf, doc: "Called vcf after Broad-recommended hard filters applied"}
  pass_vcf: {type: File, outputSource: gatk_pass_vcf/pass_vcf, doc: "Filtered vcf selected for PASS variants"}
```

### Workflow Diagram

![WF diagram](misc/d3b_gatk_rnaseq_snv_wf.cwl.svg)

## Strelka2 v2.9.10
This [workflow](https://github.com/Illumina/strelka/blob/v2.9.x/docs/userGuide/README.md#rna-seq) is pretty straight forward, with a `PASS` filter step added to get `PASS` calls.
`workflows/d3b_strelka2_rnaseq_snv_wf.cwl` is the wrapper cwl that runs this workflow

### Inputs
```yaml
inputs:
  reference: { type: File, secondaryFiles: [.fai] }
  input_rna_bam: {type: File, secondaryFiles: [^.bai]}
  strelka2_bed: {type: File?, secondaryFiles: [.tbi], label: gzipped bed file}
  cores: {type: ['null', int], default: 16, doc: "Num cores to use"}
  ram: {type: ['null', int], default: 30, doc: "Max mem to use in GB"}
  output_basename: string
```

### Outputs
```yaml
  strelka2_prepass_vcf: {type: File, outputSource: strelka2_rnaseq/output_vcf, doc: "Strelka2 SNV calls"}
  strelka2_pass_vcf: {type: File, outputSource: gatk_pass_vcf/pass_vcf, doc: "Strelka2 calls filtered on PASS"}
```

### Workflow Diagram

![WF diagram](misc/d3b_strelka2_rnaseq_snv_wf.cwl.svg)

## Kraken2
[Kraken2](http://ccb.jhu.edu/software/kraken2/index.shtml) is available to run at `tools/kraken2_classification.cwl`.

```yaml
inputs:
  input_db: { type: File, doc: "Input TGZ containing Kraken2 database" }
  input_reads: { type: File, doc: "FA or FQ file containing sequences to be classified" }
  input_mates: { type: 'File?', doc: "Paired mates for input_reads" }
  db_path: { type: string, default: "./covid", doc: "Relative path to the folder containing the db files from input_db" }
  threads: { type: int, default: 32, doc: "Number of threads to use in parallel" }
  ram: { type: int, default: 50000, doc: "Recommended MB of RAM needed to run the job" }
  output_basename: { type: string, doc: "String to be used as the base filename of the output" }
```

```yaml
outputs:
  output: { type: File, outputBinding: { glob: "*.output" } }
  classified_reads: { type: 'File', outputBinding: { glob: "*_1.fq" } }
  classified_mates: { type: 'File?', outputBinding: { glob: "*_2.fq" } }
```
