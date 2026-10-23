nextflow.enable.types = true

record ExtractedCds {
    name: String
    fasta: Path
    cds: Path
}

process SEQKIT_LOCATE {
    label 'process_single'
    // REVIEW D02: conda env file from the spec instead of a container directive
    conda "${projectDir}/envs/seqkit_env.yml"

    input:
    target: ExtractedCds

    output:
    guides: Path = file("${target.name}.guides.tsv")

    script:
    """
    # REVIEW D12: target = 20-nt spacer + NGG PAM (pattern N{21}GG), IUPAC via -d, case-insensitive via -i, both strands, overlapping hits kept
    # REVIEW D21: with -d, pattern N means A/C/G/T only, so any site containing an N (or other ambiguity code) in the genome is dropped
    seqkit locate -i -d -p NNNNNNNNNNNNNNNNNNNNNGG ${target.fasta} > ${target.name}.locate.tsv

    read -r chrom start end name score strand < ${target.cds}

    # REVIEW D13: output is 1-based inclusive genomic coordinates of the 20-nt spacer only (PAM excluded), one row per site, sorted by start then strand
    # REVIEW D22: strand column is the strand of the target site on the genome, not the transcript strand; coordinates are always + strand
    # REVIEW D14: guide and PAM reported 5'->3' on the strand they target, upper-cased
    printf 'chrom\\tstart\\tend\\tstrand\\tguide\\tpam\\n' > ${target.name}.guides.tsv
    awk -F '\\t' -v OFS='\\t' -v chrom="\$chrom" -v offset="\$start" '
        NR == 1 { next }
        {
            hit = toupper(\$7)
            if (\$4 == "+") { gs = offset + \$5;     ge = offset + \$6 - 3 }
            else            { gs = offset + \$5 + 3; ge = offset + \$6 }
            print chrom, gs, ge, \$4, substr(hit, 1, 20), substr(hit, 21, 3)
        }' ${target.name}.locate.tsv \\
        | sort -t \$'\\t' -k2,2n -k4,4 >> ${target.name}.guides.tsv
    """

    stub:
    """
    touch ${target.name}.locate.tsv ${target.name}.guides.tsv
    """
}
