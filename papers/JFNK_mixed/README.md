# Benchmark cases for the mixed pressure-displacement JFNK paper

Top-level driver for every benchmark case reported in

> A. Mullen-Hales, P. Cardiff and P. Castrillo,
> *Algebraically Monolithic Methods for Mixed Solid Mechanics*

Each case keeps its own `Allrun`, `Allclean`, base case, mesh definitions and
plot scripts. The scripts in this directory only

1. run each case's own `Allrun` with the mesh sequence used in the paper,
2. copy the resulting plots into `figures/`, and
3. assemble those plots into a single PDF with a heading above the figures of
   each test case.

## Usage

Source the OpenFOAM and solids4foam environment first, then:

```bash
./Allrun          # every case, using the paper mesh sequences
./AllrunTest      # short verification run on the first one or two meshes
./Allclean        # remove every generated run, figure and log
```

Useful options:

```bash
./Allrun --list                 # cases and the mesh sequence each will use
./Allrun beam inflation         # only the named cases
./Allrun --figures-only         # re-collect figures and rebuild the PDF
./Allrun --stop-on-error        # stop at the first failing case
```

By default a failing case is reported and the run continues, so a long
overnight run still produces every figure that did complete.

The beam, inflation and contraction cases refuse to overwrite an existing
`runs/meshN` directory, so run `./Allclean` before repeating a run.

## Cases and mesh counts

| Case | Directory | Paper section | Meshes, `./Allrun` | Meshes, `./AllrunTest` |
|---|---|---|---|---|
| `mms` | `linearElastic/manufactoredSolution` | 5.1 | 1-6 | 1-2 |
| `linearCooks` | `linearElastic/cooksMembrane` | 5.2 | 1-6 | 1-2 |
| `nonlinearCooksCompressible` | `hyperElastic/cooksMembrane` | 5.3.1 | 1-8 | 1-2 |
| `nonlinearCooksIncompressible` | `hyperElastic/LargeStrainIncompCooksMembrane` | 5.3.2 | 1-8 | 1-2 |
| `beam` | `hyperElastic/ventricle/beam` | 5.4 | levels 2-6 | levels 1-2 |
| `inflation` | `hyperElastic/ventricle/inflation` | 5.5 | 1-3 | 1 |
| `contraction` | `hyperElastic/ventricle/contraction` | 5.6 | 1-3 | 1 |

The full mesh counts are those the paper reports:

* **Manufactured solution**: six meshes, initial spacing `h = 0.04 m` halved
  each level, matching the 1 mm to 50 mm axis of Figures 2 and 3.
* **Linear Cook's membrane**: six meshes, `3x3` to `96x96` cells in plane.
* **Nonlinear Cook's membrane** (both compressibility regimes): eight meshes.
  The mesh-1 spacing is 12.649 mm, so mesh 8 reaches the 0.098 mm left-hand
  limit of the axis in Figures 8(b) and 9.
* **Heart tissue beam**: five meshes. Figure 11 spans cell sizes 0.5 mm to
  0.03125 mm, which are levels 2 to 6 of the seven the case defines; level 1
  (10 cells) is not part of that figure. Override with
  `BEAM_MESH_LEVELS="1 2 3 4 5 6" ./Allrun beam` if all seven levels are
  wanted.
* **LV inflation**: three meshes, 1,620 / 12,960 / 103,680 control volumes.
* **LV active contraction**: three meshes, 3,240 / 25,920 / 103,680 control
  volumes.

## Output

```text
figures/
|-- 01_mms/                             # copies of each case's plots
|-- 02_linearCooks/
|-- ...
|-- manifest.tsv                        # heading and caption of every figure
`-- JFNK_mixed_paperFigures.pdf         # all figures, grouped under headings
logs/
`-- <case>.log                          # full console output of each case
```

The combined PDF is built by `scripts/combineFigures.py`. It uses `pdflatex`
when available, which keeps the figures vector, and otherwise falls back to
rasterising them with Ghostscript and laying them out with ReportLab.

## Requirements

* A configured OpenFOAM environment and a compatible solids4foam build with
  PETSc/SNES support.
* `python3` with ReportLab, `gnuplot`, and `gmsh` for the polyhedral and
  unstructured mesh families.
* `pdflatex` for the vector combined PDF, or Ghostscript for the raster
  fallback.
