nextflow.enable.types = true

include { SAMTOOLS_FAIDX } from './modules/samtools_faidx'
include { GET_CDS } from './modules/get_cds'
include { SAMTOOLS_EXTRACT } from './modules/samtools_extract'
include { SEQKIT_LOCATE } from './modules/seqkit_locate'

workflow {
    // REVIEW D03: "Get genome" and "Choose transcript" are Provided rows, so they are params, not processes
    // REVIEW D15: genome, BED and transcript are single values (file()/String), not channels: one genome and one transcript per run
    genome = file(params.genome)
    bed = file(params.bed)
    transcript = params.transcript

    indexed_genome = SAMTOOLS_FAIDX(genome)
    cds_region = GET_CDS(bed, transcript)
    cds_sequence = SAMTOOLS_EXTRACT(indexed_genome, cds_region, transcript)
    target_sites = SEQKIT_LOCATE(cds_sequence)
}
