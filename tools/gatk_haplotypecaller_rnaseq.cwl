cwlVersion: v1.0
class: CommandLineTool
id: gatk-rnaseq-snv
requirements:
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    ramMin: 32000
    coresMin: 16
    coresMax: 4
  - class: DockerRequirement
    dockerPull: 'kfdrc/gatk:3.8_ubuntu'
baseCommand: [mkdir, TMP]
arguments:
  - position: 1
    shellQuote: false
    valueFrom: >-

      java -Xmx23g -Djava.io.tmpdir=TMP -jar /GenomeAnalysisTK.jar
      -R $(inputs.reference_fasta.path)
      -T HaplotypeCaller
      -I $(inputs.dup_marked_bam.path)
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
      -nct 16
      -ERC GVCF
      -variant_index_type LINEAR
      -variant_index_parameter 128000
      -o $(inputs.output_basename).called.vcf

      java -Xmx23g -Djava.io.tmpdir=TMP -jar /GenomeAnalysisTK.jar
      -R $(inputs.reference_fasta.path)
      -T GenotypeGVCFs
      ${
        if (inputs.genes_bed != null){
          return "-L " + inputs.genes_bed.path;
        }
        else{
          return "";
        }
      }
      -o $(inputs.output_basename).gatk.rnaseq.vcf.gz
      --variant $(inputs.output_basename).called.vcf
 
inputs:
  reference_fasta: {type: File, secondaryFiles: ['.fai', '^.dict']}
  dup_marked_bam: {type: File, secondaryFiles: ['.bai']}
  genes_bed: {type: File?}
  output_basename: string
outputs:
  output:
    type: File
    outputBinding:
      glob: '*.vcf.gz'
    secondaryFiles: [.tbi]
