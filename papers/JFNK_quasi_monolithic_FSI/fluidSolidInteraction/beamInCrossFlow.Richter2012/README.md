# Beam In Cross Flow, Richter 2012

This case is a pseudo-transient route to the steady beam-in-crossflow FSI
benchmark from Richter (2012).  It is intended for comparing the Newton/PETSc
quasi-monolithic FVM FSI solver with partitioned FSI coupling schemes, using the
steady beam-tip `x` displacement and interface drag as the main quantities of
interest.

The monitored beam-tip point is:

```text
(0.45 0.15 -0.15)
```

The current reference values are recorded in `Richter2012ReferancesValues.md`:

- drag force in the `x` direction: `1.33 N`
- beam-tip `x` displacement: `5.95e-5 m`

The force object uses `rhoInf 1000` and compares directly against the recorded
Richter drag value.  No cavity-style force-per-thickness rescaling is applied.

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

## Steady-State Detection

Both base cases enable the `fsiSteadyStateControl` function object.  It monitors:

- solid point displacement component `0` at `(0.45 0.15 -0.15)`
- fluid interface force component `0` from the `forces` function object

When both monitored quantities change by less than the configured tolerances over
the sample window, the function object writes the current time and ends the
simulation cleanly with `writeAndEnd()`.  The monitor writes:

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

- `mesh`: mesh levels `1 2 3 4` at `deltaT=0.125`
- `time`: mesh level `2` with `deltaT = 0.0625 0.125 0.25 0.5 1 2`
- `all`: all mesh levels and all default time steps
- `smoke`: mesh level `1`, `deltaT=0.125`, `endTime=4`, and the two baseline
  methods `monolithic:default partitioned:IQNILS`

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

Run a time-step robustness sweep on mesh level 3:

```bash
MESH_LEVELS="3" DT_VALUES="0.0625 0.125 0.25 0.5 1" ./Allrun time
```

Submit the same sweep through Slurm:

```bash
sbatch --export=ALL,STUDY=time,MESH_LEVELS="3",DT_VALUES="0.0625 0.125 0.25 0.5 1",METHODS="monolithic:default partitioned:IQNILS" run.slurm
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

## Summary Columns

The campaign summary records one row per attempted case:

```text
Study Method Variant Case Mesh DeltaX DeltaT Status CellsFluid CellsSolid WallTime MaxMemoryMb SteadyTime Dx Fx DisplacementRelChange ForceRelChange Consecutive NewtonIterations KrylovIterations OuterCorrectors
```

The `Dx` and `Fx` columns are the monitored `x` displacement and `x` force.  For
short smoke runs, cases are expected to report `hitEndTime` rather than `steady`.

## Generated Figures

The existing `plotScripts/displacementVsTime.gnuplot` and
`plotScripts/forceVsTime.gnuplot` are useful for quick per-run inspection of
case directories.  Campaign-level plots against `campaignSummary.tsv` should be
added before producing paper figures.

Recommended campaign figures are:

- mesh convergence of final `x` displacement against `5.95e-5 m`
- mesh convergence of final drag against `1.33 N`
- time-step robustness plots for displacement and drag
- cost-to-solution plot versus cell count
- optional solver-work plot once iteration parsing is refined

## Verified Smoke Test

The scripts were smoke-tested with OpenFOAM-v2512 and the monolithic solids4Foam
build.  The successful verification run was:

```text
run_smoke_AMD_EPYC_9684X_96_Core_Processor_2026-04-29_11-36-31/campaignSummary.tsv
```

Both baseline cases reached the short smoke end time and wrote
`fsiSteadyStateControl.dat`.  This verifies the campaign scripts and monitors;
it is not a steady-convergence result.

## Notes

The current campaign is serial.  Parallel runs should be added after the serial
mesh and time-step behaviour is established, initially on the finest useful mesh.

The companion `campaign-plan.md` records the broader design plan and open
questions for the full paper campaign.
