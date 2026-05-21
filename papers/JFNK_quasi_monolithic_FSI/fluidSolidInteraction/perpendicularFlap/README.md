# Perpendicular Flap

This transient two-dimensional FSI benchmark compares the Newton/PETSc
quasi-monolithic FVM FSI solver with partitioned coupling schemes for a flexible
flap mounted perpendicular to the lower wall of a channel.

The main quantities of interest are:

- displacement of the initial flap-tip point `(0 1 0)` versus time
- fluid-side interface force on the fluid patch `flap` versus time

The solid-side interface force on solid patch `interface` is also written for
debugging and force-balance checks.

## Case Structure

The campaign uses template cases:

- `base/quasiMonolithic`: Newton/PETSc quasi-monolithic coupling
- `base/partitioned`: partitioned coupling with selectable IQNILS or Aitken

The top-level `Allrun` copies one template per attempted case into a timestamped
`run_<study>_<cpu>_<date>/` directory, selects the method dictionaries, creates
the solid/fluid meshes, runs `checkMesh`, executes `solids4Foam`, and appends a
row to `campaignSummary.tsv`.  Cases are queued and launched concurrently while
respecting the configured MPI-rank budget.

## Solver Comparisons

Supported method/variant pairs are:

- `monolithic:default`
- `monolithic:schurTuned`
- `monolithic:physicsPC`
- `partitioned:IQNILS`
- `partitioned:Aitken`

The monolithic template uses the velocity-form solid model required by
`NewtonQuasiMonolithic`, with a `StVenantKirchhoffElastic` law using the same
`rho`, `E`, and `nu` as the original linear-elastic flap.

Restrict the campaign with `METHODS`, for example:

```bash
METHODS="monolithic:default partitioned:IQNILS" ./Allrun smoke
```

## Mesh And Time-Step Studies

The mesh scale is selected with `MESH_LEVELS`.  The supplied levels are:

- `1`: original mesh
- `2`: twice as many cells in each in-plane block direction
- `3`: four times as many cells in each in-plane block direction

The out-of-plane cell count remains `1` because the case uses `empty`
front/back patches.

Available study modes:

- `mesh`: mesh scales `1 2 3` at `deltaT=0.01`
- `time`: mesh scale `2` with `deltaT = 0.0025 0.005 0.01 0.02`
- `all`: all mesh scales and all default time steps
- `smoke`: mesh scale `1`, `deltaT=0.02`, and `endTime=0.1`

The default physical end time is `5 s`, which captures several flap bounces.
The smoke test shortens this unless `END_TIME` is explicitly set.

Common overrides:

```bash
MESH_LEVELS="1 2" DT_VALUES="0.005 0.01" ./Allrun all
END_TIME=1 METHODS="monolithic:default partitioned:IQNILS" ./Allrun time
```

## Running Directly

Use OpenFOAM-v2512:

```bash
. /usr/lib/openfoam/openfoam2512/etc/bashrc
./Allrun smoke
./Allrun mesh
./Allrun time
```

The intended solids4foam build is:

```text
/home/philipc/OpenFOAM/philipc-v2512/solids4foam.monolithic
```

Ensure this build is on `PATH` and that its PETSc-enabled libraries are
available before running the monolithic variants.

## Running With Slurm

Submit the default mesh study with:

```bash
sbatch run.slurm
```

Select another study or override campaign controls at submission:

```bash
sbatch --export=ALL,STUDY=smoke run.slurm
sbatch --export=ALL,STUDY=time,METHODS="monolithic:default partitioned:IQNILS" run.slurm
sbatch --export=ALL,STUDY=all,MESH_LEVELS="1 2",DT_VALUES="0.005 0.01",END_TIME=2 run.slurm
```

`run.slurm` passes its Slurm task count to `Allrun` as `TOTAL_CORES`.
Override the total budget at submission time when a campaign should use fewer
tasks:

```bash
sbatch --export=ALL,STUDY=smoke,TOTAL_CORES=2 run.slurm
```

## Outputs

Each run directory contains:

```text
campaignSummary.tsv
<method>_<variant>.m<mesh>.dt<dt>/
```

The primary time-history files inside each case are:

```text
postProcessing/0/solidPointDisplacement_tipDisplacement.dat
postProcessing/fluid/fluidForces/0/force.dat
postProcessing/0/solidForcesinterface.dat
```

The summary table records final tip displacement, displacement extrema, final
fluid force, fluid-force extrema, final solid-side force, mesh cell counts,
wall time, and maximum resident memory.

The default run uses `1 1 2` ranks for mesh levels `1 2 3`, so the campaign
budget controls both concurrent serial cases and the level-3 parallel cases.
Direct runs can change this mapping:

```bash
TOTAL_CORES=4 ./Allrun smoke
MESH_CORES="1 2 4" TOTAL_CORES=4 ./Allrun mesh
```

If `gnuplot` is available, `Allrun` copies `plotScripts/` into the run
directory and creates campaign plots for mesh response, time-step response,
cost, memory, final summary values, and comparison histories.  The displacement
and force history scripts compare the default monolithic and partitioned Aitken
variants across time steps at one mesh and across meshes at one time step.  The
method pair and selected comparison slices are set at the top of each script.
