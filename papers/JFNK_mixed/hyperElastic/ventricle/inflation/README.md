# Land 2015 Problem 2 ventricle benchmark

This directory contains a minimal solids4foam case for the passive inflation
of the idealised left ventricle in Land et al. (2015) Problem 2. An
endocardial pressure inflates a truncated ellipsoidal ventricle whose base is
fixed.

The repository stores one pristine case in `base/snes`. `Allrun` copies this
base case into `runs/meshN`, selects one of six ready-made mesh definitions,
and runs solids4foam. The base case is never run in place.

## Requirements

- A configured OpenFOAM environment. `WM_PROJECT_DIR` must be set.
- A compatible solids4foam build containing the models used by this case.
- PETSc/SNES support for the mixed pressure-displacement solution.
- An MPI launcher is optional. If `mpirun` is available, the solver is
  launched as a one-rank MPI job; otherwise it is launched directly.
- Python 3 with ReportLab for the default final plot. Set `PLOTTER=gnuplot`
  to use the supplied gnuplot script instead, or `PLOTTER=none` to skip plots.
  If needed, `PLOT_PYTHON` can select a Python interpreter that has ReportLab
  (and pypdf when the Land et al. overlay is used).

No local OpenFOAM installation path is hard-coded in the case.

## Running the case

After configuring OpenFOAM and solids4foam in the current shell, run from this
directory.

Run the coarsest mesh only:

```bash
./Allrun
```

Run the first three mesh levels:

```bash
./Allrun 3
```

The numerical argument means "run levels 1 through N". Therefore,
`./Allrun 6` runs all six available levels sequentially.

Run a specific selection of mesh levels:

```bash
MESH_LEVELS="2 4 6" ./Allrun
```

Show the command-line help:

```bash
./Allrun --help
```

Each selected case is created under `runs/meshN`. `Allrun` refuses to
overwrite an existing run case. Clean previous results before repeating a
level:

```bash
./Allclean
```

`Allclean` removes the complete `runs` directory while preserving `base` and
`plotScripts`.

## Mesh levels

Each level is defined by a matching pair in `base/snes/system`:

```text
blockMeshDict.1       extrudeMeshDict.1
...                   ...
blockMeshDict.6       extrudeMeshDict.6
```

For each run, the selected pair is copied to the active `blockMeshDict` and
`extrudeMeshDict` before mesh generation.

| Level | Block divisions | Extrusion layers | Cells |
|---:|:---:|---:|---:|
| 1 | `15 x 3 x 1` | 36 | 1,620 |
| 2 | `30 x 6 x 1` | 72 | 12,960 |
| 3 | `60 x 12 x 1` | 144 | 103,680 |
| 4 | `120 x 24 x 1` | 288 | 829,440 |
| 5 | `240 x 48 x 1` | 576 | 6,635,520 |
| 6 | `480 x 96 x 1` | 1,152 | 53,084,160 |

Levels 5 and 6 require substantial memory, storage, and runtime. Select mesh
levels appropriate for the available machine.

## What `Allrun` does

For every selected level, `Allrun`:

1. Copies `base/snes` to `runs/meshN`.
2. Activates `blockMeshDict.N` and `extrudeMeshDict.N`.
3. Runs `blockMesh`, `extrudeMesh`, and `createPatch -overwrite`.
4. Runs solids4foam in serial, using one MPI rank when `mpirun` is available.
5. Runs `extractIdealisedVentricleResults` inside the completed case, producing
   `runs/meshN/midLineDeformed.txt`.

After all selected levels finish, `Allrun` returns to this `inflation`
directory and runs the Python plot script. If the extraction utility is not
already installed in the configured OpenFOAM environment, `Allrun` builds the
copy in `extractIdealisedVentricleResults/` with `wmake` first.

OpenFOAM utility logs and `log.solids4Foam` are written inside each
`runs/meshN` case.

