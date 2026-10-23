# Instructions for coding agents

You are helping a student build a bioinformatics workflow in Nextflow. The
student writes the specification; you generate the implementation; the student
reviews every decision you made. Your job is to make that review possible, not to
make it unnecessary.

## 1. The specification is the source of truth

`specifications.md` describes what to build.


## 2. What to generate

Implement one process per row of the spec's Pipeline Steps table, wired
according to its "Depends on" column. Use the tools and versions from the
Environment table and the resources from the Resource Requirements table.

Nextflow conventions:

- One process per module, in `modules/<tool>/main.nf`, included from `main.nf`
- Every process has a `stub:` block that creates its declared outputs, named by
  sample ID
- Resources are set by `label` and defined in `nextflow.config`, not hard-coded
  in processes
- Containers are declared per process with the `container` directive
- Parameters (input paths, reference files, `outdir`) live in the `params` block
  of `nextflow.config`
- Helper scripts live in `bin/` and are called by name

### Static typing and records

- Every `.nf` file starts with `nextflow.enable.types = true`
- Every process input and output is declared with a type (`Path`, `String`,
  `Integer`, `List<Path>`, or a record type)
- Values that travel together (a sample's name and its files, a BAM and its log)
  are a `record`, never a tuple. Define the record type in the module that
  consumes it, and refer to fields by name (`$sample.r1`), not by position
- Single outputs are named and typed; multi-file outputs are returned as a record

```groovy
nextflow.enable.types = true

record SampleRecord {
    name: String
    r1: Path
    r2: Path
}

process ALIGN {
    label 'process_high'
    container 'ghcr.io/example/star:2.7.11b'

    input:
    sample: SampleRecord
    index: Path

    output:
    record(name: sample.name, bam: file("${sample.name}.bam"), log: file("${sample.name}.Log.final.out"))

    script:
    """
    STAR --genomeDir $index --readFilesIn $sample.r1 $sample.r2 ...
    """

    stub:
    """
    touch ${sample.name}.bam ${sample.name}.Log.final.out
    """
}
```

### Workflow wiring

- Assign every process call to an explicit, descriptively named variable, and
  pass that variable downstream. Never use `PROCESS.out`, and never chain one
  process call directly into another
- Build channels from the samplesheet as records (`record(name: ..., r1: ..., r2: ...)`)
- Give intermediate channel transformations their own named variables too, so
  each step of the wiring can be read and reviewed on its own

```groovy
workflow {
    samples = channel.fromPath(params.samplesheet)
        .splitCsv(header: true)
        .map { row -> record(name: row.name, r1: file(row.r1), r2: file(row.r2)) }

    star_index = INDEX(params.genome, params.gtf)
    aligned = ALIGN(samples, star_index)
    counts = VERSE(aligned, params.gtf)

    all_counts = counts.collect()
    counts_matrix = CONCAT(all_counts)
}
```

If `specifications.md` has an **Implementation Conventions** section, it takes
precedence over the list above. Otherwise match the style of code already in the
repo.

In all cases:

- Pin every tool to the version in the Environment table — never `latest`
- Name per-sample outputs by the sample ID from the samplesheet
- Make sure `nextflow run main.nf -stub` succeeds before you report that you're done

## 3. Record every decision the spec did not make

Anything you choose that is not stated in `specifications.md` is a **decision**.
This includes:

- **Tool parameters**: any flag, option, or value, including defaults you relied
  on (strandedness, sort order, thresholds, output formats, prefixes)
- **Channel wiring**: operators you chose (`map`, `flatMap`, `join`, `collect`,
  `mix`), how samples are keyed, and in what order outputs are combined
- **Assumptions about the data**: paired vs. single end, read length, file naming,
  compression, library type, reference build
- **Resources**: anything beyond what the Resource table says
- **Deviations**: any place you did something different from the spec, and why

For each decision:

1. Assign the next free ID (`D01`, `D02`, ...). Never reuse or renumber an ID.
2. Put a marker comment where the decision lives. Use `// REVIEW D04: ...` in Nextflow
   files. Inside a `script:` block, use a bash comment (`# REVIEW D04: ...`) on
   the line above the command. Use `#` in Python, R, and shell scripts.
3. Append a block to `review/decisions.md` under **Agent decisions**, using the
   template there. Fill in only the agent fields:
   - **Step**: the step name exactly as written in the Pipeline Steps table, or
     `workflow` / `config` for wiring and configuration
   - **Unit**: the process name (e.g. `STAR_ALIGN`), or `workflow` / `config`

Every process involves at least one choice the spec does not settle (an
output name, a flag left at its default, how inputs are staged), so log at least
one decision per process. If you truly made none, add a block with
**Choice:** `none` and explain in **Why not in spec** why the spec fully
determines it.

Be specific: give the exact value you chose, the alternatives, and what would go
wrong if the choice were incorrect. If you are unsure, say so. "Standard default"
is not acceptable — name the default and where it is documented.

## 4. Things you must not do

- Do not fill in, edit, or delete any **student** fields in `review/decisions.md`
- Do not remove `REVIEW` markers; the student does that during review
- Do not edit the **Required checkpoints** section
- Do not edit `specifications.md` unless the student explicitly asks you to
- Do not run the full (non-dry-run) workflow unless asked

## 5. Regenerating after a spec change

During review the student will change `specifications.md` and ask you to
regenerate. When that happens:

- Regenerate only the parts affected by the change
- Keep existing decision IDs and all student-filled fields intact
- If a change resolves an existing decision, leave its block in place and add a
  line `- **Agent note:** superseded by spec change: <what changed>`
- Add new decisions with new IDs
