# Land Problem 1 Beam

## Overview
This 3-D beam problem follows problem 1 from Land et al. (2015).  The case is
set up to compare the displacement-only formulation with the mixed pressure
formulation using the stabilisation models in the current solids4foam
framework.

## Instructions

### Run the Cases
The `Allrun` runs a mesh study for:

```bash
displacement rhiechow laplacian jst evenlap_m0 evenlap_m1 evenlap_m2
```

The default sweep uses meshes 2 to 5.  The finest meshes are expensive when all
stabilisation methods are run, but the range can be overridden:

```bash
./Allrun
END_MESH=7 ./Allrun
```

The script creates `run_<CPU_NAME>_<DATE_TIME>`.  Each formulation is written to
its own sub-directory and the root run directory contains
`land_problem1_dz_comparison.pdf` when `gnuplot` is available.

The mixed pressure cases use `petscOptions.split`.  The default pressure
stabilisation scales are `1.0` for Rhie-Chow, Laplacian, JST, evenlap m0, and
evenlap m2.  The evenlap m1 case keeps the original Land problem 1 scale of
`10.0`.
