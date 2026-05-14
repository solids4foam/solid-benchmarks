# Cavity With Flexible Bottom

This case is a pseudo-transient route to a steady FSI response for a lid-driven
cavity with a flexible bottom.  It is intended for comparing the new
Newton/PETSc quasi-monolithic FVM FSI solver with partitioned FSI coupling
schemes, using the steady vertical displacement at `(4 -1 0.5)` and the fluid
force on the interface as the main quantities of interest.

The case includes Tukovic reference data:

- `TukovicDisplacements.csv`: steady vertical displacement versus `DeltaX`
- `TukovicForces.csv`: steady vertical force versus `DeltaX`

The Tukovic force values are for an out-of-plane thickness of `0.05 m`; the
campaign plots multiply them by `20` to compare against force per unit
thickness.

## Solver Comparisons

The campaign runner supports these method/variant pairs:

- `monolithic:default`
- `monolithic:schurTuned`
- `monolithic:physicsPC`
- `partitioned:IQNILS`
- `partitioned:Aitken`

The initial partitioned Aitken comparison uses the same baseline tolerance,
relaxation, and maximum outer-corrector settings as the corresponding
partitioned case setup.  These settings can be tuned later after the first
comparison pass.

## Steady-State Detection

Both base cases enable the `fsiSteadyStateControl` function object.  It monitors:

- vertical solid point displacement at `(4 -1 0.5)`
- vertical interface force from the fluid `forces` function object

When both monitored quantities change by less than the specified tolerances over
the configured sample window, the function object writes the current time and
ends the simulation cleanly with `writeAndEnd()`.  The monitor writes:

```text
postProcessing/0/fsiSteadyStateControl.dat
```

If the steady criterion is not reached before `endTime`, the case is marked as
`hitEndTime` in the campaign summary.  Solver failures are marked as `failed`.

## Running With Slurm

Submit the default mesh study with:

```bash
sbatch run.slurm
```

The Slurm script sources OpenFOAM-v2512 and runs:

```bash
./Allrun "$STUDY"
```

By default, `STUDY=mesh`.  Other studies can be selected at submission:

```bash
sbatch --export=ALL,STUDY=time run.slurm
sbatch --export=ALL,STUDY=all run.slurm
sbatch --export=ALL,STUDY=smoke run.slurm
```

## Running Allrun Directly

After sourcing OpenFOAM-v2512:

```bash
source /usr/lib/openfoam/openfoam2512/etc/bashrc
./Allrun mesh
./Allrun time
./Allrun smoke
```

Available study modes:

- `mesh`: mesh levels `1 2 3 4` at `deltaT=0.5`
- `time`: mesh level `3` with `deltaT = 0.5 1 2.5 5 10 20 40`
- `all`: all mesh levels and all default time steps
- `smoke`: one coarse quick check

Each run creates a timestamped directory:

```text
run_<study>_<cpu>_<date>/
```

The main output table is:

```text
run_<study>_<cpu>_<date>/campaignSummary.tsv
```

## Common Overrides

Use environment variables to restrict or extend the campaign.

Run only two methods:

```bash
METHODS="monolithic:default partitioned:IQNILS" ./Allrun mesh
```

Run a time-step robustness sweep on mesh level 2:

```bash
MESH_LEVELS="2" DT_VALUES="0.5 1 2.5 5 10 20" ./Allrun time
```

Submit the same sweep through Slurm:

```bash
sbatch --export=ALL,STUDY=time,MESH_LEVELS="2",DT_VALUES="0.5 1 2.5 5 10 20",METHODS="monolithic:default partitioned:IQNILS" run.slurm
```

Change the steady-state tolerances:

```bash
STEADY_DISP_REL_TOL=1e-6 STEADY_FORCE_REL_TOL=1e-6 ./Allrun mesh
```

Useful controls:

- `METHODS`
- `MESH_LEVELS`
- `DT_VALUES`
- `END_TIME`
- `STEADY_MIN_TIME`
- `STEADY_N_SAMPLES`
- `STEADY_N_CONSECUTIVE`
- `STEADY_DISP_REL_TOL`
- `STEADY_FORCE_REL_TOL`

## Generated Figures

If `gnuplot` is available, the campaign copies and runs the campaign plot
scripts from `plotScripts/`, producing:

- `campaignMeshDisplacement.pdf`
- `campaignMeshForce.pdf`
- `campaignTimeStepDisplacement.pdf`
- `campaignTimeStepForce.pdf`
- `campaignTimeStepCost.pdf`

The mesh plots overlay the computed steady values against the Tukovic mesh-study
data.  The time-step plots are intended to highlight robustness and cost,
including which cases fail, reach steady state, or simply hit `endTime`.

## Notes

The current campaign is serial.  Parallel runs should be added after the serial
mesh and time-step behaviour is established, initially on the finest useful mesh.
