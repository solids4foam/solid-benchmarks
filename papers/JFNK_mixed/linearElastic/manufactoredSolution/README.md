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
The `Allrun` runs a mesh study for each pressure stabilisation method used in
the Cook's membrane study:

```bash
rhiechow laplacian jst evenlap_m0 evenlap_m1 evenlap_m2
```

The mesh and solution procedure configurations are defined near the top of the
`Allrun` script:
```bash
configs=(
    "BASE=base/snes NAME=hex.hypre USE_GMSH=0 USE_DUALMESH=0 USE_PERTURBMESHPOINTS=0 PETSC_FILE=petscOptions.hypre"
    "BASE=base/snes NAME=tet.hypre USE_GMSH=1 USE_DUALMESH=0 USE_PERTURBMESHPOINTS=0 PETSC_FILE=petscOptions.hypre"
    "BASE=base/snes NAME=poly.hypre USE_GMSH=1 USE_DUALMESH=1 USE_PERTURBMESHPOINTS=0 PETSC_FILE=petscOptions.hypre"
    "BASE=base/snes NAME=distHex.hypre USE_GMSH=0 USE_DUALMESH=0 USE_PERTURBMESHPOINTS=1 PETSC_FILE=petscOptions.hypre"
    "BASE=base/snes NAME=hex.seg.hypre USE_GMSH=0 USE_DUALMESH=0 USE_PERTURBMESHPOINTS=0 PETSC_FILE=petscOptions.seg.hypre"
)
```
where various flags are used to specify meshing and solution procedure options.
The `Allrun` script is executed as
```bash
./Allrun
```
which creates a directory for the cases called `run_<CPU_NAME>_<DATE_TIME>`, for
example, `run_Apple_M1_Ultra_20250118_151956`. Six pdf plots are produced:
`mms_dispErrors.pdf`, `mms_stressErrors_v2.pdf`, `mms_pressureErrors.pdf` and
the corresponding `mms_*_orderOfAccuracy.pdf` figures. The results for each pressure
stabilisation are written in sub-directories named after the stabilisation
method. When the `Allrun` script completes, pdf plots will be available in each
method directory, if `gnuplot` is installed.
