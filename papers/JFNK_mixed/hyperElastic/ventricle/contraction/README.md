# Land 2015 Problem 3 ventricle benchmark

This directory contains a minimal solids4foam case for the idealised left
ventricle configuration used for Land et al. (2015) Problem 3. The case applies
an endocardial pressure and active fibre tension to a truncated ellipsoidal
ventricle with a fixed base.

The repository stores one pristine case in `base/snes`. `Allrun` copies this
base case into `runs/meshN`, selects one of six ready-made mesh definitions,
generates the Land fibre field, and runs solids4foam. The base case is never
run in place.

## Requirements

- A configured OpenFOAM environment. `WM_PROJECT_DIR` must be set.
- A compatible solids4foam build containing the models used by this case.
- PETSc/SNES support for the mixed pressure-displacement solution.
- The `setLand2015FibreField` utility. `Allrun` builds it from
  `../setLand2015FibreField/` when it is not already on `PATH`.
- An MPI launcher is optional. If `mpirun` is available, the solver is launched
  as a one-rank MPI job; otherwise it is launched directly.
- Python 3 with ReportLab for the default final plot (and pypdf when the
  Land et al. overlay is used). `PLOT_PYTHON` selects the interpreter;
  `PLOTTER=gnuplot` or `PLOTTER=none` avoid it.

The portable source for the fibre utility is stored beside this case:

```text
../setLand2015FibreField/
```

It needs only OpenFOAM, not solids4foam. To build it by hand after sourcing
OpenFOAM:

```bash
cd ../setLand2015FibreField
wmake
cd ../contraction
```

`wmake` installs the executable in `FOAM_USER_APPBIN` according to the active
OpenFOAM environment. No local installation path is hard-coded in this case.

## Running the case

Make sure OpenFOAM and solids4foam are configured in the current shell, then
run from this directory.

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

Each selected case is created under `runs/meshN`. `Allrun` refuses to overwrite
an existing run case. Clean the previous results before repeating a level:

```bash
./Allclean
```

`Allclean` removes the complete `runs` directory while preserving `base`,
`plotScripts`, and `referenceData`.

## Mesh levels

Each mesh level is defined by a matching pair in `base/snes/system`:

```text
blockMeshDict.1       extrudeMeshDict.1
...                   ...
blockMeshDict.6       extrudeMeshDict.6
```

For each run, the selected pair is copied to the active `blockMeshDict` and
`extrudeMeshDict` before mesh generation. The nominal cell counts follow from
the block divisions multiplied by the rotational extrusion layers.

| Level | Block divisions | Extrusion layers | Cells |
|---:|:---:|---:|---:|
| 1 | `15 x 6 x 1` | 36 | 3,240 |
| 2 | `30 x 12 x 1` | 72 | 25,920 |
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
4. Runs `setLand2015FibreField` to create the transmural coordinate and fibre
   fields, including `0/f0` and `0/f0f`.
5. Runs solids4foam in serial, using one MPI rank when `mpirun` is available.

OpenFOAM utility logs and `log.solids4Foam` are written inside each
`runs/meshN` case.

## Physical and numerical setup

The geometry is a truncated ellipsoidal ventricle. The fibre utility uses the
following semi-axis dimensions:

- Endocardium: short radius 7 mm and long radius 17 mm.
- Epicardium: short radius 10 mm and long radius 20 mm.
- Fibre angle: +90 degrees at the endocardium to -90 degrees at the
  epicardium.

The basal `fixed` patch has zero displacement. The `inside` patch receives a
pressure ramp from 0 to 15 kPa over simulation time 0 to 1, while the `outside`
patch is traction-free.

The tissue uses an `electroMechanicalLaw` with a Guccione passive law. The key
case values are:

- Density: 3000 kg/m^3.
- Active tension: 60 kPa, ramped over time 0 to 1.
- Guccione parameters: `k = 2 kPa`, `cf = 8`, `ct = 2`, and `cfs = 4`.
- Bulk modulus: 160 MPa.

The solid model is nonlinear total-Lagrangian total displacement. It uses a
mixed pressure-displacement PETSc SNES solution with the options in
`petscOptions.split`. The time step is 0.01, the end time is 1, and fields are
written every 0.1 time units.

## Plotting and reference data

`Allrun` runs `extractIdealisedVentricleResults` in each `runs/meshN` directory
once the solver finishes, so every mesh level ends up with its own
`midLineDeformed.txt`. The utility is compiled from the copy in
`extractIdealisedVentricleResults/` when it is not already on the path.

After the last mesh level, the default plotter,
`../plotScripts/render_land_midline_layers.py`, draws the data layer of the
manuscript figure in the shared style and writes
`land_problem3_m3_combined_layer.pdf` here. It plots every level from 1 to 3
that has a case directory under `runs/`; each of them must have its mid-wall
file, otherwise the script stops. When fewer than the three levels of the
paper figure are present, it says so.

```bash
./Allrun plots                 # plot the existing mid-wall lines; no solver
./Allrun extract               # run the extraction utility on every completed
                               # case under runs/, then plot (needs OpenFOAM)
PLOTTER=python  ./Allrun 3     # earlier ReportLab figures, ventricleInflation-midline-*.pdf
PLOTTER=gnuplot ./Allrun 3     # plotScripts/midline.gnuplot
PLOTTER=none    ./Allrun 3     # no figure
```

A case counts as completed when `log.solids4Foam` reached `End` and every load
increment converged; `Allrun` and `./Allrun extract` stop otherwise.

The data layer is then placed over faint crops of the published
Land et al. (2015) results, giving `land_problem3_m3_combined_overlay.pdf`,
the form of the printed Figure 16. The crops are in `../referenceData/` with
their attribution and hold the published curves only. `LAND_OVERLAY_PDF=none`
skips this step; the step needs the Python package `pypdf`.

The two earlier scripts write the same `ventricleInflation-midline-*.pdf`
filenames, so only one of them runs. The gnuplot script additionally overlays
`referenceData/land3PlotData.csv` when that file is present.

## Directory layout

```text
contraction/
|-- Allrun
|-- Allclean
|-- README.md
|-- base/
|   `-- snes/
|       |-- 0/
|       |-- constant/
|       |-- system/
|       `-- petscOptions.split
|-- extractIdealisedVentricleResults/
|-- plotScripts/
|-- referenceData/
`-- runs/                 # generated by Allrun
```

Only `base`, the top-level scripts, plotting inputs, reference data, and this
README need to be version-controlled. The generated `runs` directory should
normally be excluded from commits.
