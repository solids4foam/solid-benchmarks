# Beam In Cross Flow, Gillebaart 2015

This case is a transient beam-in-crossflow FSI benchmark with larger
deformations than the steady Richter 2012 case.  It is intended for comparing
the Newton/PETSc quasi-monolithic FVM FSI solver with partitioned FSI coupling
schemes using time histories of beam-tip displacement and interface force.

The monitored beam-tip point is:

```text
(0.45 0.15 -0.15)
```

The current reference value is recorded in `Tukovic2018ReferancesValues.md`:

- beam-tip `x` deflection: `1.016 mm`

The force object uses `rhoInf 1000`.  The default comparison plots show the
`x` component of the total interface force directly from the `forces` function
object.

## Solver Comparisons

The campaign runner supports these method/variant pairs:

- `monolithic:default`
- `monolithic:schurTuned`
- `monolithic:physicsPC`
- `partitioned:IQNILS`
- `partitioned:Aitken`

The monolithic variants select existing PETSc option files in
`base/quasiMonolithic`.  The partitioned variants switch the
`fluidSolidInterface` entry in `constant/fsiProperties`.

The first comparison pass should treat these as baseline settings.  Further
tuning of PETSc preconditioners, Aitken relaxation, or IQN-ILS settings should
come after the baseline mesh and time-step behaviour is understood.

## Transient Output

This case should run to the prescribed physical `endTime`.  It does not use an
automated steady-state stopping criterion.

Both base cases write time histories every time step:

- beam-tip displacement:
  `postProcessing/0/solidPointDisplacement_displacement.dat`
- interface force:
  `postProcessing/fluid/forces/0/force.dat`

The campaign summary records the final and peak absolute values and keeps the
relative paths to these history files so plots can compare full transients
across method, mesh, and time-step sweeps.

## Running With Slurm

Submit the default mesh study with:

```bash
sbatch run.slurm
```

The Slurm script sources OpenFOAM-v2512, prepends the monolithic solids4Foam
build paths from `/home/philipc/OpenFOAM/philipc-v2512/solids4foam.monolithic`,
and runs:

```bash
./Allrun "${STUDY:-mesh}"
```

By default, `STUDY=mesh`.  Other studies can be selected at submission:

```bash
sbatch --export=ALL,STUDY=time run.slurm
sbatch --export=ALL,STUDY=all run.slurm
sbatch --export=ALL,STUDY=smoke run.slurm
```

## Running Allrun Directly

After sourcing OpenFOAM-v2512, prepend the monolithic build paths:

```bash
source /usr/lib/openfoam/openfoam2512/etc/bashrc
export PATH=/home/philipc/OpenFOAM/philipc-v2512/platforms/linux64GccDPInt32Opt/bin:/home/philipc/OpenFOAM/philipc-v2512/solids4foam.monolithic/applications/scripts:$PATH
export LD_LIBRARY_PATH=/home/philipc/OpenFOAM/philipc-v2512/platforms/linux64GccDPInt32Opt/lib:$LD_LIBRARY_PATH

./Allrun mesh
./Allrun time
./Allrun smoke
```

Available study modes:

- `mesh`: mesh levels `1 2 3 4` at `deltaT=0.001`
- `time`: mesh level `2` with `deltaT = 0.002 0.001 0.0005 0.00025`
- `all`: all mesh levels and all default time steps
- `smoke`: mesh level `1`, `deltaT=0.001`, `endTime=0.004`, and the two
  baseline methods `monolithic:default partitioned:IQNILS`

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

Run a time-step sweep on mesh level 3:

```bash
MESH_LEVELS="3" DT_VALUES="0.001 0.0005 0.00025" ./Allrun time
```

Submit the same sweep through Slurm:

```bash
sbatch --export=ALL,STUDY=time,MESH_LEVELS="3",DT_VALUES="0.001 0.0005 0.00025",METHODS="monolithic:default partitioned:IQNILS" run.slurm
```

Run a shorter development case:

```bash
END_TIME=0.02 METHODS="monolithic:default partitioned:IQNILS" ./Allrun mesh
```

Useful controls:

- `METHODS`
- `MESH_LEVELS`
- `DT_VALUES`
- `END_TIME`

## Summary Columns

The campaign summary records one row per attempted case:

```text
Study Method Variant Case Mesh DeltaX DeltaT Status CellsFluid CellsSolid WallTime MaxMemoryMb FinalTime FinalDx FinalFx PeakAbsDx PeakAbsFx DisplacementHistory ForceHistory NewtonIterations KrylovIterations OuterCorrectors
```

The `FinalDx` and `FinalFx` columns are the final monitored `x` displacement and
`x` force.  `PeakAbsDx` and `PeakAbsFx` are the largest absolute values seen in
the written histories.  `DisplacementHistory` and `ForceHistory` are relative
paths from the run directory to the full time-history files.

Cases are marked as:

- `completed`: solver reached the requested physical end time
- `failed`: solver returned a non-zero status

## Generated Figures

If `gnuplot` is available, the campaign copies and runs the campaign plot
scripts from `plotScripts/`, producing:

- `campaignDisplacementVsTime.pdf`
- `campaignForceVsTime.pdf`

These plots overlay all completed runs in the campaign summary.  They are
intended for method, mesh, and time-step comparison of the full transient
response.  The older `displacementVsTime.gnuplot` and `forceVsTime.gnuplot`
scripts remain useful for quick per-method directory inspection.

Recommended paper-oriented figures are:

- displacement time histories for selected method/mesh/time-step combinations
- force time histories for selected method/mesh/time-step combinations
- mesh convergence of peak and final displacement
- time-step convergence of peak displacement and phase
- cost-to-solution versus cell count or time-step size

## Verified Smoke Test

The scripts were smoke-tested with OpenFOAM-v2512 and the monolithic solids4Foam
build.  The successful verification run was:

```text
run_smoke_AMD_EPYC_9684X_96_Core_Processor_2026-04-29_12-49-08/campaignSummary.tsv
```

Both baseline cases reached the short transient smoke end time `0.004 s`, wrote
displacement and force histories, and generated the two campaign PDFs.  This
verifies the campaign scripts and monitors; it is not a full benchmark result.

## Notes

The current campaign is serial.  Parallel runs should be added after the serial
mesh and time-step behaviour is established, initially on the finest useful mesh.

Unlike the steady Richter 2012 case, this transient benchmark should not use
`fsiSteadyStateControl` or early termination based on steady criteria.
