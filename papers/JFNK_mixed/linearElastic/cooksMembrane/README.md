# Linear Cook's membrane paper reproduction

This directory prepares, runs and plots the normalised pressure-stabilisation
Cook's membrane campaign for Paper 1. The plots are drawn in the shared
manuscript style (`../../plotStyle/paper_figure_style.py`) from the results of
the campaign run in this checkout.

## Historical baseline

The original reproduction contained 180 simulations:

- 36 structured accuracy/timing cases: six pressure operators on six meshes,
  with `sp=10.0` and `sm=0.1`;
- 108 structured pressure-scale cases: coupled orders `m=0`, `m=1` and `m=2`
  on six meshes at `sp=0.01, 0.1, 1, 10, 100, 1000`, with `sm=0.1`;
- 36 unstructured verification cases: six pressure operators on six meshes,
  with `sp=10.0` and `sm=1.0`.

Those runs generated the structured displacement and execution-time/error
panels, the three order-specific pressure-scale panels, and the unstructured
displacement panel. Their plotting structure and visual style remain the basis
for the updated figures.

## Normalised campaign

Every generated pressure-stabilisation dictionary uses:

```text
normalise                    true;
referenceNyquistDirections   2;
scaleFactorJacobian          1.0;
```

`sp` sets the pressure-stabilisation **residual** coefficient (`scaleFactor`)
and is the only swept stabilisation parameter. The approximate **Jacobian**
coefficient (`scaleFactorJacobian`) is a fixed experimental control held at
`1.0` in every case, so that the sweep changes the residual operator alone and
not the preconditioner. It never tracks `sp`. `scripts/validate_campaign.py`
re-reads the generated dictionaries and fails if the two are ever relinked.

The nominal `sp` values are unchanged. The generalised model mapping is
`paper m = laplacianPower`, so powers 0, 1 and 2 are the coupled orders
`m=0`, `m=1` and `m=2` of the manuscript. The figure file names
`figure6_pressure_scale_{m1,m2,m3}_*` and the run names keep an earlier
one-based tag: file `m1` is `m=0`, `m2` is `m=1` and `m3` is `m=2`, while
`evenlap_mN` already means `laplacianPower N`. The campaign manifests also keep
their `method_label` and `paper_m` (`laplacianPower + 1`) columns in that
one-based form, so that newly generated manifests stay identical to the
archived campaign; only the plot legends use the manuscript index. Rhie--Chow
is a separate operator with its own spectral shape; it is not labelled as
coupled `m=1`.

The full 396-case matrix is:

| Study | Methods | Meshes | `sp` values | `sm` values | Cases |
| --- | ---: | ---: | ---: | ---: | ---: |
| Structured accuracy/timing | 6 | 6 | 1 | 2 | 72 |
| Structured pressure scale | 4 | 6 | 6 | 2 | 288 |
| Unstructured verification | 6 | 6 | 1 | 1 | 36 |

The six accuracy methods are Rhie--Chow, standalone Laplacian, JST, and the
three generalised orders. The pressure-scale study uses the three generalised
orders plus Rhie--Chow at every existing `sp`. Structured runs use both
`sm=1.0` and `sm=0.1`. The unstructured study deliberately remains a single
`sm=1.0` verification campaign.

The structured mesh sequence is `3, 6, 12, 24, 48, 96` cells per side, with
one cell through the thickness. The unstructured Gmsh spacings are
`16, 8, 4, 2, 1, 0.5`, with expected cell counts
`19, 62, 241, 941, 3793, 15131`. Material properties, loading, boundary
conditions, PETSc options, tolerances and the displacement sample point
`(48.0 60.0 0)` are inherited unchanged from the paper cases.

## Required solids4foam build

The executable and `libsolids4FoamModels` must come from a checkout containing
normalisation commit:

```text
329898141971d40e201ff2ee6ae4d19e8a97643c
```

That commit is on the `pr/spectral-normalisation` branch used for the paper
runs. The same change is in `solids4foam/solids4foam` on the
`fix-pressure-solid` branch as squash-merge commit

```text
12059d360780aab125d36170331c9c7d68b0ade2
```

(pull request 462), whose source tree is identical to the tip of
`pr/spectral-normalisation`. The workflow accepts either commit. On the HPC
system, load the desired OpenFOAM environment and build that solids4foam
checkout normally, for example:

```sh
export OPENFOAM_BASHRC=/path/to/OpenFOAM/etc/bashrc
source "$OPENFOAM_BASHRC"
export SOLIDS4FOAM_SOURCE=/path/to/normalisation-enabled/solids4foam
cd "$SOLIDS4FOAM_SOURCE"
./Allwmake
```

If the models library is outside `$FOAM_USER_LIBBIN` or `$FOAM_LIBBIN`, also
set `SOLIDS4FOAM_MODELS_LIB` to its absolute path. Before creating cases, the
workflow checks that one of these commits is an ancestor of the selected source
HEAD, that the source and compiled library contain normalisation markers, that
the solver links `libsolids4FoamModels`, and that `solids4Foam -help` loads.
The checked source HEAD, executable and library are recorded in generated run
provenance.

## Manifest and preparation checks

Enumerate and validate the complete matrix without writing cases:

```sh
./Allrun --list
./AllrunTest --list
```

Create all cheap-test dictionaries without meshing or solving:

```sh
./Allclean
./AllrunTest --prepare-only
```

This is useful for inspecting dictionaries with `foamDictionary` before an HPC
submission. Run `./Allclean` afterwards.

