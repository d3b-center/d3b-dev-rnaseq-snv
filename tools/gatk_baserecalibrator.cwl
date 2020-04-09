cwlVersion: v1.0
class: CommandLineTool
id: gatkv4_baserecalibrator
requirements:
  - class: ShellCommandRequirement
  - class: InlineJavascriptRequirement
  - class: DockerRequirement
    dockerPull: 'kfdrc/gatk:4.1.1.0'
  - class: ResourceRequirement
    ramMin: 8000
    coresMin: 8
baseCommand: [/gatk, BaseRecalibrator]
arguments:
  - position: 0
    shellQuote: false
    valueFrom: >-
      --java-options "-Xms4000m
      -XX:GCTimeLimit=50
      -XX:GCHeapFreeLimit=10
      -XX:+PrintFlagsFinal
      -XX:+PrintGCTimeStamps
      -XX:+PrintGCDateStamps
      -XX:+PrintGCDetails
      -Xloggc:gc_log.log"
      -R $(inputs.reference.path)
      -I $(inputs.input_bam.path)
      --use-original-qualities
      -O $(inputs.input_bam.nameroot).recal_data.csv
      ${
        if(inputs.sequence_interval != null){
          return "-L " + inputs.sequence_interval.path;
        }
        else{
          return "";
        }
      }

inputs:
  reference: {type: File, secondaryFiles: [^.dict, .fai]}
  input_bam: {type: File, secondaryFiles: [^.bai]}
  knownsites:
    type:
      type: array
      items: File
      inputBinding:
        prefix: --known-sites
    inputBinding:
      position: 1
    secondaryFiles: [.tbi]
  sequence_interval: File?
outputs:
  output:
    type: File
    outputBinding:
      glob: '*.recal_data.csv'
