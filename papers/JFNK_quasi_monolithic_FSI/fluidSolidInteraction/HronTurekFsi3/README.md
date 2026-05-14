# Hron-Turek FSI3 Benchmark

A campaign harness for the Turek-Hron `FSI3` dynamic benchmark (elastic plate
behind a rigid cylinder in laminar channel flow). Runs the new Newton/PETSc
quasi-monolithic FVM FSI solver alongside partitioned FSI (IQN-ILS, Aitken)
under matched physics, mesh, and time-step settings.

The case is 2D (plane strain), transient, and quasi-periodic after `t ~ 4 s`.
Reference values are reported as `mean +/- amplitude [frequency]` over the last
full period before `t = 20 s`.

## Physical setup

Channel `2.5 m x 0.41 m`, rigid cylinder of radius `0.05 m` at `(0.2, 0.2)`,
elastic plate `0.35 m x 0.02 m` attached to the right of the cylinder.

| Parameter | Value | Units |
|---|---|---|
| Fluid density | 1000 | kg/m^3 |
| Fluid kinematic viscosity | 1e-3 | m^2/s |
| Mean inlet velocity | 2 (max 3 for parabolic profile) | m/s |
| Solid density | 1000 | kg/m^3 |
| Solid Young's modulus | 5.6e6 | Pa |
| Solid Poisson's ratio | 0.4 | - |
| Solid model | neo-Hookean elastic | - |

Coupling is activated at `t = 2 s` after the inlet flow develops.

## Reference data

`HronTurekReference.csv` carries:

- Turek & Hron (2006) FSI3 reference: `u_x=-2.69 +/- 2.53 [10.9]`,
  `u_y=1.48 +/- 34.38 [5.3]`, `F_x=457.3 +/- 22.66`, `F_y=2.22 +/- 149.78`.
- Tukovic et al. (2018) solids4foam reference: `u_x=-2.72 +/- 2.58 [11.07]`,
  `u_y=1.67 +/- 33.84 [5.53]`, `F_x=459.18 +/- 24.86`, `F_y=1.59 +/- 155.9`.

Displacements are in mm, forces in N, frequencies in Hz.

## Conformal-interface meshes

The monolithic interface implementation requires fluid and solid to share the
same number and size of faces along the FSI patch. `system/fluid/blockMeshDict.{1,2,3}`
and `system/solid/blockMeshDict.{1,2,3}` are designed conformally:

| level | fluid cells | solid cells | plate faces (each side) | DeltaX (plate thickness mm) |
|---|---|---|---|---|
| 1 | 1859 | 150 | 65 | 4.0 |
| 2 | ~7400 | 600 | 130 | 2.0 |
| 3 | 29744 | 2400 | 260 | 1.0 |

Levels 2 and 3 are uniform 2x and 4x scalings of every block-divisions tuple.
The `Allrun` runs `checkMesh` on both regions and asserts equal plate face
counts before launching the solver.

## Solver variants

| methodVariant | description |
|---|---|
| `monolithic:default` | Newton/PETSc quasi-monolithic with default fieldsplit/Schur PC |
| `monolithic:schurTuned` | tuned Schur factorisation + ASM/ILU |
| `monolithic:physicsPC` | physics-based PC (segregated inner solves) |
| `partitioned:IQNILS` | partitioned IQN-ILS (relax 0.05, nOuterCorr 30) |
| `partitioned:Aitken` | partitioned Aitken (same baseline settings) |

## Running with Slurm

```bash
sbatch run.slurm                                        # default mesh study
sbatch --export=ALL,STUDY=time run.slurm
sbatch --export=ALL,STUDY=all  run.slurm
sbatch --export=ALL,STUDY=smoke run.slurm
```

## Running Allrun directly

```bash
source /usr/lib/openfoam/openfoam2512/etc/bashrc
./Allrun mesh        # MESH_LEVELS="1 2 3", DT_VALUES="1e-3", endTime=20
./Allrun time        # MESH_LEVELS="2", DT_VALUES="2e-3 1e-3 5e-4 2.5e-4"
./Allrun smoke       # quick check at endTime=0.1, monolithic+IQNILS only
```

Each run writes a timestamped directory:

```
run_<study>_<cpu>_<date>/
    campaignSummary.tsv
    monolithic_default.m1.dt1em3/
    ...
    campaign*.pdf       # if gnuplot is available
```

## Common overrides

```bash
METHODS="monolithic:default partitioned:IQNILS" ./Allrun mesh
MESH_LEVELS="1" DT_VALUES="1e-3 5e-4" ./Allrun time
END_TIME=10 ./Allrun mesh
FORCE_SCALE=66.667 ./Allrun mesh   # 1/0.015 if force-per-meter is desired
```

Useful controls:

- `METHODS`, `MESH_LEVELS`, `DT_VALUES`
- `END_TIME` (default 20 s; smoke defaults to 0.1 s)
- `FORCE_SCALE` (default 1.0; multiplies the post-processed F_x and F_y)
- `START_FRAC` (default 0.5; fraction of `[0, endTime]` used for last-period
  statistics)

## Summary table columns

```
Study Method Variant Case Mesh DeltaX DeltaT Status
CellsFluid CellsSolid WallTime MaxMemoryMb
UxMean UxAmp UxFreq UyMean UyAmp UyFreq
FxMean FxAmp FxFreq FyMean FyAmp FyFreq
```

`Status` is `ranToEnd` if the solver completed, `failed` otherwise.
`Ux*`/`Uy*` are in metres; `Fx*`/`Fy*` are in Newtons (raw forces over the
extruded 15 mm slab; multiply by `1/0.015` for 2D unit-thickness comparison
to Turek-Hron). The post-processing helper `extractLastPeriod.py` extracts
mean / half-amplitude / frequency from the last full period detected by
zero crossings of `signal - mean(tail)`. Returns `NaN` if the run is too
short to contain a full period.

## Plots

If `gnuplot` is available, the campaign copies and runs the scripts in
`plotScripts/`, producing:

- `campaignMeshUyMean.pdf`, `campaignMeshUyAmp.pdf`, `campaignMeshUyFreq.pdf`
- `campaignMeshFxMean.pdf`, `campaignMeshFyAmp.pdf`
- `campaignTimeStepUyAmp.pdf`, `campaignTimeStepUyFreq.pdf`,
  `campaignTimeStepFyAmp.pdf`, `campaignTimeStepCost.pdf`

The displacement and force time-history scripts can be run inside any run
directory with `gnuplot -c displacementVsTime.gnuplot <method.variant>` etc.

## References

1. Turek, S. & Hron, J. (2006). Proposal for Numerical Benchmarking of
   Fluid-Structure Interaction between an Elastic Object and Laminar
   Incompressible Flow. _Lecture Notes in Computational Science and
   Engineering_, vol. 53. Springer.
2. Tukovic, Z., Jasak, H., Karac, A., Cardiff, P., Ivankovic, A. (2018).
   OpenFOAM finite volume solver for fluid-solid interaction. _Trans.
   Famena_, 42(3), 1-31.
