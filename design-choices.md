# Design Choices

These are some leading questions to get you thinking about what's considered
"right" and how you want this pipeline to behave. You can discuss these with
others around you, consult a LLM, or look at what established tools (ChopChop
already do to help make choices here. 

You can add these to the provided spec or your own. 

---

## 1. Region boundary semantics

**Context:** Assume we are hoping to generate a KO (generating a DSB and mutation
within an exon)

**Question:** Where does the Cas9 enzyme cut relative to the guide? Where does it
need to cut to potentially introduce the effect we want? Where is the position
of the guide relative to this?

**Specifications:** Make a choice about this behavior and encode it in your spec

---

## 2. Which interval is "the gene"

**Context:** Assume we are trying to maximize the likelihood of obtaining a true
gene knockout. 

**Question:** What do we consider to be the region of sequence corresponding to
the "gene"? How would we handle isoforms and why do we need to care about isoforms
in the first place?

**Specifications:** Make a choice about this behavior and encode it in your spec.
You can look at the default choices made by ChopChop or other guide finding
algorithms for what might be defensible

---

## 3. Overlapping matches

**Context:** PAM motifs can overlap ('GGGG')

**Question:** Do we consider both? Based on the goal of this tool, should we consider
overlapping PAM motifs?

**Spec:** Make a choice about this behavior and encode it in your spec

---

## 4. Strand representation

**Context:** The FASTA stores only the plus strand, but Cas9 can target either
strand. A guide on the minus strand is still in the file, just written the other way.

**Question:** When we report a guide's sequence, should it be the sequence as it
appears in the FASTA, or the guide as it would actually be ordered? Which way
should a correctly written guide read relative to its PAM?

**Specifications:** Make a choice about this behavior and encode it in your spec

---

## 5. Coordinate frame

**Context:** A single number describing a site's position can mean many different
things, and two pipelines can report the same site with different numbers.

**Question:** Are positions 0-based or 1-based? Genomic, or relative to the
extracted region? Do they point at the guide start, the PAM, or the cut site? For a
minus-strand site, is it the leftmost genomic base or the guide's 5' end? How would
you compare your output to ChopChop, which reports coordinates in transcript
orientation?

**Specifications:** Make a choice about this behavior and encode it in your spec

---

## 6. Soft-masked bases

**Context:** Reference genome FASTAs are soft-masked: repetitive sequence is written
in lowercase.

**Question:** Should lowercase bases be searched for guides? Will your search tool
match them by default?

**Specifications:** Make a choice about this behavior and encode it in your spec

---

## 7. Ambiguous bases

**Context:** Real chromosomes contain `N` bases, including long assembly-gap runs.

**Question:** What should happen when a guide window contains an `N`? What does your
search tool do with an `N` in the sequence, as opposed to an `N` in the pattern?
Would you be able to order that guide?

**Specifications:** Make a choice about this behavior and encode it in your spec

---

## 8. Gene name resolution

**Context:** The user asks for a gene by name, but annotations identify genes in
several ways and names are not always unique.

**Question:** Should the pipeline accept a gene name or a stable ID? What should
happen if the name appears more than once, or not at all — fail loudly or produce
empty output? Does the name in your GTF match the one ChopChop resolves?

**Specifications:** Make a choice about this behavior and encode it in your spec

---

## 9. Zero sites

**Context:** Some regions contain no valid target sites. Nextflow does not error on
an empty channel.

**Question:** If no sites are found, should the output be an empty file, a header
only, or no file at all? How would a user tell "no sites" apart from "the pipeline
silently failed"?

**Specifications:** Make a choice about this behavior and encode it in your spec

---

## 10. Chromosome naming

**Context:** Different sources name chromosomes differently (`chr21` vs `21`).

**Question:** Where do your FASTA and GTF come from, and do they agree? What should
the pipeline do if they don't?

**Specifications:** Make a choice about this behavior and encode it in your spec

---
