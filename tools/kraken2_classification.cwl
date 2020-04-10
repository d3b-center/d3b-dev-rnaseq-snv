cwlVersion: v1.0
class: CommandLineTool
id: kraken2_classification 
requirements:
  - class: ShellCommandRequirement
  - class: DockerRequirement
    dockerPull: 'dmiller15/kraken2:0.0.2'
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    ramMin: $(inputs.ram) 
    coresMin: $(inputs.threads)
baseCommand: ["/bin/bash -c"]
arguments:
  - position: 1
    shellQuote: false
    valueFrom: >-
      set -eo pipefail

      tar --use-compress-program=pigz -xf $(inputs.input_db.path) &&
      kraken2
      --db $(inputs.db_path)
      --threads $(inputs.threads)
      --output $(inputs.output_basename).output
      ${
        if (inputs.input_mates) {
          var cmd = ["--paired --classified-out "+inputs.output_basename+"_cseqs#.fq",inputs.input_reads.path,inputs.input_mates.path]
          return cmd.join(' ')
        } else {
          var cmd = ["--classified-out "+inputs.output_basename+"_cseqs_1.fq",inputs.input_reads.path]
          return cmd.join(' ')
        }
      }
inputs:
  input_db: { type: File, doc: "Input TGZ containing Kraken2 database" }
  input_reads: { type: File, doc: "FA or FQ file containing sequences to be classified" }
  input_mates: { type: 'File?', doc: "Paired mates for input_reads" }
  db_path: { type: string, default: "./covid", doc: "Relative path to the folder containing the db files from input_db" } 
  threads: { type: int, default: 32, doc: "Number of threads to use in parallel" }
  ram: { type: int, default: 50000, doc: "Recommended KB of RAM needed to run the job" }
  output_basename: { type: string, doc: "String to be used as the base filename of the output" }
outputs:
  output: { type: File, outputBinding: { glob: "*.output" } }
  classified_reads: { type: 'File', outputBinding: { glob: "*_1.fq" } }
  classified_mates: { type: 'File?', outputBinding: { glob: "*_2.fq" } }

$namespaces:
  sbg: https://sevenbridges.com
