# Flow over a rectangle building with a flexible membrane roof: `membraneRoof2d`

Prepared by Ivan Batistić, Philip Cardiff

## Tutorial Aims

- Demonstrate a two-dimensional fluid-structure interaction benchmark with a
  very slender membrane roof.
- Show the partitioned Dirichlet-Neumann coupling and the monolithic
  fluid-solid interaction solver.

## Case Overview

This tutorial studies a rectangle building covered by a flexible
membrane roof and exposed to an incoming
parabolic profile flow. The case is 2D version of the `membraneRoof` case.
The setup follows the membrane-roof example described in Section 4.1 of the
paper by von Scheven and Ramm [1], with some slight changes in velocity profile,
membrane thickness, domain size and membrane Young modulus.

The physical parameters of the problem are:

- **Geometry**
  - Building width: $0.4$ m
  - Building height: $0.2$ m
  - Overall domain size ($L \times W$): $2.2 \times 1$ m
  - Membrane thickness: $0.005$ m
  - Gravity ($g$): $0$ $\mathrm{m/s}^2$
- **Solid**
  - St. Venant-Kirchhoff material model
  - Density ($\rho_s$): $500$ $\mathrm{kg/m}^3$
  - Young’s modulus ($E_s$): $500$ Pa
  - Poisson’s ratio ($\nu_s$): $0$
- **Fluid**
  - Laminar flow
  - Density ($\rho_f$): $1$ $\mathrm{kg/m}^3$
  - Kinematic viscosity ($\nu_f$): $0.01$ $\mathrm{m}^2$/s

As in the reference paper [1], the case is solved using $400$ uniform
time steps of $\Delta t = 0.005$ s.

At the inlet boundary ($x = 0$), the paper prescribes the streamwise
velocity $\mathbf{u}(y,t) =U_{\max} r(t)\left(2\eta - \eta^2\right)\mathbf{e}_x, \qquad \eta = \mathrm{clip}\left(\frac{y}{H},0,1\right)$ 
with $U_{\max}=0.6, H=1.0$, and $r(t)= t/2 \text{ for } t < 2$ and $r(t)=1$ otherwise.

Compared to [1] where authors
use linear velocity profile, herein used parabolic profile is chosen 
becouse it is more consistent with slip boundary condition at the
top surface.

The inlet condition is implemented as a tutorial-local library in
`src/membraneRoofVelocity2dFvPatchVectorField`
and loaded through `system/controlDict`. This avoids `codedFixedValue`, which
is not portable across all supported OpenFOAM forks.

The library is compiled automatically by `./Allrun` through `src/Allwmake`.

## Mesh Generation

The tutorial uses a coarser mesh intended for routine testing and demonstration.
The fluid mesh consists of $6804$ cells, and the solid mesh consists
of $288$ cells.

For the fluid region, the mesh is generated with `blockMesh` and then refined
two times locally above and around the roof using `setSet` and `refineMesh`. 
The `setSet` command creates the `cellsToRefine` cell set from the selection specified in
`setSet1.batch` and `setSet2.batch`, while `refineMesh`, 
using `system/fluid/refineMeshDict1` and `system/fluid/refineMeshDict2`.
`refineMesh` utility uniformly splits each selected cell into eight cells.

## Campaign Layout

The case is organised as a transient comparison campaign:

- `base/quasiMonolithic`: Newton/PETSc quasi-monolithic template case
- `base/partitioned`: partitioned FSI template case
- `Allrun`: top-level campaign driver
- `run.slurm`: Slurm entry point
- `src/`: tutorial-local inlet velocity boundary condition

The base templates contain three mesh levels:

- `1`: original blockMesh cell counts
- `2`: twice the number of cells in each block direction
- `4`: four times the number of cells in each block direction

Each run still applies the local fluid refinement above and around the roof via
`setSet` and `refineMesh`.

The main quantities of interest are:

- displacement of the solid interface centre point `(0.6 0.2 0)` versus time
- total interface force components `Fx` and `Fy` on the fluid patch
  `membrane-fluid` versus time

These are written by the `solidPointDisplacement` and `forces` function objects
in `system/controlDict`.

## Running With Slurm

Submit the default mesh study with:

```bash
sbatch run.slurm
```

The Slurm script sources OpenFOAM-v2512:

```bash
. /usr/lib/openfoam/openfoam2512/etc/bashrc
```

and uses:

```bash
SOLIDS4FOAM_ROOT=/home/philipc/OpenFOAM/philipc-v2512/solids4foam.monolithic
```

By default, `STUDY=mesh`. Other studies can be selected at submission:

```bash
sbatch --export=ALL,STUDY=time run.slurm
sbatch --export=ALL,STUDY=mesh run.slurm
sbatch --export=ALL,STUDY=all run.slurm
sbatch --export=ALL,STUDY=smoke run.slurm
```

Common overrides can be passed through Slurm:

```bash
export METHODS="quasiMonolithic:default partitioned:IQNILS"
sbatch --export=ALL,STUDY=time,DT_VALUES="0.04 0.02 0.01" run.slurm
```

## Running Allrun Directly

From the case directory, run

```bash
. /usr/lib/openfoam/openfoam2512/etc/bashrc
./Allrun mesh
./Allrun time
./Allrun smoke
```

```note
The monolithic approach requires OpenFOAM.com (ESI) and a PETSc installation
with `PETSC_DIR` set. It does not run with foam-extend or OpenFOAM.org.
```

Available study modes:

- `mesh`: mesh factors `1 2 4` at `deltaT=0.02`
- `time`: mesh factor `1` with `deltaT = 0.04 0.02 0.01`
- `all`: all mesh factors and all default time steps
- `smoke`: one short two-step check on the original mesh

The campaign driver will:

1. Compile the local inlet boundary-condition library.
2. Clone the selected base template into a timestamped run directory.
3. Link the selected quasi-monolithic or partitioned dictionary files.
4. Select the requested mesh level.
5. Generate and check the fluid and solid meshes.
6. Refine the fluid mesh.
7. Run `solids4Foam`.
8. Append run status, mesh size, cost, displacement, `Fx`, and `Fy` data to
   `campaignSummary.tsv`.

Each campaign creates:

```text
run_<study>_<cpu>_<date>/
```

The main output table is:

```text
run_<study>_<cpu>_<date>/campaignSummary.tsv
```

The default method/variant set is:

- `quasiMonolithic:default`
- `quasiMonolithic:schurTuned`
- `quasiMonolithic:physicsPC`
- `partitioned:IQNILS`
- `partitioned:Aitken`

Useful controls:

- `METHODS`
- `MESH_LEVELS`
- `DT_VALUES`
- `END_TIME`
- `WRITE_INTERVAL`

Example direct runs:

```bash
METHODS="quasiMonolithic:default partitioned:Aitken" ./Allrun mesh
MESH_LEVELS="2" DT_VALUES="0.04 0.02 0.01" ./Allrun time
END_TIME=2 WRITE_INTERVAL=0.02 ./Allrun smoke
```

## References

[1] [M. von Scheven and E. Ramm, "Strong coupling schemes for interaction of
thin-walled structures and incompressible flows," *International Journal for
Numerical Methods in Engineering*, 87(1-5), 2011, pp. 214-231](
https://doi.org/10.1002/nme.3033)
