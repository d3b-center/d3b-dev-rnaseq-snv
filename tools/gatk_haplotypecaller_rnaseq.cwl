cwlVersion: v1.0
class: CommandLineTool
id: gatk-haplotypecaller-rnaseq
requirements:
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    ramMin: 8000
    coresMin: 4
  - class: DockerRequirement
    dockerPull: 'kfdrc/gatk:3.8_ubuntu'
baseCommand: [mkdir, TMP]
arguments:
  - position: 1
    shellQuote: false
    valueFrom: >-

      java -Xmx7500m -Djava.io.tmpdir=TMP -jar /GenomeAnalysisTK.jar
      -R $(inputs.reference_fasta.path)
      -T HaplotypeCaller
      -I $(inputs.bqsr_bam.path)
      --filter_reads_with_N_cigar
      --genotyping_mode DISCOVERY
      --fix_misencoded_quality_scores
      -stand_call_conf 50
      ${
        if (inputs.genes_bed != null){
          return "-L " + inputs.genes_bed.path;
        }
        else{
          return "";
        }
      }
      -nct 4
      -ERC GVCF
      -variant_index_type LINEAR
      -variant_index_parameter 128000
      -o $(inputs.output_basename).gatk.hc.called.vcf

      bgzip $(inputs.output_basename).gatk.hc.called.vcf

      tabix $(inputs.output_basename).gatk.hc.called.vcf.gz
inputs:
  reference_fasta: {type: File, secondaryFiles: ['.fai', '^.dict']}
  bqsr_bam: {type: File, secondaryFiles: ['.bai']}
  genes_bed: {type: File?}
  output_basename: string
outputs:
  hc_called_vcf:
    type: File
    outputBinding:
      glob: '*.gatk.hc.called.vcf.gz'
    secondaryFiles: ['.tbi']
