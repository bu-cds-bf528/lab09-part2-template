nextflow.enable.types = true

record IndexedGenome {
    fasta: Path
    fai: Path
}

process SAMTOOLS_EXTRACT {
    label 'process_single'
    // REVIEW D02: conda env file from the spec instead of a container directive
    conda "${projectDir}/envs/samtools_env.yml"

    input:
    genome: IndexedGenome
    cds: Path
    transcript: String

    output:
    // REVIEW D11: the CDS BED is passed through with the extracted FASTA so the locate step has the genomic offset
    record(name: transcript, fasta: file("${transcript}.cds.fa"), cds: file(cds.name))

    script:
    """
    read -r chrom start end name score strand < ${cds}
    # REVIEW D20: only the CDS is extracted, no flanking bases, so sites whose spacer or PAM cross a CDS boundary are not found
    # REVIEW D10: BED 0-based thickStart converted to 1-based samtools region (start+1)-end; + strand sequence only, no -i reverse complement
    samtools faidx ${genome.fasta} "\${chrom}:\$((start + 1))-\${end}" > ${transcript}.cds.fa
    """

    stub:
    """
    touch ${transcript}.cds.fa
    """
}
