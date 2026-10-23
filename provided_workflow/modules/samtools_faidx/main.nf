nextflow.enable.types = true

process SAMTOOLS_FAIDX {
    label 'process_single'
    // REVIEW D02: conda env file from the spec instead of a container directive
    conda "${projectDir}/envs/samtools_env.yml"

    input:
    genome: Path

    output:
    // REVIEW D08: the staged FASTA is re-emitted alongside its .fai so the two always travel together
    record(fasta: file(genome.name), fai: file("${genome.name}.fai"))

    script:
    """
    samtools faidx ${genome}
    """

    stub:
    """
    touch ${genome.name}.fai
    """
}
