# An elastic half-ylinder in a highly viscous flow: `blobInTreacle`

## Overview

This tutorial demonstrates a two-dimensional fluid–structure interaction (FSI)
problem involving incompressible flow past a deformable elastic half-cylinder
attached to the bottom wall of a channel, as proposed by [Liu et al.](http://dx.doi.org/10.1016/j.jcp.2014.04.020).

The case is designed to assess the temporal accuracy of coupled FSI schemes.
A laminar inflow develops smoothly in time, interacting with a linearly elastic
solid that deforms under fluid loading.

## Geometry and Setup

The computational domain consists of:

- A rectangular fluid domain: `[0, 6.5] × [-0.5, 1]` m
- A deformable semi-circular cylinder of radius 0.5 m
- The cylinder is centred at (1.5, -0.5) m and attached to the bottom wall

The interface between the fluid and solid domains is denoted Γ.

## Boundary Conditions

### Fluid

- **Inlet (Γ_in):**
  Prescribed velocity:

  u = (U₀, 0) = g(t)(1 + 2y)(1 - y)

  where:

  ```text
  g(t) = 0.5 * [1 - cos(π/2 * t)]  for t ≤ 2
  g(t) = 1                         for t > 2
  ```

- **Outlet (Γ_out):**
  Traction-free:

  σ·n = 0

- **Walls:**
  No-slip condition

- **Fluid–solid interface (Γ):**
  No-slip and kinematic coupling

### Solid Model

- St-Venant-Kirchhoff hyperelastic material
- Fixed at the base (attached to the bottom wall)

## Material Properties

### Solid Properties

- Density: ρˢ = 1
- Lamé parameters:
  - λˢ = 500
  - μˢ = 50

### Fluid Properties

- Density: ρᶠ = 1
- Kinematic viscosity: νᶠ = 1

## Running the Case

The case now follows the same campaign layout as `cavityFlexibleBottom`:

```text
base/quasiMonolitic/
base/partitioned/
```

The top-level `Allrun` copies these templates into timestamped campaign
directories and records a `campaignSummary.tsv`.

It can also launch multiple cases at once, subject to a total MPI-rank budget.
The default mesh-to-core mapping is:

```text
mesh 1 -> 2 cores
mesh 2 -> 4 cores
mesh 3 -> 8 cores
mesh 4 -> 12 cores
mesh 5 -> 16 cores
```

Override the total budget with `TOTAL_CORES`, or replace the per-mesh mapping
with `MESH_CORES=(...)` if you want a different distribution.

Run a short monolithic/partitioned smoke test with:

```bash
./Allrun smoke
```

Run the representative time-step sweep with:

```bash
./Allrun time
```

## Running With Slurm

Submit the default Slurm smoke test with:

```bash
sbatch run.slurm
```

The Slurm script loads OpenFOAM-v2512, prepends the
`/home/philipc/OpenFOAM/philipc-v2512/solids4foam.monolithic` build to the
runtime paths, and runs:

```bash
./Allrun "$STUDY"
```

By default, `STUDY=smoke`.  Other campaign modes can be selected at submission:

```bash
sbatch --export=ALL,STUDY=time run.slurm
sbatch --export=ALL,STUDY=mesh run.slurm
sbatch --export=ALL,STUDY=all run.slurm
```

Campaign controls can be passed through Slurm as environment variables:

```bash
sbatch --export=ALL,STUDY=time,METHODS="monolithic:default partitioned:IQNILS",DT_VALUES="0.1 0.025 0.0125 0.00625",END_TIME=1 run.slurm
```

Common overrides:

```bash
METHODS="monolithic:default partitioned:IQNILS" END_TIME=1 ./Allrun time
DT_VALUES="0.1 0.025 0.0125 0.00625" ./Allrun time
TOTAL_CORES=8 ./Allrun smoke
MESH_CORES=(2 2 4 4 8) TOTAL_CORES=8 ./Allrun all
```

The script still runs the individual solids4Foam solver in parallel whenever
the selected mesh level requests more than one core. For partitioned cases that
means decomposing the fluid and solid regions before the solver and
reconstructing afterwards; for monolithic cases it uses the monolithic
decomposition path before calling `solids4Foam -parallel`.

The monolithic template uses `NewtonQuasiMonolithic`, defined in
`base/quasiMonolitic/constant/fsiProperties`:

```c++
fluidSolidInterface NewtonQuasiMonolithic;

NewtonQuasiMonolithicCoeffs
{
    solidPatch      interface;
    fluidPatch      cylinder;
    fluidSystemScaleFactor 1e+08;
    coupled         yes;
    interfaceTransferMethod directMap;
    writeResidualsToFile yes;
    passViscousStress yes;
}
```

The partitioned template uses `IQNILS` by default, defined in
`base/partitioned/constant/fsiProperties`.  The top-level driver can switch this
to `Aitken` through `METHODS`.

PETSc options for the monolithic `UpU` system are defined in the monolithic
template `system/fvSolution`.  The partitioned template has separate fluid `Up`
and solid `D` PETSc entries in the region `fvSolution` files.

Make sure the mesh exposes the `interface` and `cylinder` patches referenced
above. Update `fsiProperties` accordingly if you change the patch names so the
solver can locate the solid and fluid boundaries.

## Results

The simulation captures the deformation of the elastic half-cylinder under
transient flow loading. The inflow ramps up smoothly, allowing assessment of
the temporal accuracy of the coupling scheme.

Typical quantities of interest include:

- Tip displacement of the cylinder
- Velocity and pressure fields in the fluid
- Convergence behaviour of the coupled solver

The regression script (`regressionTest.sh`) tracks the tip displacement in
`postProcessing/0/solidPointDisplacement_displacement.dat` and the total fluid
force in `postProcessing/fluid/forces/0/force.dat` at the final time (t = 2 s).
Target values are ≈ 0.1989 m for the x-displacement and ≈ 15.77 N for the total
x-force; monitor `log.Allrun` for the residual history when evaluating
convergence.

## References

[1] [Liu, J. Jaiman, RK., Gurugubelli, PS. A stable second-order scheme for
 fluid–structure interaction with strong added-mass effects, Journal of Computational
 Physics, 270, 2014, 687-710](https://doi.org/10.1016/j.jcp.2014.04.020)
