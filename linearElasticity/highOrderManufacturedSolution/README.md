# Method of Manufactured Solutions

Prepared by Ivan Batistić, Pablo Castrillo and Philip Cardiff

---

## Overview

This test case applies a manufactured solution to a 2D and 3D square domain and measures the
accuracy and order of accuracy for the displacement and stress fields on various mesh types.  

The keyword **highOrder** is added to distinguish this case from the manufacturedSolution case, which uses a different form of analytical solution. Here, the 2D and 3D examples use different forms of the solution, as given below. The setup is the same as in the following references:

- Castrillo, Pablo, et al. "High-order finite volume method for linear elasticity on unstructured meshes." *Computers & Structures* 268, 2022.
- Castrillo, Pablo, Eugenio Schillaci, and Joaquim Rigola. "High-order cell-centered finite volume method for solid dynamics on unstructured meshes." *Computers & Structures* 295, 2024.

### 2D case

$$
u_x(x,y) = e^{x^2}\sin(y),\\
u_y(x,y) = \ln(3+y)\cos(x)+\sin(y),\\
u_z(x,y) = 0.
$$

### 3D case

$$
u_x(x,y) = \ln(x+3)y(z+1)+e^z,\\
u_y(x,y) = \sin(yz) + 3y,\\
u_z(x,y) = e^{xz}y-4\cos(z).
$$

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
(cd manufacturedSolution && ./Allwmake -j -s)
```

### Run the Cases
The `Allrun` runs the a mesh study for various mesh and solution procedure
configurations. The configurations are defined near the top of the `Allrun` script:
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
example, `run_Apple_M1_Ultra_20250118_151956`. When the `Allrun` script
completes, pdf plots will be available in the directory, if `gnuplot` is
installed.