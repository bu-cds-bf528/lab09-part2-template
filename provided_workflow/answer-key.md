# synthetic.fa — all possible PAM motifs

Region: `chr1:101-210` (110 bp), transcript `Synthetic.1`, plus strand.
Local coordinates are 1-based within the extracted sequence. Genomic = local + 100.

There are 8 possible PAM motifs but only 5 reported guides. 

| PAM (local) | PAM (genomic) | Strand | Guide (local) | Guide (genomic) | Guide sequence | PAM | Case | Reported? |
|---|---|---|---|---|---|---|---|---|
| 5–7 | 105–107 | + | — | — | only 4 bp upstream | TGG | Edge, 5' end | no |
| 8–10 | 108–110 | − | 11–30 | 111–130 | `TAATAATTTATAATTATAAT` | TGG | Minus strand | yes |
| 31–33 | 131–133 | + | 11–30 | 111–130 | `ATTATAATTATAAATTATTA` | TGG | Normal | yes |
| 54–56 | 154–156 | + | 34–53 | 134–153 | `TAATTATAATTAATATTAAT` | TGG | Overlap 1/2 | yes |
| 55–57 | 155–157 | + | 35–54 | 135–154 | `AATTATAATTAATATTAATT` | GGG | Overlap 2/2 | yes |
| 78–80 | 178–180 | + | 58–77 | 158–177 | `ATTAATNTTAATTATAATTA` | TGG | Ambiguous base | no |
| 101–103 | 201–203 | + | 81–100 | 181–200 | `TATTAATTATAATTAATTAT` | agg | Soft-masked | yes |
| 104–106 | 204–206 | − | 107–126 | 207–226 | runs past region end | TGG | Edge, 3' end | no |

