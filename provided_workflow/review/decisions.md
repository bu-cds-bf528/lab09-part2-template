# Review Log

Every block below needs a **Decision** and **Evidence** from you.

**Decision** is one of:

- `ACCEPT` — the choice is correct as it stands, and you are signing off on the
  choice
- `PATCH` — a small fix you make yourself. The spec does not need to say it, and
  it is not worth regenerating multiple files to fix.
- `SPECIFY` — an important enough decision that it should be in the specifications.
   Write the sentence into `specifications.md`, then have the agent update the code
   where the specs have changed.

**Evidence** is what convinced you. Acceptable evidence:

- a link to the specific section of the tool's documentation (not just the homepage)
- a command you ran and the relevant line(s) of its output
- a file you inspected (a FASTA header, a BED line, a tool's log) and what it showed

"Looks right", and "the agent chose this", are not evidence.


## How to work through this file

1. **Triage.** Read every block once. For each, ask: *if this choice were wrong,
   would the reported guides change for any input, not just this one?* If no,
   move the block to `## Dismissed` at the bottom and fill in the `Decision` and
   `Evidence`.
2. **Group what's left.** Add a `## Group: <name>` header for each set of related
   decisions and move their blocks under it. Name the group after the thing being
   decided (`## Group: quality control thresholds`), not after the
   process.
3. **Resolve each group as a unit.** Write all of its spec sentences, have the
   agent make all of its code changes at once, fill in the evidence, delete the
   `REVIEW` markers from the code, and commit the whole group as one commit.

---

## Agent decisions

AGENT: append one block per decision below this template. Fill in only the fields
above the `<!-- student -->` line.

```markdown
### <UNIT>.<slug> — <short title>

- **Step:** <step name from the Pipeline Steps table, or workflow / config>
- **Unit:** <process name, or workflow / config>
- **Location:** `<file>:<line>`
- **Choice:** <exact value/flag/operator chosen>
- **Alternatives:** <what else could have been chosen>
- **Why not in spec:** <what the spec left unstated>
- **If wrong:** <concrete consequence>
<!-- student -->
- **Decision:** ACCEPT | PATCH | SPECIFY
- **Evidence:**
```

### D01 — config.env-versions — Tool versions pinned in the env files

- **Step:** config
- **Unit:** config
- **Location:** `envs/python_env.yml:1`, `envs/seqkit_env.yml:1`, `envs/samtools_env.yml:1`
- **Choice:** Created `envs/samtools_env.yml` (`samtools=1.21`), `envs/seqkit_env.yml` (`seqkit=2.8.2`), `envs/python_env.yml` (`python=3.12`), channels `conda-forge`, `bioconda`.
- **Alternatives:** Any other release, e.g. samtools 1.20/1.22, seqkit 2.9.0/2.10.x, Python 3.11/3.13.
- **Why not in spec:** The spec names the three env files, but they did not exist and the spec gives no versions.
- **If wrong:** Reproducibility only. `samtools faidx` region extraction and `seqkit locate -d` have behaved the same across recent releases as far as I know, but I have only checked the pinned versions (samtools 1.21, seqkit v2.8.2 both resolved and ran on the synthetic data).
<!-- student -->
- **Decision:** ACCEPT | PATCH | SPECIFY
- **Evidence:**

### D02 — workflow.conda-not-container — Conda env per process instead of a `container` directive

- **Step:** workflow
- **Unit:** SAMTOOLS_FAIDX, GET_CDS, SAMTOOLS_EXTRACT, SEQKIT_LOCATE
- **Location:** `modules/samtools_faidx/main.nf:5`, `modules/samtools_extract/main.nf:10`, `modules/seqkit_locate/main.nf:11`, `modules/get_cds/main.nf:5`
- **Choice:** `conda "${projectDir}/envs/<tool>_env.yml"` in every module; no `container` directive.
- **Alternatives:** A pinned BioContainers image per process (e.g. `quay.io/biocontainers/samtools:1.21--...`), or both conda and container with a profile switch.
- **Why not in spec:** AGENTS.md asks for `container` per process, but the spec's Environment section names conda env files. I treated the spec as the source of truth. This is a deviation from the AGENTS.md convention.
- **If wrong:** If the grading or cluster environment expects containers (Docker/Singularity) the pipeline will not use them, and tool resolution depends on the conda solver at run time.
<!-- student -->
- **Decision:** ACCEPT | PATCH | SPECIFY
- **Evidence:**

### D03 — workflow.provided-steps — No process for the 'Provided' rows

- **Step:** Get genome
- **Unit:** workflow
- **Location:** `main.nf:9`
- **Choice:** `Get genome` and `Choose transcript` (Tool = Provided) are implemented as `params.genome` and `params.transcript`, not as processes.
- **Alternatives:** A trivial process per row that just stages/echoes the input, to match 'one process per row' literally.
- **Why not in spec:** AGENTS.md says one process per Pipeline Steps row; the spec marks these two rows as Provided with no input or output.
- **If wrong:** None for the guides. Only matters if you expect a process to exist for every table row.
<!-- student -->
- **Decision:** ACCEPT | PATCH | SPECIFY
- **Evidence:**

### D04 — GET_CDS.transcript-match — Transcript matched exactly on BED column 4

- **Step:** Get cds
- **Unit:** GET_CDS
- **Location:** `bin/get_cds.py:19`
- **Choice:** Row selected where column 4 `==` `params.transcript`, exact and case-sensitive, version suffix included (e.g. `ENST00000456328.2` will not match `ENST00000456328`).
- **Alternatives:** Match ignoring the version suffix; match on a gene name; case-insensitive match.
- **Why not in spec:** The spec says 'a transcript specified as a string' but not which BED field it must match or how strictly.
- **If wrong:** If the config string omits or differs in the version suffix, GET_CDS exits with 'found 0' and the run fails (it will not silently pick the wrong transcript).
<!-- student -->
- **Decision:** ACCEPT | PATCH | SPECIFY
- **Evidence:**

### D05 — GET_CDS.match-count — Zero or multiple matching rows is an error

- **Step:** Get cds
- **Unit:** GET_CDS
- **Location:** `bin/get_cds.py:29`
- **Choice:** `sys.exit` with a message unless exactly one BED row matches.
- **Alternatives:** Take the first match; merge multiple rows; warn and continue.
- **Why not in spec:** The spec does not say what happens if the transcript is missing or duplicated in the BED.
- **If wrong:** If your BED legitimately repeats a transcript name (e.g. PAR copies on chrX/chrY in GENCODE), the run fails instead of choosing one.
<!-- student -->
- **Decision:** ACCEPT | PATCH | SPECIFY
- **Evidence:**

### D06 — GET_CDS.noncoding — Non-coding transcripts rejected

- **Step:** Get cds
- **Unit:** GET_CDS
- **Location:** `bin/get_cds.py:36`
- **Choice:** Exit with an error if `thickStart >= thickEnd`.
- **Alternatives:** Fall back to the whole transcript span (`chromStart`-`chromEnd`).
- **Why not in spec:** The spec says to use the CDS start and end; it does not say what to do when there is no CDS. `data/README.md` notes `thickStart == thickEnd` means non-coding.
- **If wrong:** Choosing a non-coding transcript gives a failed run rather than guides over the transcript body.
<!-- student -->
- **Decision:** ACCEPT | PATCH | SPECIFY
- **Evidence:**

### D07 — GET_CDS.cds-span — CDS = one continuous span, introns included

- **Step:** Get cds
- **Unit:** GET_CDS
- **Location:** `bin/get_cds.py:40`
- **Choice:** Region is `thickStart`..`thickEnd` as a single interval; BED12 blocks (columns 10-12) are ignored.
- **Alternatives:** Intersect thickStart..thickEnd with the exon blocks and search each coding exon separately (guides inside introns excluded).
- **Why not in spec:** The spec says 'the search should use the cds start and end', which I read as the thickStart/thickEnd span. `data/README.md` points out this span includes introns.
- **If wrong:** For multi-exon genes, guides that sit in introns are reported, and guides that span an exon-exon junction in the mRNA are not relevant anyway (genomic search). ChopChop's CDS mode targets coding exons only, so for real genes the counts will differ from ChopChop. For the single-exon synthetic transcript it makes no difference. I think this is likely the most important decision to check against the success criteria.
<!-- student -->
- **Decision:** ACCEPT | PATCH | SPECIFY
- **Evidence:**

### D08 — SAMTOOLS_FAIDX.output — FASTA and .fai emitted together as a record

- **Step:** Index Genome
- **Unit:** SAMTOOLS_FAIDX
- **Location:** `modules/samtools_faidx/main.nf:12`
- **Choice:** `samtools faidx <genome>` with no options; output `record(fasta, fai)` where `fai` is `<genome filename>.fai`.
- **Alternatives:** Emit only the `.fai` and pass the FASTA separately from params; build a `.gzi` for bgzipped input.
- **Why not in spec:** The spec gives 'fasta + fai' as the output but not how they are packaged. It also does not say whether the genome may be gzipped; I assumed uncompressed (or bgzipped, which samtools handles but which I have not tested).
- **If wrong:** Plain gzip (not bgzip) genomes will fail at `samtools faidx`.
<!-- student -->
- **Decision:** ACCEPT | PATCH | SPECIFY
- **Evidence:**

### D09 — GET_CDS.output-format — CDS region written as BED6 file

- **Step:** Get cds
- **Unit:** GET_CDS
- **Location:** `modules/get_cds/main.nf:13`
- **Choice:** One line `chrom\tthickStart\tthickEnd\tname\t0\tstrand`, 0-based half-open, file `<transcript>.cds.bed`.
- **Alternatives:** Write a samtools region string (`chr1:101-210`); emit chrom/start/end as values instead of a file.
- **Why not in spec:** The spec says the output is 'Chr + start and stop' but not the format or coordinate system.
- **If wrong:** Downstream steps assume 0-based starts (D10 adds 1, D13 adds offsets). If this file were 1-based, every coordinate would be off by one.
<!-- student -->
- **Decision:** ACCEPT | PATCH | SPECIFY
- **Evidence:**

### D10 — SAMTOOLS_EXTRACT.region — 0-based BED start converted to 1-based region; + strand only

- **Step:** Extract the sequence
- **Unit:** SAMTOOLS_EXTRACT
- **Location:** `modules/samtools_extract/main.nf:26`
- **Choice:** `samtools faidx <fasta> "${chrom}:$((start + 1))-${end}"`; default 60-column line wrapping; no `-i` (no reverse complement), even for minus-strand transcripts. Output `<transcript>.cds.fa`, header `chr1:101-210`.
- **Alternatives:** Use `-i` for minus-strand transcripts; use `--region-file`; `-n 0` for unwrapped output.
- **Why not in spec:** The spec does not give the coordinate conversion or say which strand to extract.
- **If wrong:** Off-by-one here shifts every reported coordinate by 1 and changes which PAMs are in range. Checked for synthetic.1: BED `100 210` -> `chr1:101-210`, which matches `data/README.md`. Extracting + strand only is fine because D12 searches both strands.
<!-- student -->
- **Decision:** ACCEPT | PATCH | SPECIFY
- **Evidence:**

### D11 — SAMTOOLS_EXTRACT.passthrough — CDS BED travels with the extracted sequence

- **Step:** Extract the sequence
- **Unit:** SAMTOOLS_EXTRACT
- **Location:** `modules/samtools_extract/main.nf:19`
- **Choice:** Output `record(name: transcript, fasta: <transcript>.cds.fa, cds: <transcript>.cds.bed)`; the CDS BED is re-emitted so SEQKIT_LOCATE can read chrom and offset from it.
- **Alternatives:** Pass GET_CDS output to SEQKIT_LOCATE as a second input; parse the offset from the FASTA header `chr1:101-210`.
- **Why not in spec:** The spec does not say how 'genomic coordinates' get back to the locate step.
- **If wrong:** Wiring only. If the wrong BED were paired with a FASTA the coordinates would be wrong, but with one transcript per run (D15) there is only one pair.
<!-- student -->
- **Decision:** ACCEPT | PATCH | SPECIFY
- **Evidence:**

### D12 — SEQKIT_LOCATE.pattern — Target = 20-nt spacer + NGG, both strands, overlaps kept

- **Step:** Find target sites
- **Unit:** SEQKIT_LOCATE
- **Location:** `modules/seqkit_locate/main.nf:22`
- **Choice:** `seqkit locate -i -d -p NNNNNNNNNNNNNNNNNNNNNGG` (21 N + GG). Both strands (seqkit default; `-P`/`--only-positive-strand` not set). Greedy mode (default; `-G`/`--non-greedy` not set), so overlapping sites are all reported. `-i` makes soft-masked lowercase bases match.
- **Alternatives:** Spacer length 19-21 or species-specific; plus strand only (`-P`); search the PAM `NGG` alone and compute guides separately; non-greedy mode.
- **Why not in spec:** The spec says 'NGG' but not the guide length, which strands to search, case handling, or overlapping sites.
- **If wrong:** Wrong spacer length changes every guide sequence and drops/adds sites near the CDS edges. Plus-strand-only would roughly halve the count. Checked on synthetic data: an overlapping test `A21GGGG` returned 3 hits; the synthetic CDS returns 5 sites (4 +, 1 -), including the lowercase `agg` at chr1:201-203.
<!-- student -->
- **Decision:** ACCEPT | PATCH | SPECIFY
- **Evidence:**

### D13 — SEQKIT_LOCATE.output — Output table: spacer-only, 1-based inclusive coordinates

- **Step:** Find target sites
- **Unit:** SEQKIT_LOCATE
- **Location:** `modules/seqkit_locate/main.nf:28`
- **Choice:** `<transcript>.guides.tsv` with header `chrom start end strand guide pam`. start/end are 1-based inclusive genomic coordinates of the 20-nt spacer, PAM excluded: + strand `start = offset + s`, `end = offset + e - 3`; - strand `start = offset + s + 3`, `end = offset + e`, where offset = thickStart and s/e are seqkit's 1-based positions. Sorted by start, then strand. The raw seqkit output `<transcript>.locate.tsv` stays in the task work directory and is not published.
- **Alternatives:** BED (0-based half-open) coordinates; include the PAM in the interval; report the cut site; ChopChop-style `chr:pos` column.
- **Why not in spec:** The spec says 'the chromosome, and the start and stop of the guide' but not the coordinate system or whether the PAM is part of the guide.
- **If wrong:** Comparisons with ChopChop will be off by 1 (coordinate system) or by 3 (PAM included or not) if this does not match what you compare against. Spot-checked: `samtools faidx synthetic.fa chr1:111-130` = `ATTATAATTATAAATTATTA`, the reported + guide.
<!-- student -->
- **Decision:** ACCEPT | PATCH | SPECIFY
- **Evidence:**

### D14 — SEQKIT_LOCATE.guide-orientation — Guide/PAM reported 5'->3' on target strand, upper-cased

- **Step:** Find target sites
- **Unit:** SEQKIT_LOCATE
- **Location:** `modules/seqkit_locate/main.nf:30`
- **Choice:** `guide` = first 20 nt and `pam` = last 3 nt of seqkit's `matched` column (which seqkit gives in the orientation of the matched strand), passed through `toupper`.
- **Alternatives:** Report everything on the + strand; keep original case (soft-masking).
- **Why not in spec:** The spec asks for 'guide sequences' without orientation or case.
- **If wrong:** Minus-strand guides would be reverse-complemented incorrectly if seqkit's orientation were different. Checked: `samtools faidx -i synthetic.fa chr1:111-130` = `TAATAATTTATAATTATAAT`, the reported - guide.
<!-- student -->
- **Decision:** ACCEPT | PATCH | SPECIFY
- **Evidence:**

### D15 — workflow.single-values — Inputs as single values, not channels

- **Step:** workflow
- **Unit:** workflow
- **Location:** `main.nf:10`
- **Choice:** `file(params.genome)`, `file(params.bed)`, `params.transcript` passed directly to processes; no samplesheet, no `map`/`join`/`collect`.
- **Alternatives:** A channel of transcripts (e.g. `channel.of(params.transcript.split(','))`) to run several at once.
- **Why not in spec:** The spec puts multiple genomes/genes out of scope but does not say how inputs are wired.
- **If wrong:** Running several transcripts needs rewiring (and pairing of FASTA with BED per transcript).
<!-- student -->
- **Decision:** ACCEPT | PATCH | SPECIFY
- **Evidence:**

### D16 — config.default-params — Default params point at synthetic data

- **Step:** config
- **Unit:** config
- **Location:** `nextflow.config:2`
- **Choice:** `params.genome = data/synthetic.fa`, `params.bed = data/synthetic.bed`, `params.transcript = 'synthetic.1'`, `params.outdir = results`.
- **Alternatives:** No defaults (require them on the command line); defaults for the real biological data.
- **Why not in spec:** The spec says the transcript is set in the config but does not give a value or default paths.
- **If wrong:** Running without overrides analyses the synthetic data; override with `--genome`, `--bed`, `--transcript` for the real data.
<!-- student -->
- **Decision:** ACCEPT | PATCH | SPECIFY
- **Evidence:**

### D17 — config.conda-enabled — Conda turned on globally

- **Step:** config
- **Unit:** config
- **Location:** `nextflow.config:9`
- **Choice:** `conda.enabled = true` at top level, not inside a profile.
- **Alternatives:** A `conda` profile (`-profile conda`); containers instead (see D02).
- **Why not in spec:** The spec names conda env files but not how they are activated.
- **If wrong:** Every run, including `-stub`, builds the envs under `work/conda` (needs network on first run). Systems without conda cannot run the pipeline.
<!-- student -->
- **Decision:** ACCEPT | PATCH | SPECIFY
- **Evidence:**

### D18 — config.resources — Resource label values

- **Step:** config
- **Unit:** config
- **Location:** `nextflow.config:13`
- **Choice:** One label, `process_single`: `cpus = 1`, `memory = 2.GB`, `time = 1.h`, used by all four processes.
- **Alternatives:** Separate labels per tool; more memory for faidx on a large genome.
- **Why not in spec:** The spec says 'Labels in nextflow.config' with no label names or values.
- **If wrong:** If a scheduler enforces limits, 2 GB / 1 h is enough for faidx on chr-sized or human-sized FASTA in my experience, but I have not measured it.
<!-- student -->
- **Decision:** ACCEPT | PATCH | SPECIFY
- **Evidence:**

### D19 — config.publishdir — Publishing outputs

- **Step:** config
- **Unit:** config
- **Location:** `nextflow.config:20`
- **Choice:** `publishDir` for every process to `${params.outdir}/<process name lowercase>`, `mode: 'copy'`. Includes the copied genome FASTA and `.fai` from SAMTOOLS_FAIDX, and a second copy of `<transcript>.cds.bed` under `samtools_extract/` (from the D11 pass-through).
- **Alternatives:** Publish only the final guides table; `mode: 'symlink'`; the workflow `output {}` block.
- **Why not in spec:** The spec lists the outputs per gene but not where they are written.
- **If wrong:** Copying the genome into `results/samtools_faidx/` duplicates a potentially large file.
<!-- student -->
- **Decision:** ACCEPT | PATCH | SPECIFY
- **Evidence:**

### D20 — SAMTOOLS_EXTRACT.no-flank — No flanking sequence around the CDS

- **Step:** Extract the sequence
- **Unit:** SAMTOOLS_EXTRACT
- **Location:** `modules/samtools_extract/main.nf:25`
- **Choice:** Only bases thickStart+1..thickEnd are extracted. A site is reported only if all 23 nt (spacer + PAM) are inside the CDS.
- **Alternatives:** Extract the CDS plus 20-23 nt on each side so PAMs near the CDS edge still get a full spacer, keeping only sites whose cut site (or PAM, or spacer) overlaps the CDS.
- **Why not in spec:** The spec says the search uses the CDS start and end, but not how sites overlapping the boundary are treated.
- **If wrong:** Sites near the ends are dropped. In synthetic.1, the `GG` at chr1:105-106 and the `CC` at chr1:204-205 have no full spacer inside the CDS and are not reported. ChopChop uses flanking genome sequence, so its counts may be higher. Likely to matter for the success criteria.
<!-- student -->
- **Decision:** ACCEPT | PATCH | SPECIFY
- **Evidence:**

### D21 — SEQKIT_LOCATE.ambiguous-bases — Sites containing N are dropped

- **Step:** Find target sites
- **Unit:** SEQKIT_LOCATE
- **Location:** `modules/seqkit_locate/main.nf:23`
- **Choice:** Rely on `seqkit locate -d`, where `N` in the pattern matches only A/C/G/T, so any 23-mer containing an `N` (or other IUPAC code) in the genome is not reported.
- **Alternatives:** Allow N in the spacer; allow N only as the PAM's first base.
- **Why not in spec:** The spec does not say how to handle ambiguous bases in the genome.
- **If wrong:** synthetic.fa has an `N` at chr1:164; no candidate site containing it is reported. Checked: `printf '>t\nAAAAAAAAANAAAAAAAAAAAGG\n' | seqkit locate -i -d -p N{21}GG` returns no hits.
<!-- student -->
- **Decision:** ACCEPT | PATCH | SPECIFY
- **Evidence:**

### D22 — SEQKIT_LOCATE.strand-semantics — Strand column = target strand on the genome

- **Step:** Find target sites
- **Unit:** SEQKIT_LOCATE
- **Location:** `modules/seqkit_locate/main.nf:29`
- **Choice:** `strand` is `+` for NGG on the reference + strand and `-` for CCN on the + strand (NGG on the - strand), regardless of the transcript's strand. start/end are always + strand genomic coordinates with start < end.
- **Alternatives:** Report strand relative to the transcript (sense/antisense); give minus-strand coordinates as start > end.
- **Why not in spec:** The spec does not say which strand the strand column refers to.
- **If wrong:** For a minus-strand transcript, users may read `+` as 'sense' when it is antisense to the gene.
<!-- student -->
- **Decision:** ACCEPT | PATCH | SPECIFY
- **Evidence:**
