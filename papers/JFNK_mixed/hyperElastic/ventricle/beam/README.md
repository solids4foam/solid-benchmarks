# Land 2015 Problem 1 beam benchmark

This directory contains a minimal solids4foam case for Problem 1 from Land et
al. (2015). It models a 10 mm long, 1 mm square cantilever beam. The left end
is fixed and a pressure of 4 Pa is applied to the bottom surface, bending the
beam. The displacement monitored for the mesh study is at the upper tip,
`(10, 0.5, 1)` mm.

One pristine case is stored in `base/snes`. `Allrun` copies that case to
`runs/meshN`, activates the requested ready-made `blockMeshDict.N`, creates the
mesh, and runs solids4foam. The base case is never run in place.

## Requirements

- A configured OpenFOAM environment with `WM_PROJECT_DIR` set.
- A compatible solids4foam build.
- PETSc/SNES support for the mixed pressure-displacement solution.
- An MPI launcher is needed only when explicitly requesting a one-rank MPI
  launch with `USE_MPI=true`.
- Python 3 and ReportLab are needed to create the convergence plot
  automatically. A gnuplot version of the plot is also available.

There are no local-machine paths or operating-system-specific library names in
the case.

## Running

From this directory, after sourcing the OpenFOAM and solids4foam environment:

```bash
./Allrun
```

With no argument, only mesh level 1 is run. To run levels 1 through 4:

```bash
./Allrun 4
```

To run all seven levels:

```bash
./Allrun 7
```

The default launch is direct serial execution. If the local PETSc setup
requires an MPI launcher, use:

```bash
USE_MPI=true ./Allrun 3
```

A specific selection can be requested through `MESH_LEVELS`:

```bash
MESH_LEVELS="2 4 6" ./Allrun
```

Show the available options with `./Allrun --help`. A selected case is created
under `runs/meshN`. Existing mesh directories are not overwritten; use:

```bash
./Allclean
```

to remove generated cases, the displacement summary, and plot output while
preserving the base and plot script.

## Meshes

The beam is generated directly by `blockMesh`; unlike Problems 2 and 3, no
rotational extrusion is required. The block directions correspond to the
10 mm beam length and the two 1 mm cross-section directions.

| Level | Block divisions | Nominal cell size | Cells |
|---:|:---:|---:|---:|
| 1 | `10 x 1 x 1` | 1 mm | 10 |
| 2 | `20 x 2 x 2` | 0.5 mm | 80 |
| 3 | `40 x 4 x 4` | 0.25 mm | 640 |
| 4 | `80 x 8 x 8` | 0.125 mm | 5,120 |
| 5 | `160 x 16 x 16` | 0.0625 mm | 40,960 |
| 6 | `320 x 32 x 32` | 0.03125 mm | 327,680 |
| 7 | `720 x 72 x 72` | 0.0138889 mm | 3,732,480 |

Levels 1 through 6 successively double every directional division, increasing
the number of cells by a factor of eight per level. Level 7 retains the finest
`720 x 72 x 72` definition from the working benchmark source. The final two
levels can require substantial memory and runtime.

## What `Allrun` does

For each selected level, it:

1. Copies `base/snes` to `runs/meshN`.
2. Copies `blockMeshDict.N` over the active `blockMeshDict`.
3. Runs `blockMesh` and solids4foam.
4. Reads the final tip displacement written by the `pointDisp` function object
   and appends it to `runs/beam.summary.txt`.
5. Runs `plotScripts/render_land_problem1_plots.py` and writes the convergence
   figure under `plots/`.

Uniform `0/f0` and `0/f0f` fields aligned with the beam axis are included in
the base. This keeps the case mesh-independent and avoids a separate fibre
preprocessing step while satisfying the field inputs read by the enclosing
`electroMechanicalLaw`.

## Physical and numerical setup

The material uses the passive Guccione law inside an `electroMechanicalLaw`
with zero active tension. Its main parameters are `k = 2 kPa`, `cf = 8`,
`ct = 2`, `cfs = 4`, a bulk modulus of 16 MPa, and density 3000 kg/m3.

The solid model is nonlinear total-Lagrangian total displacement. The working
configuration uses the mixed pressure-displacement PETSc SNES solution and the
options in `petscOptions.split`. It uses the successful DataHPC Rhie-Chow
pressure stabilisation settings: a momentum diff-stencil Laplacian scale factor
of 0.1 and Rhie-Chow pressure scale/Jacobian scale factors of 1.

This is treated as a steady benchmark. `controlDict` advances directly from
time 0 to time 1 with `deltaT 1`, applying the complete load in one solve. A
completed generated case therefore has only the `0` and `1` time directories,
rather than the intermediate `0.1`, `0.2`, ... states.

## Plotting

`Allrun` invokes the Python plot script automatically after all requested mesh
levels have completed. It reads `runs/beam.summary.txt` and creates
`plots/land_problem1_m3_verticalDisplacement_vs_cellSize.pdf`.

To use the gnuplot renderer instead, or to disable plotting, use:

```bash
PLOTTER=gnuplot ./Allrun 3
PLOTTER=none ./Allrun 3
```

Set `PLOT_PYTHON` if the ReportLab-enabled interpreter is not named `python3`.
Both plotting scripts may also be invoked directly from this directory. Column
4 of the summary is the z-displacement in metres. The benchmark quantity is the
final z-coordinate of the monitored tip, whose initial coordinate is 0.001 m,
so the plot uses `1 + 1000 * Dz` in millimetres and includes the 4.2 mm
reference result.

## Layout

```text
problem1/
|-- Allrun
|-- Allclean
|-- README.md
|-- base/
|   `-- snes/
|       |-- 0/
|       |-- constant/
|       |-- system/
|       `-- petscOptions.split
|-- plotScripts/
`-- runs/                 # generated by Allrun
```

Only the base, top-level scripts, plot script, and README need to be committed.
The generated `runs` directory should normally be excluded from version
control.
