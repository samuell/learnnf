#!/usr/bin/env nextflow
// A port of the scatter/gather example workflow in the SciPipe repo:
// https://github.com/scipipe/scipipe/blob/master/examples/scatter_gather/scattergather.go
// Author: Samuel Lampa shl@rilspace.com

nextflow.enable.dsl=2

params.chrYFilename = 'Homo_sapiens.GRCh38.dna.chromosome.Y.fa.gz'
params.chrYUrl = 'ftp://ftp.ensembl.org/pub/release-84/fasta/homo_sapiens/dna/Homo_sapiens.GRCh38.dna.chromosome.Y.fa.gz'
params.linesPerSplit = 100000

process DOWNLOAD {
    output:
      path params.chrYFilename

    """
    wget '${params.chrYUrl}' -O '${params.chrYFilename}'
    """
}

process UNGZIP {
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
    input:
      path allcounts
    output:
      path 'allcounts_at.sum'

    script:
      """
      awk '{ SUM += \$1 } END { print SUM }' $allcounts > allcounts_at.sum
      """
}

process SUMGCS {
    input:
      path allcounts
    output:
      path 'allcounts_gc.sum'

    script:
      """
      awk '{ SUM += \$1 } END { print SUM }' $allcounts > allcounts_gc.sum
      """
}

process GCRATIO {
    publishDir 'gcratio'

    input:
      path gccount
      path atcount

    output:
      'gcratio.txt'

    script:
      """
      gc=\$(cat $gccount); at=\$(cat $atcount); calc "\$gc/(\$gc+\$at)" > gcratio.txt
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
  GCRATIO( SUMGCS.out, SUMATS.out )
}
