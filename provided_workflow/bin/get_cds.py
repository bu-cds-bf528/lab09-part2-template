#!/usr/bin/env python
"""Pull the CDS (thickStart-thickEnd) of one transcript out of a UCSC BED12 file.

Writes a single BED6 line: chrom, thickStart, thickEnd, name, score, strand.
Coordinates stay 0-based, half-open, exactly as in the input BED.
"""

import argparse
import sys


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--bed", required=True, help="UCSC BED12 file")
    parser.add_argument("--transcript", required=True, help="transcript name (BED column 4)")
    parser.add_argument("--out", required=True, help="output BED6 file")
    args = parser.parse_args()

    # REVIEW D04: transcript is matched on BED column 4 by exact string equality (version suffix included)
    matches = []
    with open(args.bed) as bed:
        for line in bed:
            if not line.strip() or line.startswith(("#", "track", "browser")):
                continue
            fields = line.rstrip("\n").split("\t")
            if fields[3] == args.transcript:
                matches.append(fields)

    # REVIEW D05: zero or multiple matching rows is a hard error rather than picking one
    if len(matches) != 1:
        sys.exit(f"expected exactly 1 BED row named {args.transcript!r}, found {len(matches)}")

    chrom, strand = matches[0][0], matches[0][5]
    thick_start, thick_end = int(matches[0][6]), int(matches[0][7])

    # REVIEW D06: non-coding transcripts (thickStart == thickEnd) are rejected
    if thick_start >= thick_end:
        sys.exit(f"{args.transcript} has no CDS (thickStart={thick_start}, thickEnd={thick_end})")

    # REVIEW D07: CDS is taken as one span thickStart..thickEnd, introns included; exon blocks ignored
    with open(args.out, "w") as out:
        out.write(f"{chrom}\t{thick_start}\t{thick_end}\t{args.transcript}\t0\t{strand}\n")


if __name__ == "__main__":
    main()
