# Spherical Cavity

## Overview
This classic 3-D problem consists of a spherical cavity with radius a = 0.2 m
 in an infinite, isotropic linear elastic solid (E = 200 GPa, ν = 0.3). Far from
 the cavity, the solid is subjected to a tensile stress σzz = T = 1 MPa, with
 all other stress components zero.

## Instructions

### Compile `projectPointsToSphere` Utilty
The `projectPointsToSphere` utility is used to project the points of the cavity
surface to a sphere to ensure the geometry is correct to machine tolerance.
The `projectPointsToSphere` utility can be compiled with
```bash
wmake projectPointsToSphere
```

### Run the Cases
The `Allrun` runs the a mesh study for various mesh and solution procedure
configurations. The configurations are defined near the top of the `Allrun` script:
```bash
configs=(
    "BASE=base/snes NAME=poly.hypre PETSC_FILE=petscOptions.hypre"
    "BASE=base/segregated NAME=poly.seg"
e"
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