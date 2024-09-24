cwlVersion: v1.2
class: Workflow
doc: |-
    Strelka2 SNV Calling Workflow
    
    This [workflow](https://github.com/Illumina/strelka/blob/v2.9.x/docs/userGuide/README.md#rna-seq) is pretty straight forward, with a `PASS` filter step added to get `PASS` calls.
    The git repo serving this app and related tools can be found [here](https://github.com/d3b-center/d3b-dev-rnaseq-snv), compatible with all releases as of 2020-Jun-17.
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

    ### Docker Pulls
    - `kfdrc/strelka2:2.9.10`
    - `kfdrc/gatk:4.1.1.0`

    ### Simulated bash calls
    An example of bash calls from each step can be found in the [git repo](https://github.com/d3b-center/d3b-dev-rnaseq-snv#strelka2-simulated-bash-calls)

id: d3b-strelka2-rnaseq-snv-wf
label: "Strelka2 RNAseq SNV Calling Workflow"
requirements:
  - class: ScatterFeatureRequirement
  - class: MultipleInputFeatureRequirement
  - class: SubworkflowFeatureRequirement

inputs:
  sorted_align: { type: File, secondaryFiles: [{pattern: ".bai", required: false}, {pattern: "^.bai", required: false}, {pattern: ".crai", required: false},
      {pattern: "^.crai", required: false}] }
  reference: {type: 'File', doc: "GRCh38.primary_assembly.genome.fa", "sbg:suggestedValue": {class: File, path: 5f500135e4b0370371c051b4,
      name: GRCh38.primary_assembly.genome.fa, secondaryFiles: [{class: File, path: 62866da14d85bc2e02ba52db, name: GRCh38.primary_assembly.genome.fa.fai}]},
    secondaryFiles: ['.fai']}
  # Strelka2
  strelka2_bed: { type: 'File?', secondaryFiles: [.tbi], doc: "gzipped bed file, if relevant" }
  is_rna: { type: 'boolean?', doc: "Flag to turn on RNA flag depths and model", default: true }
  strelka2_cores: {type: 'int?', default: 16, doc: "Num cores to use" }
  strelka2_ram: {type: 'int?', default: 30, doc: "Max mem to use in GB" }
  output_basename: { type: 'string?', doc: "Output vcf prefix for filename. Will have suffix of .strelka2.rnaseq.vcf.gz" }
  # Annotation
  bcftools_annot_clinvar_columns: {type: 'string?', doc: "csv string of columns from annotation to port into the input vcf", default: "INFO/ALLELEID,INFO/CLNDN,INFO/CLNDNINCL,INFO/CLNDISDB,INFO/CLNDISDBINCL,INFO/CLNHGVS,INFO/CLNREVSTAT,INFO/CLNSIG,INFO/CLNSIGCONF,INFO/CLNSIGINCL,INFO/CLNVC,INFO/CLNVCSO,INFO/CLNVI"}
  echtvar_anno_zips: {type: 'File[]?', doc: "Annotation ZIP files for echtvar anno", "sbg:suggestedValue": [{class: File, path: 65c64d847dab7758206248c6,
        name: gnomad.v3.1.1.custom.echtvar.zip}]}
  clinvar_annotation_vcf: {type: 'File?', secondaryFiles: ['.tbi'], doc: "additional bgzipped annotation vcf file"}
  bcftools_prefilter_csv: {type: 'string?', doc: "csv of bcftools filter params if you want to prefilter before annotation", default: }
  # VEP-specific
  vep_ram: {type: 'int?', default: 64, doc: "In GB, may need to increase this value depending on the size/complexity of input"}
  vep_cores: {type: 'int?', default: 32, doc: "Number of cores to use. May need to increase for really large inputs"}
  vep_buffer_size: {type: 'int?', default: 100000, doc: "Increase or decrease to balance speed and memory usage"}
  vep_cache: {type: 'File', doc: "tar gzipped cache from ensembl/local converted cache", "sbg:suggestedValue": {class: File, path: 6332f8e47535110eb79c794f,
      name: homo_sapiens_merged_vep_105_indexed_GRCh38.tar.gz}}
  dbnsfp: {type: 'File?', secondaryFiles: [.tbi, ^.readme.txt], doc: "VEP-formatted plugin file, index, and readme file containing
      dbNSFP annotations"}
  dbnsfp_fields: {type: 'string?', doc: "csv string with desired fields to annotate. Use ALL to grab all", default: 'SIFT4G_pred,Polyphen2_HDIV_pred,Polyphen2_HVAR_pred,LRT_pred,MutationTaster_pred,MutationAssessor_pred,FATHMM_pred,PROVEAN_pred,VEST4_score,VEST4_rankscore,MetaSVM_pred,MetaLR_pred,MetaRNN_pred,M-CAP_pred,REVEL_score,REVEL_rankscore,PrimateAI_pred,DEOGEN2_pred,BayesDel_noAF_pred,ClinPred_pred,LIST-S2_pred,Aloft_pred,fathmm-MKL_coding_pred,fathmm-XF_coding_pred,Eigen-phred_coding,Eigen-PC-phred_coding,phyloP100way_vertebrate,phyloP100way_vertebrate_rankscore,phastCons100way_vertebrate,phastCons100way_vertebrate_rankscore,TWINSUK_AC,TWINSUK_AF,ALSPAC_AC,ALSPAC_AF,UK10K_AC,UK10K_AF,gnomAD_exomes_controls_AC,gnomAD_exomes_controls_AN,gnomAD_exomes_controls_AF,gnomAD_exomes_controls_nhomalt,gnomAD_exomes_controls_POPMAX_AC,gnomAD_exomes_controls_POPMAX_AN,gnomAD_exomes_controls_POPMAX_AF,gnomAD_exomes_controls_POPMAX_nhomalt,Interpro_domain,GTEx_V8_gene,GTEx_V8_tissue'}
  merged: {type: 'boolean?', doc: "Set to true if merged cache used", default: true}
  cadd_indels: {type: 'File?', secondaryFiles: [.tbi], doc: "VEP-formatted plugin file and index containing CADD indel annotations"}
  cadd_snvs: {type: 'File?', secondaryFiles: [.tbi], doc: "VEP-formatted plugin file and index containing CADD SNV annotations"}
  intervar: {type: 'File?', doc: "Intervar vcf-formatted file. Exonic SNVs only - for more comprehensive run InterVar. See docs for
      custom build instructions", secondaryFiles: [.tbi]}

outputs:
  strelka2_prepass_vcf: {type: File, outputSource: strelka2_rnaseq/output_vcf, doc: "Strelka2 SNV calls"}
  strelka2_annotated_vcf: {type: 'File[]', outputSource: annotate_vcf/annotated_vcf, doc: "Strelka2 annotated and filtered as specified by bcftools_prefilter_csv"}

steps:
  strelka2_rnaseq:
    run: ../tools/strelka2_rnaseq.cwl
    label: Strelka2
    in:
      reference: reference
      input_rna_align: sorted_align
      strelka2_bed: strelka2_bed
      is_rna: is_rna
      strelka2_cores: strelka2_cores
      strelka2_ram: strelka2_ram
      output_basename: output_basename
    out: [output_vcf]

  annotate_vcf:
    run: ../kf-annotation-tools/workflows/kfdrc-germline-snv-annot-workflow.cwl
    doc: 'annotate variants'
    in:
      indexed_reference_fasta: reference
      input_vcf: strelka2_rnaseq/output_vcf
      output_basename: output_basename
      tool_name:
        valueFrom: "strelka2.rnaseq"
      bcftools_annot_clinvar_columns: bcftools_annot_clinvar_columns
      echtvar_anno_zips: echtvar_anno_zips
      clinvar_annotation_vcf: clinvar_annotation_vcf
      bcftools_prefilter_csv: bcftools_prefilter_csv
      vep_ram: vep_ram
      vep_cores: vep_cores
      vep_buffer_size: vep_buffer_size
      vep_cache: vep_cache
      dbnsfp: dbnsfp
      dbnsfp_fields: dbnsfp_fields
      cadd_indels: cadd_indels
      cadd_snvs: cadd_snvs
      merged: merged
      intervar: intervar
    out: [annotated_vcf]

hints:
- class: "sbg:maxNumberOfParallelInstances"
  value: 3
$namespaces:
  sbg: https://sevenbridges.com