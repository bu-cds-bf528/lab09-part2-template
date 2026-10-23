nextflow.enable.types = true

process GET_CDS {
    label 'process_single'
    // REVIEW D02: conda env file from the spec instead of a container directive
    conda "${projectDir}/envs/python_env.yml"

    input:
    bed: Path
    transcript: String

    output:
    // REVIEW D09: CDS written as a one-line BED6 (0-based, half-open) named <transcript>.cds.bed
    cds: Path = file("${transcript}.cds.bed")

    script:
    """
    get_cds.py --bed ${bed} --transcript ${transcript} --out ${transcript}.cds.bed
    """

    stub:
    """
    touch ${transcript}.cds.bed
    """
}
