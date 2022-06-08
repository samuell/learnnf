#!/usr/bin/env nextflow
nextflow.enable.dsl=2

params.chrYFilename = 'Homo_sapiens.GRCh38.dna.chromosome.Y.fa.gz'
params.chrYUrl = 'ftp://ftp.ensembl.org/pub/release-84/fasta/homo_sapiens/dna/Homo_sapiens.GRCh38.dna.chromosome.Y.fa.gz'

process DOWNLOAD {
    publishDir 'results'
    output:
      path params.chrYFilename

    """
    wget '${params.chrYUrl}' -O '${params.chrYFilename}'
    """
}

process UNGZIP {
    publishDir 'results'
    input:
      path gz
    output:
      path 'file.fa'

    script:
      """
      zcat '${gz}' > 'file.fa'
      """
}

workflow {
  DOWNLOAD()
  UNGZIP(DOWNLOAD.out)
}
