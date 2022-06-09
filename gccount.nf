#!/usr/bin/env nextflow
nextflow.enable.dsl=2

params.chrYFilename = 'Homo_sapiens.GRCh38.dna.chromosome.Y.fa.gz'
params.chrYUrl = 'ftp://ftp.ensembl.org/pub/release-84/fasta/homo_sapiens/dna/Homo_sapiens.GRCh38.dna.chromosome.Y.fa.gz'
params.linesPerSplit = 100000

process DOWNLOAD {
    publishDir 'rawdata'

    output:
      path params.chrYFilename

    """
    wget '${params.chrYUrl}' -O '${params.chrYFilename}'
    """
}

process UNGZIP {
    publishDir 'rawdata'

    input:
      path gz
    output:
      path 'file.fa'

    script:
      """
      zcat '${gz}' > 'file.fa'
      """
}

process SPLIT {
    publishDir 'splits'

    input:
      path fasta
    output:
      path 'fasta_splits_*'

    script:
      """
      split -l ${params.linesPerSplit} $fasta fasta_splits_
      """
}

workflow {
  DOWNLOAD()
  UNGZIP(DOWNLOAD.out)
  SPLIT(UNGZIP.out)
}
