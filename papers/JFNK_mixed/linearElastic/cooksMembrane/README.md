# Linear Cook's membrane paper reproduction

This directory prepares and plots the normalised pressure-stabilisation Cook's
membrane campaign for Paper 1. The cases and visual conventions come from the
historical plots. Full paper plots are now generated directly from the new HPC
archive; the plotting workflow only reads that archive.

## Historical baseline

The original reproduction contained 180 simulations:

- 36 structured accuracy/timing cases: six pressure operators on six meshes,
  with `sp=10.0` and `sm=0.1`;
- 108 structured pressure-scale cases: paper orders `m=1`, `m=2` and `m=3`
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
`paper m = laplacianPower + 1`, so powers 0, 1 and 2 are paper orders 1, 2 and
3. Rhie--Chow is a separate operator with its own spectral shape; it is not
labelled as coupled `m=2`.

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

The current integration branch is `pr/spectral-normalisation`. On the HPC
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
workflow checks that the required commit is an ancestor of the selected source
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

In full mode, the plotting stage reads raw results from a case-local `DataHPC`
directory when present, otherwise from the repository-level `../../dataHPC`
archive used by this checkout. It reads each campaign manifest,
point-displacement file and solver log without changing the archive. If the
archive is stored elsewhere, set `COOKS_HPC_DATA_DIR` to its root. The
cheap-test plotting stage continues to read its locally generated
`results/test` tables.

For SLURM, preserve the historical serial execution convention:

```sh
sbatch --export=ALL,OPENFOAM_BASHRC=/path/to/bashrc,\
SOLIDS4FOAM_SOURCE=/path/to/solids4foam run.slurm
```

An optional module can be loaded with `OPENFOAM_MODULE`, and an individual
stage can be selected with `COOKS_TARGET=structured`, `parameter`,
`unstructured` or `plots`. Do not run stages concurrently in the same output
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

Plots never combine momentum campaigns. The shared axis bounds and original
fonts, dimensions, colours, markers, line styles and legend placement are
retained wherever possible. The paper's displacement-axis headroom and linear
tick spacing are retained so that the inside upper-right legends do not hide
refined-mesh data. Rhie--Chow uses triangle markers with the existing `sp`
colour. The generated PDFs are:

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
