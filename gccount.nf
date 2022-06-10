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

process SUMATS {
    publishDir 'allcounts'

    input:
      path allcounts
    output:
      path 'allcounts.sum'

    script:
      """
      awk '{ SUM += \$1 } END { print SUM }' $allcounts > allcounts.sum
      """
}

process SUMGCS {
    publishDir 'allcounts'

    input:
      path allcounts
    output:
      path 'allcounts.sum'
 
    script:
      """
      awk '{ SUM += \$1 } END { print SUM }' $allcounts > allcounts.sum
      """
}

workflow {
  DOWNLOAD()
  UNGZIP(DOWNLOAD.out)
  UNGZIP.out.splitText( by: 100000, file: true ).set{ splits }
  COUNTAT(splits)
  COUNTGC(splits)
  COUNTAT.out.collectFile( name: 'all_at_combined.txt' ).set{ all_ats }
  COUNTGC.out.collectFile( name: 'all_gc_combined.txt' ).set{ all_gcs }
  SUMATS( all_ats )
  SUMGCS( all_gcs )
}
