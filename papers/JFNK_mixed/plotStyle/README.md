# Shared figure style and the plotting sources copied from paperData

`paper_figure_style.py` is the shared style of the paper's line figures: printed
sizes, fonts, the fixed identity of every method (colour and marker), the
labels `Coupled m = 0`, `m = 1`, `m = 2`, `JST-type`, `Rhie–Chow`,
`Cell-wise RMS` and `Maximum`, and the checks made when a figure is saved. The
case plot scripts import it; they find it by looking for a `plotStyle`
directory above their own location, or in `$JFNK_PAPER_STYLE_DIR`.

## Two copies of the plotting code

The same generators exist in two places, for two purposes.

| Place | Purpose | Input |
|---|---|---|
| this directory (`papers/JFNK_mixed`) | plot the results of new runs made with the case `Allrun` scripts | the tables and files those runs write; an input location is always given explicitly and there is no archive default |
| the paperData package (`./Allrun` there) | regenerate the published figures | the archived data of that package |

Neither route reads the other's data.

## What was copied, and from where

`paperData_sources.tsv` lists every file copied from paperData on 10 Nov 2026
with its source path and the md5 checksum the source had at that moment.

| File here | Changes made here |
|---|---|
| `plotStyle/paper_figure_style.py` | A legend that covers plotted data gives a warning instead of an error (set `JFNK_PAPER_STRICT_LEGEND=1` for the paperData behaviour). New `warn_outside_axes`: a warning when plotted points lie outside the fixed axis window of a figure |
| `fourierVerification/pressureStabilisationFourier/plotPaperFigures.py` | none |
| `fourierVerification/pressureStabilisationFourier/tableMaxErrors.py` | Default input is `postProcessing/stabilisationFourierCheck`; stops when no result file or value is found |
| `linearElastic/manufactoredSolution/plotScripts/mms_paper_figures.py` | `--data-dir` is required; stops on missing or non-finite plotted values |
| `linearElastic/manufactoredSolution/plotScripts/orderOfAccuracySlopesPressure.dat` | none (slope-guide positions, not results) |
| `linearElastic/cooksMembrane/plotScripts/plot_paper.py` | New `--results-dir`; the three input options exclude one another |
| `hyperElastic/cooksMembrane/plotScripts/plot_nonlinear_cooks.py` | No archive default; either regime can be plotted alone; `--reference-dir` for the published reference tables; stops on empty or non-finite rows |
| `hyperElastic/ventricle/beam/plotScripts/plot_land_problem1.py` | `--summary` is required; mesh level 1 is left out by its index instead of as the first row; rows are sorted by level |
| `hyperElastic/ventricle/beam/plotScripts/extract_land_problem1_reference.py` | Default directory name `referenceData` |
| `hyperElastic/ventricle/beam/referenceData/land1Data.csv`, `land_problem1_reference_stats.gp` | none |
| `hyperElastic/ventricle/plotScripts/render_land_midline_layers.py` | New `--meshes` and `--runs-subdir`; a missing mid-wall file is an error; falls back to the base-14 Helvetica when the macOS font collection is absent |
| `hyperElastic/ventricle/plotScripts/composite_land_overlay.py` | New `--write-reference`: writes the published layers of a Keynote overlay without its pasted plot; accepts such a file as `--overlay`; rejects an overlay whose pasted plot cannot be identified completely |
| `imageFigureScripts/render_field_layer.py`, `compose_field_figure.py` | none |

No numerical transformation, axis window, reference value or label was changed.
For identical input the scripts here and the paperData scripts record identical
plotted arrays (checked on 10 Nov 2026 for every generator).

## Keeping the two copies in step

```bash
scripts/checkPlotSync.py /path/to/paperData
```

reports, for every copied file, whether the paperData source still has the
recorded checksum and whether the copy here is identical or adapted. Rule:
change the style or a transformation in paperData first, then bring the change
over to the file here (keeping the adaptations in the table above) and update
the checksum in `paperData_sources.tsv`.

## Published reference data kept in this repository

| File | Content | Origin |
|---|---|---|
| `hyperElastic/ventricle/beam/referenceData/land1Data.csv` | 23 deformed tip coordinates of Land et al. (2015), problem 1 (second column, mm) | Copied from paperData (`05_heartTissueBeam/data/Landp1Data`). The file carries no participant identifiers; how the points were obtained is not recorded there |
| `hyperElastic/ventricle/beam/referenceData/land_problem1_reference_stats.gp` | Minimum 4.0247, median 4.1681 and maximum 4.1889 mm of those 23 values; no point filtered | Written by `plotScripts/extract_land_problem1_reference.py` from `land1Data.csv` |
| `hyperElastic/ventricle/contraction/referenceData/land3PlotData.csv` | 70 points of one Land et al. (2015) problem 3 curve, used by the gnuplot script only | Copied from the directory of the paper runs; how the points were obtained is not recorded |
| `hyperElastic/ventricle/referenceData/land2015_problem{2,3}_reference_layers.pdf` | Faint crops of the published Land et al. (2015) result figures for problems 2 and 3 | Separated from the Keynote overlays of paperData; attribution, licence and checks in `hyperElastic/ventricle/referenceData/README.md` |
| `hyperElastic/cooksMembrane/plotScripts/deal.II.dat`, `abaqus.dat` | Pelteret and McBride (2016) and Abaqus CPE4H results | Already in this repository |
| `linearElastic/cooksMembrane/plotScripts/Bijelona.csv` | Bijelonja et al. (2006) mesh-refinement curve | Already in this repository |

The Abaqus CPE4RH value 13.5843 mm of Figure 11 is a constant in
`plot_nonlinear_cooks.py`; no source file for it exists.