## Running locally or on HPC

Run the complete campaign and create the figures with:

```sh
export OPENFOAM_BASHRC=/path/to/OpenFOAM/etc/bashrc
export SOLIDS4FOAM_SOURCE=/path/to/normalisation-enabled/solids4foam
./Allrun
```

Individual stages are available as:

```sh
./Allrun structured
./Allrun parameter
./Allrun unstructured
./Allrun plots
```

The plotting stage reads the processed tables that the three studies of this
checkout wrote, `results/<mode>/normalised_r2/sm*/{structured,parameter,unstructured}.tsv`,
and stops if one of them is missing: all three studies have to be complete. It
never looks for a campaign anywhere else on its own.

To plot a raw campaign directory instead, name it: with
`COOKS_HPC_DATA_DIR=/path/to/campaign` (full mode only) the plotting stage reads
each campaign manifest, point-displacement file and solver log under that
directory without changing it. `COOKS_HPC_DATA_DIR=$PWD/runs/full ./Allrun plots`
re-extracts the campaign of this checkout in that way; a campaign run on
another machine can be plotted by copying its `runs/full` directory and naming
the copy.

`PLOTTER=none ./Allrun` runs the three studies without the plotting stage;
`./Allrun plots` makes the figures afterwards. The figures need Python with
NumPy and Matplotlib (`COOKS_PLOT_PYTHON` selects the interpreter). The
execution-time panels take the coupled `m = 2` result on the finest mesh of
the campaign as the displacement reference and show the meshes between the
coarsest and the finest.

For SLURM, preserve the historical serial execution convention:

```sh
sbatch --export=ALL,OPENFOAM_BASHRC=/path/to/bashrc,\
SOLIDS4FOAM_SOURCE=/path/to/solids4foam run.slurm
```

The job runs `./Allrun` itself, so extraction and plotting follow the
simulations inside the job and only when they succeeded. An optional module
can be loaded with `OPENFOAM_MODULE`, and an individual stage can be selected
with `COOKS_TARGET=structured`, `parameter`, `unstructured` or `plots`. Do not run stages concurrently in the same output
tree. The workflow refuses to overwrite existing cases and records each case
as `PENDING`, `RUNNING`, `OK` or `FAILED`; final result tables are written only
after every requested simulation succeeds.

## Configuration regression check

`scripts/validate_campaign.py` generates the complete full and test matrices
with the real preparation mechanism, then re-reads every generated
`constant/solidProperties` and checks the stabilisation settings
(`scaleFactor == sp`, `scaleFactorJacobian == 1.0`, `normalise true`,
`referenceNyquistDirections 2`, momentum scale, model and `laplacianPower`)
and the campaign structure (72 + 288 + 36 = 396 cases, `sm` of 0.1 and 1.0,
single-scope unstructured study). It needs no OpenFOAM environment and runs in
a temporary directory:

```sh
python3 scripts/validate_campaign.py
```

## Cheap test

The test uses the first two existing meshes and the existing `sp=10` pressure
scale. It exercises both momentum settings, all six accuracy methods, all four
pressure-sweep methods, the single-scope unstructured study, extraction and
separate figure generation:

```sh
./Allclean
./AllrunTest
```

It contains 24 structured accuracy runs, 16 pressure-scale runs and 12
unstructured runs, for 52 simulations. Like the full campaign, every test case
is generated with `scaleFactorJacobian 1.0`. It cannot select the full mesh or
pressure-scale matrix accidentally because those selections are fixed by test
mode in the shared generator.

## Output layout

Every case path records normalisation, momentum scale, study, model, pressure
scale where applicable, and mesh. For example:

```text
runs/full/normalised_r2/sm1p0/parameter/rhiechow/sp_0p1/mesh_03/
runs/full/normalised_r2/sm0p1/structured/evenlap_m2/mesh_06/
```

Locally run campaigns keep their processed tables and progress manifests in:

```text
results/<mode>/normalised_r2/sm1p0/{structured,parameter,unstructured}.tsv
results/<mode>/normalised_r2/sm0p1/{structured,parameter}.tsv
runs/<mode>/normalised_r2/provenance.txt
runs/<mode>/normalised_r2/<sm>/*_{manifest,progress}.tsv
```

Plots never combine momentum campaigns. Axis bounds are shared between the
two momentum campaigns. Colours, markers, fonts and sizes come from the shared
manuscript style. The generated PDFs, in `figures/<mode>/`, are:

```text
figure5_structured_displacement_sm1p0.pdf
figure5_execution_time_vs_error_sm1p0.pdf
figure6_pressure_scale_m1_sm1p0.pdf
figure6_pressure_scale_m2_sm1p0.pdf
figure6_pressure_scale_m3_sm1p0.pdf
figure6_pressure_scale_rhiechow_sm1p0.pdf
figure5_structured_displacement_sm0p1.pdf
figure5_execution_time_vs_error_sm0p1.pdf
figure6_pressure_scale_m1_sm0p1.pdf
figure6_pressure_scale_m2_sm0p1.pdf
figure6_pressure_scale_m3_sm0p1.pdf
figure6_pressure_scale_rhiechow_sm0p1.pdf
figure7b_unstructured_displacement.pdf
```

Only the first structured experiment retains both accuracy and
error-versus-execution-time panels. The pressure-scale and unstructured studies
retain their accuracy-only scope.

Clean generated cases, logs, tables and figures with:

```sh
./Allclean
```

Canonical bases, mesh definitions, plotting sources and benchmark reference
data are retained.
