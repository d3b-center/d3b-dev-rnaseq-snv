cwlVersion: v1.0
class: CommandLineTool
id: gatk-filter-variants
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
      -T VariantFiltration
      -V $(inputs.gt_vcf.path)
      -window 35
      -cluster 
      -filterName FS
      -filter "FS > 30.0"
      -filterName QD -filter "QD < 2.0"
      ${
        if (inputs.genes_bed != null){
          return "-L " + inputs.genes_bed.path;
        }
        else{
          return "";
        }
      }
      -nct 16
      -o $(inputs.output_basename).gatk.hc.filtered.vcf
 
inputs:
  reference_fasta: {type: File, secondaryFiles: ['.fai', '^.dict']}
  gt_vcf: {type: File, secondaryFiles: ['.tbi']}
  genes_bed: {type: File?}
  output_basename: string
outputs:
  hc_called_vcf:
    type: File
    outputBinding:
      glob: '*.gatk.hc.filtered.vcf'