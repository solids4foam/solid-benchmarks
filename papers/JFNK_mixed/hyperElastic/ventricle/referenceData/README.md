# Published reference layers for the ventricular mid-wall figures

| File | Used for |
|---|---|
| `land2015_problem2_reference_layers.pdf` | inflation, manuscript Figure 15 |
| `land2015_problem3_reference_layers.pdf` | active contraction, manuscript Figure 16 |

Each file holds faint crops of the published result figures for the problem
(deformed mid-wall line with its apical and inflection magnifications, all
benchmark participants) on a white page. `../plotScripts/composite_land_overlay.py`
places the data layer of a new run over them.

## Attribution

The crops are taken from

> S. Land, V. Gurev, S. Arens, C. M. Augustin, L. Baron, R. Blake, C. Bradley,
> S. Castro, A. Crozier, M. Favino, T. E. Fastl, T. Fritz, H. Gao, A. Gizzi,
> B. E. Griffith, D. E. Hurtado, R. Krause, X. Luo, M. P. Nash, S. Pezzuto,
> G. Plank, S. Rossi, D. Ruprecht, G. Seemann, N. P. Smith, J. Sundnes,
> J. J. Rice, N. Trayanova, D. Wang, Z. J. Wang and S. A. Niederer (2015).
> Verification of cardiac mechanics software: benchmark problems and solutions
> for testing active and passive material behaviour. *Proceedings of the Royal
> Society A* 471 (2184), 20150641. doi:10.1098/rspa.2015.0641

© 2015 The Authors. Published by the Royal Society under the terms of the
Creative Commons Attribution License, http://creativecommons.org/licenses/by/4.0/.
Changes made: the figures were cropped, drawn with reduced opacity and
arranged on one page (arrangement by P. Cardiff).

## How the files were made

The manuscript figures were composed in Keynote: the crops, and on top of them
the vector plot of the paper's own results. The two files here are those
Keynote exports with every pasted group of the paper's own plot removed and
nothing added:

```bash
../plotScripts/composite_land_overlay.py --problem 2 \
    --overlay land_problem2_m3_combined_overlay_original_keynote.pdf \
    --write-reference land2015_problem2_reference_layers.pdf
../plotScripts/composite_land_overlay.py --problem 3 \
    --overlay land_problem3_m3_combined_overlay_original_keynote.pdf \
    --write-reference land2015_problem3_reference_layers.pdf
```

| File | From (paperData package) | md5 of the source | Groups removed | md5 of the file here |
|---|---|---|---|---|
| `land2015_problem2_reference_layers.pdf` | `06_lvInflation/data/land_problem2_m3_combined_overlay_original_keynote.pdf` | `7aa18918d09ee4e87da60c9c58bd90ed` | 39 (3 copies of 13) | `4b1278d6327c6a30fd38bc996fa2201d` |
| `land2015_problem3_reference_layers.pdf` | `07_lvContraction/data/land_problem3_m3_combined_overlay_original_keynote.pdf` | `b45e0d0423c4d244ce7d577c7832e5e8` | 13, and two hand-typed tick labels | `343d7c334bfacf5bf3dae6048ada8355` |

Checked on 10 Nov 2026: the page content of each file is the white background
and the three reference layers only; no stream of the files holds a plotted
curve of the paper; rendered at 100 dpi the files have no pixel darker than
90/255, whereas the Keynote export of problem 2 has 7,682; a composite made
from a file here and one made from the Keynote export with the same data
layer are identical pixel for pixel.

The files contain no simulation result of the paper. The published curves were
not redrawn or digitised: they are the original crops.
