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

process COUNTAT {
    publishDir 'countsat'

    input:
      path fasta
    output:
      path 'atcounts.txt'

    script:
      """
      cat $fasta | fold -w 1 | grep '[AT]' | wc -l | awk '{ print \$1 }' >> atcounts.txt
      """
}

process COUNTGC {
    publishDir 'countsgc'

    input:
      path fasta
    output:
      path 'gccounts.txt'

    script:
      """
      cat $fasta | fold -w 1 | grep '[GC]' | wc -l | awk '{ print \$1 }' >> gccounts.txt
      """
}

process SUMCOUNTS {
    publishDir 'allcounts'

    input:
      path counts
    output:
      path 'allcounts'
    
    script:
      """
      awk '{ SUM += \$1 } END { print SUM }' $counts > allcounts
      """
}

workflow {
  DOWNLOAD()
  UNGZIP(DOWNLOAD.out)
  UNGZIP.out.splitText( by: 100000, file: true ).set{ splits }

  COUNTAT(splits)
  COUNTGC(splits)
  //COUNTAT.out.collectFile(name: 'collected_atcounts.txt' )
  //COUNTAT.out.collectFile(name: 'collected_gccounts.txt' )
}
