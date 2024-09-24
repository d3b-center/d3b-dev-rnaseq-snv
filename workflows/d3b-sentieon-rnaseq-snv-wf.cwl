cwlVersion: v1.2
class: Workflow
id: d3b-sentieon-rnaseq-snv-wf

requirements:
- class: MultipleInputFeatureRequirement
- class: InlineJavascriptRequirement
- class: StepInputExpressionRequirement
- class: SubworkflowFeatureRequirement

inputs:
  sorted_align: { type: File, secondaryFiles: [{pattern: ".bai", required: false}, {pattern: "^.bai", required: false}, {pattern: ".crai", required: false},
      {pattern: "^.crai", required: false}] }
  reference: {type: 'File', doc: "GRCh38.primary_assembly.genome.fa", "sbg:suggestedValue": {class: File, path: 5f500135e4b0370371c051b4,
      name: GRCh38.primary_assembly.genome.fa, secondaryFiles: [{class: File, path: 62866da14d85bc2e02ba52db, name: GRCh38.primary_assembly.genome.fa.fai}]},
    secondaryFiles: ['.fai']}
  sentieon_license: {type: 'string?', doc: "License server host and port", default: "10.5.64.221:8990"}
  output_basename: { type: 'string?' }
  split_reads_cpu: { type: 'int?', default: 16 }
  split_reads_ram: { type: 'int?', default: 64 }
  # Annotation
  run_annotation: { type: 'boolean?', default: false, doc: "Turn on annotation of output"}
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
  dnascope_rnaseq_vcf: {type: File, outputSource: sentieon_dnaseq/rna_snv_vcf }
  annotated_vcf: { type: 'File[]?', outputSource: annotate_vcf/annotated_vcf }

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
      ram: split_reads_ram
      threads: split_reads_cpu
    out: [split_bam]
  sentieon_dnaseq:
    run: ../tools/sentieon_dnaseq.cwl
    in:
      sentieon_license: sentieon_license
      reference: reference
      split_align: sentieon_split_reads/split_bam
      output_basename: output_basename
    out: [rna_snv_vcf]
  annotate_vcf:
    run: ../kf-annotation-tools/workflows/kfdrc-germline-snv-annot-workflow.cwl
    when: $(inputs.run_wf)
    hints:
    - class: 'sbg:AWSInstanceType'
      value: c6.8xlarge;ebs-gp3;500
    doc: 'annotate variants'
    in:
      run_wf: run_annotation
      indexed_reference_fasta: reference
      input_vcf: sentieon_dnaseq/rna_snv_vcf
      output_basename: output_basename
      tool_name:
        valueFrom: "sentieon_dnaseq.rnaseq"
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