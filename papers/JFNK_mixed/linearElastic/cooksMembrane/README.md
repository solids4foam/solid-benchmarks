# Linear Cook's membrane paper reproduction

This directory reproduces the numerical results and the six retained Cook's
membrane panels used by the paper.  The cases and plotting conventions were
migrated from the original `DataHPC` calculations; the reproduction scripts do
not refer back to that external directory.

## Requirements

Run from a shell with the OpenFOAM-v2312 and solids4foam environment loaded.
The workflow checks for the applications it needs before creating cases:

- `python3`
- `blockMesh`
- `solids4Foam`
- `gmsh`, `gmshToFoam`, `changeDictionary` and `checkMesh` for the unstructured study
- the Python `reportlab` package for plotting

`Allrun` re-sources `$WM_PROJECT_DIR/etc/bashrc` before starting.  If the
OpenFOAM environment file is elsewhere, set `OPENFOAM_BASHRC` to its path.
The prerequisite check executes `solids4Foam -help`, so a binary with missing
dynamic libraries is rejected before the first case is generated.

## Workflows

Run the complete 180-case paper calculation and create all figures with:

```sh
./Allrun
```

Individual stages are available as:

```sh
./Allrun structured
./Allrun parameter
./Allrun unstructured
./Allrun plots
```

The individual numerical stages can be run sequentially.  `./Allrun plots`
requires all three processed result tables for the selected mode.

The end-to-end test uses exactly the same implementation but selects mesh
indices 1 and 2:

```sh
./AllrunTest
```

It still runs all methods and parameter combinations: 12 structured cases, 36
pressure-scale cases and 12 unstructured cases, for 60 simulations in total.

Before running, enumerate and validate the exact manifest without creating any
cases:

```sh
./AllrunTest --list
./Allrun --list
```

Clean all generated cases, logs, result tables and figures with:

```sh
./Allclean
```

`Allclean` retains the canonical bases, mesh definitions, plotting code,
benchmark data and the user-supplied `unstructured/0.1` migration archive.

## Scientific configuration

The structured mesh sequence is `3, 6, 12, 24, 48, 96` cells per side, with
one cell through the thickness.  Study 1 uses `sp=10.0` and `sm=0.1` for
Rhie-Chow, Laplacian, JST and generalised even-order Laplacian powers 0, 1 and
2.  The latter correspond to the paper labels `m=1`, `m=2` and `m=3`.

The pressure-scale study holds `sm=0.1` and sweeps
`sp=0.01, 0.1, 1, 10, 100, 1000` for all three even-Laplacian powers.

The unstructured study uses the six Gmsh spacings `16, 8, 4, 2, 1, 0.5`, whose
nominal resolutions are again `3, 6, 12, 24, 48, 96` cells per side.  The
expected mesh cell counts are `19, 62, 241, 941, 3793, 15131`.  All six methods
use `sp=10.0` and `sm=1.0`.  Generated dictionaries and mesh cell counts are
validated before solving or accepting results.

The measured value is vertical displacement at `(48.0 60.0 0)`.  The final
data row's `Dy` is retained as `dy_raw` and multiplied by `0.001` for plotting.
Only Study 1 extracts `ExecutionTime`.  Its error reference is the finest
available structured `evenlap_m2` result: mesh 2 in test mode and mesh 6 in
full mode.

## Generated files

Raw cases and logs are written below `runs/test` or `runs/full`.  Deterministic
processed tables are written to:

```text
results/<mode>/structured.tsv
results/<mode>/parameter.tsv
results/<mode>/unstructured.tsv
```

Only these paper PDFs are generated below `figures/<mode>`:

```text
figure5_structured_displacement.pdf
figure5_execution_time_vs_error.pdf
figure6_pressure_scale_m1.pdf
figure6_pressure_scale_m2.pdf
figure6_pressure_scale_m3.pdf
figure7b_unstructured_displacement.pdf
```

The benchmark data and paper-style renderer are in `plotScripts`.  Solver logs
are never parsed directly by the plotting code.
