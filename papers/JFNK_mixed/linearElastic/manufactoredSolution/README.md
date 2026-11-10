# Method of Manufactured Solutions

## Overview
This test case applies a manufactured solution to a cube domain and measures the
accuracy and order of accuracy for the displacement, stress and pressure fields
on various mesh types.

### Pressure errors
The mixed displacement-pressure solid model stores the compression-positive
hydrostatic stress, i.e. `sigma = dev(sigma) - p*I`, so the analytical pressure
is simply `p = -tr(sigma)/3` evaluated from the existing manufactured stress
field. No extra manufactured field is needed. The `manufacturedSolution`
function object therefore writes a `pDifference` field and prints

```
Writing pDifference field
    Pressure error norms: mean L1, mean L2, LInf:
    Magnitude: <mean L1> <mean L2> <LInf>
```

which the `Allrun` script records as columns 10-12 (`P_L2 P_Linf P_meanL1`) of
the `*.summary.txt` files and as columns 6-7 of the `*.orderOfAccuracy.txt`
files. The pressure error is only available when the solid model solves for a
pressure unknown (`solvePressure true;` in `constant/solidProperties`); it is
recorded as `NaN` otherwise, which gnuplot skips. Set `cellPressure no;` in the
`mms` function object to switch it off.

## Instructions

### Compile `manufacturedSolution` Library
The `manufacturedSolution` library contains the source term, boundary conditions
and function object to apply the manufactured solution and calculate the errors.
Before the library the `SOLIDS4FOAM_DIR` directory should be set to
point to the location of the solids4foam installation, e.g.
```bash
export SOLIDS4FOAM_DIR=/Users/philipc/OpenFOAM/philipc-v2312/solids4foam
```
The `manufacturedSolution` library can then be compiled with
```bash
(cd ../manufacturedSolution && ./Allwmake -j -s)
```

### Run the Cases
The `Allrun` runs a mesh study for three mesh families with the single
stabilisation configuration of `base/snes/constant/solidProperties`
(`generalisedEvenOrderLaplacian`, `laplacianPower 1`, i.e. coupled `m = 1`).

The mesh families are defined near the top of the `Allrun` script:
```bash
configs=(
    "BASE=base/snes NAME=hex.hypre USE_GMSH=0 USE_DUALMESH=0 USE_PERTURBMESHPOINTS=0 PETSC_FILE=petscOptions.split"
    "BASE=base/snes NAME=poly.hypre USE_GMSH=1 USE_DUALMESH=1 USE_PERTURBMESHPOINTS=0 PETSC_FILE=petscOptions.split"
    "BASE=base/snes NAME=distHex.hypre USE_GMSH=0 USE_DUALMESH=0 USE_PERTURBMESHPOINTS=1 PETSC_FILE=petscOptions.split"
)
```
where the flags select the meshing route: `blockMesh` (hexahedral), Gmsh and
`polyDualMesh` (polyhedral), `blockMesh` and `perturbMeshPoints` (distorted
hexahedral). The PETSc options used by the solver are those in
`base/snes/system/fvSolution`, which take precedence over `PETSC_FILE`.
The `Allrun` script is executed as
```bash
./Allrun        # meshes 1-6
./Allrun 5      # meshes 1-5, the sequence plotted in the paper
```
which creates a directory for the cases called `run_<CPU_NAME>_<DATE_TIME>`, for
example, `run_Apple_M1_Ultra_20250118_151956`. Six pdf plots are produced
there: `mms_dispErrors.pdf`, `mms_stressErrors_v2.pdf`, `mms_pressureErrors.pdf`
and the corresponding `mms_*_orderOfAccuracy.pdf` figures. They are drawn by
`plotScripts/mms_paper_figures.py` in the shared manuscript style from the
`*.summary.txt` and `*.orderOfAccuracy.txt` tables of that run directory; the
"L2" columns are plotted as the cell-wise RMS error and the "Linf" columns as
the maximum error. The paper plots stop if a plotted value is missing or not a
number, for example the pressure columns of a run made without the pressure
error output.

Existing runs can be post-processed without running the solver:
```bash
./Allrun plots [run_dir]      # plot the existing tables
./Allrun extract [run_dir]    # rebuild the tables from the solver logs, then plot
PLOTTER=gnuplot ./Allrun plots [run_dir]   # the earlier gnuplot figures
PLOTTER=none ./Allrun 5       # run and extract only
```
`run_dir` defaults to the newest `run_*` directory. The axis windows of the
paper plots are those of the published figures (cell spacing 2.5 mm to 40 mm);
results outside them are reported in a warning.
