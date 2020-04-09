cwlVersion: v1.0
class: CommandLineTool
id: gatk-genotype-vcf
requirements:
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    ramMin: 32000
    coresMin: 16
  - class: DockerRequirement
    dockerPull: 'kfdrc/gatk:3.8_ubuntu'
baseCommand: [mkdir, TMP]
arguments:
  - position: 1
    shellQuote: false
    valueFrom: >-

      java -Xmx23g -Djava.io.tmpdir=TMP -jar /GenomeAnalysisTK.jar
      -R $(inputs.reference_fasta.path)
      -T GenotypeGVCFs
      -nct 16
      ${
        if (inputs.genes_bed != null){
          return "-L " + inputs.genes_bed.path;
        }
        else{
          return "";
        }
      }
      -o $(inputs.output_basename).gatk.hc.gt.vcf.gz
      --variant $(inputs.hc_called_vcf.path)
 
inputs:
  reference_fasta: {type: File, secondaryFiles: ['.fai', '^.dict']}
  hc_called_vcf: File
  genes_bed: {type: File?}
  output_basename: string
outputs:
  gt_vcf:
    type: File
    outputBinding:
      glob: '*.gatk.hc.gt.vcf.gz'
    secondaryFiles: ['.tbi']