Unlike Problem 3, this passive isotropic case does not need the
`setLand2015FibreField` preprocessing utility. The base nevertheless includes
uniform `0/f0` and `0/f0f` files: the enclosing `electroMechanicalLaw` reads
both fields even when active tension is zero. The `uniformFibreField yes`
setting applies to the nested passive Guccione law and does not remove that
outer-law input requirement.

## Physical and numerical setup

The basal `fixed` patch has zero displacement. The endocardial `inside` patch
receives a pressure ramp from 0 to 10 kPa over simulation time 0 to 1, while
the epicardial `outside` patch is traction-free.

The tissue uses an `electroMechanicalLaw` with zero active tension and a
Guccione passive law with an isotropic parameter choice. The key values are:

- Density: 3000 kg/m^3.
- Active tension: 0 Pa.
- Guccione parameters: `k = 10 kPa`, `cf = 1`, `ct = 1`, and `cfs = 1`.
- Bulk modulus: 1 MPa.
- Uniform fibre direction: `(0 0 1)`; it does not affect this isotropic case.

The solid model is nonlinear total-Lagrangian total displacement. It uses a
mixed pressure-displacement PETSc SNES solution with the working
`petscOptions.split` configuration. The time step is 0.01, the end time is 1,
and fields are written every 0.1 time units.

The calculation is quasi-static. `system/fvSchemes` sets
`d2dt2Schemes default steadyState`, so the inertial term is absent from the
momentum residual, from the approximate Jacobian and from the pressure
stabilisation weighting; the 100 time steps are 100 equal load increments.
`ddtSchemes default backward` is retained: no damping is set in
`constant/solidProperties` (`dampingCoeff` defaults to zero), so the first time
derivative does not enter the equilibrium residual and is used only by the
load-increment predictor (`predictor yes`), which requires a non-steady `ddt`
scheme. The density is consequently inactive in the solved equations.

## Plotting

`Allrun` plots automatically once the selected levels have finished. The
default plotter, `../plotScripts/render_land_midline_layers.py`, draws the data
layer of the manuscript figure in the shared style from
`runs/mesh{1,2,3}/midLineDeformed.txt` and writes
`land_problem2_m3_combined_layer.pdf` here. It plots every level from 1 to 3
that has a case directory under `runs/`; each of them must have its mid-wall
file, otherwise the script stops. When fewer than the three levels of the
paper figure are present, it says so. Levels 4 to 6 are not part of the
figure.

```bash
./Allrun plots                 # plot the existing mid-wall lines; no solver
./Allrun extract               # run the extraction utility on every completed
                               # case under runs/, then plot (needs OpenFOAM)
PLOT_MESH_LEVELS="1 2" ./Allrun plots   # explicit selection
PLOTTER=python ./Allrun 3      # earlier ReportLab figure, land_problem2_m3_combined.pdf
PLOTTER=gnuplot ./Allrun 3     # midline.pdf, midline_apex.pdf, midline_inflection.pdf
PLOTTER=none ./Allrun 3        # no figure
```

A case counts as completed when `log.solids4Foam` reached `End` and every load
increment converged; `Allrun` and `./Allrun extract` stop otherwise.

The data layer is then placed over faint crops of the published
Land et al. (2015) results, giving `land_problem2_m3_combined_overlay.pdf`,
the form of the printed Figure 15. The crops are in `../referenceData/` with
their attribution and hold the published curves only. `LAND_OVERLAY_PDF=none`
skips this step; the step needs the Python package `pypdf`.

All paths are derived from the location of the scripts, so the repository can
be moved or cloned to a different directory without editing paths.

## Directory layout

```text
inflation/
|-- Allrun
|-- Allclean
|-- README.md
|-- extractIdealisedVentricleResults/
|-- base/
|   `-- snes/
|       |-- 0/
|       |-- constant/
|       |-- system/
|       `-- petscOptions.split
|-- plotScripts/
`-- runs/                 # generated by Allrun
```

Only `base`, the top-level scripts, plotting inputs, and this README need to be
version-controlled. The generated `runs` directory should normally be excluded
from commits.
