# Idealised Ventricle Inflation Stabilisation Sweep

This case is a stabilisation-framework-compatible copy of the idealised
ventricle inflation benchmark.  The original `../base` case is left unchanged.

The sweep uses the SNES mixed pressure-displacement formulation with the new
dictionary form:

```text
stabilisation
{
    momentum
    {
        type        diffStencilLaplacian;
        scaleFactor 0.1;
    }

    pressure
    {
        type                <method>;
        scaleFactor         <value>;
        scaleFactorJacobian <value>;
    }
}
```

The case provides pressure stabilisation dictionaries for `RhieChow`,
`laplacian`, `JamesonSchmidtTurkel`, and `generalisedEvenOrderLaplacian` with
`laplacianPower` values `0`, `1`, and `2`.

The default `Allrun` sweep runs the methods currently validated on mesh 1 for
this transient inflation case: `RhieChow`, `JamesonSchmidtTurkel`, and
`generalisedEvenOrderLaplacian` with `laplacianPower 1`.  The `laplacian`,
`evenlap_m0`, and `evenlap_m2` dictionaries are included for follow-up tuning,
but they are not part of the default sweep because they showed pressure-block
linear-solver issues with the supplied PETSc options.

The default mesh sweep is meshes `1` to `4`, matching the original benchmark.
For a quick check, run for one mesh:

```bash
START_MESH=1 END_MESH=1 ./Allrun
```

To force a specific method or include the full method set:

```bash
STABS=laplacian START_MESH=1 END_MESH=1 ./Allrun
STABS=all START_MESH=1 END_MESH=1 ./Allrun
```

The script compiles `../extractIdealisedVentricleResults` if it is not already
available, extracts `midLineDeformed.txt` for each case, and creates midline,
runtime, and linear-iteration plots when `gnuplot` is installed.
