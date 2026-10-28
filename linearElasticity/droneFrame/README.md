# Drone Frame: `droneFrame`

This case is referenced by the solids4foam workflow tutorial:

<https://www.solids4foam.com/tutorials/workflow-tutorials/droneFrame.html>

All details for constructing and running the case are described on that page.
This directory provides the final case for users who want to inspect the
completed setup or who get stuck while following the workflow steps.

The `Allrun` script downloads the STEP geometry of the quarter model from the
solids4foam website, generates the tetrahedral mesh with Gmsh, converts it to
OpenFOAM format and runs the solver. Gmsh and a solids4foam build with PETSc
support are required: the case uses the coupled `PETScSNES` solution algorithm
with the high-order (quadratic) discretisation, which are available from
solids4foam v2.4.
