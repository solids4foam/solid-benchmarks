# Pressure stabilisation Fourier verification

This case evaluates the production runtime-selected `stabilisationModel`
classes through `updateScalar(p, &gradP)` and `cellScalar(&rAUf, true)`.
It does not reconstruct a numerical stencil. Analytical predictions live
separately in `applications/utilities/stabilisationFourierCheck/fourierSymbols.H`.

The same framework runs the unchanged raw verification and a second campaign
with `normalise true` and `referenceNyquistDirections 2`. The mesh covers a
unit square with cyclic x/y boundaries and one empty z cell of thickness 0.1.
`Allrun` tests 16, 32 and 64 cells per active axis. All models use
`scaleFactor 0.37`. `rAUf` is exactly 1, with dimensions area/pressure.
The pressure gradient is explicitly `Gauss linear`, face interpolation is
`linear`, and normal gradients are `uncorrected`. These choices are part of
the diffStencil/RhieChow symbol; a wider gradient stencil changes that symbol.

## Build and run

Load an OpenFOAM environment first. The case runs on OpenFOAM.com and is
intended for OpenFOAM.org; foam-extend is skipped. Only OpenFOAM.com v2312
has been validated here. Standard repository installation builds the utility
through `applications/Allwmake`.

Build the matching spectral-normalisation-enabled solids4foam checkout first.
The utility and shared library must come from that same checkout:

```bash
cd /path/to/matching/solids4foam
source /path/to/OpenFOAM/etc/bashrc
cd src/solids4FoamModels
wmake libso
cd ../..
wmake applications/utilities/stabilisationFourierCheck
export PATH="$FOAM_MODULE_APPBIN:$PWD/applications/scripts:$PATH"

cd /path/to/paper1Code/papers/JFNK_mixed/fourierVerification/pressureStabilisationFourier
./Allclean
./Allrun
python3 checkResults.py
./regressionTest.sh
./regressionTest.sh --check-only
```

The case does not build or use a private baseline solids4foam library. Ensure
the selected `stabilisationFourierCheck` executable resolves the matching
normalisation-enabled `libsolids4FoamModels`.

A fresh checkout contains source infrastructure only: no CSVs, figures,
meshes, logs, post-processing output or ParaView fields are required.
`Allrun` generates all numerical inputs consumed by `checkResults.py` and the
plotting scripts. `Allclean` removes generated output but keeps the canonical
`system/blockMeshDict`, so the case remains immediately rerunnable.

On macOS, place GNU sed on PATH after loading OpenFOAM, for example
`export PATH="/opt/homebrew/opt/gnu-sed/libexec/gnubin:$PATH"`.
The repository's case-conversion helpers require GNU sed.

`Allrun` uses `foamDictionary -disableFunctionEntries` to preserve `$nCells`
while editing, then restores the original dictionary exactly. Without this
flag, edits expand the block's cell counts on the first run and subsequent
runs silently keep the first mesh resolution. The regression validator
checks the measured resolutions and requires distinct result files.

## Modes, errors and failures

`system/stabilisationFourierDict` lists all seven model configurations and
eight modes as `theta/pi` vectors. Add more vectors there; every component
must satisfy integer `k = N * (theta/pi) / 2`. Empty directions require zero.
The cosine phase uses integer cell indices recovered from the actual cell
centres, avoiding zero-amplitude Nyquist cosines at half-cell offsets.
Pressure boundary conditions are corrected before computing the gradient
and calling the operator. The mesh validator rejects nonuniform spacing,
non-Cartesian faces, invalid cell centres/volumes and unsupported boundaries.

Both the Rayleigh quotient and residual use cell volumes. CSVs report the
relative eigenvalue error, the requested relative eigenmode error, and
versions scaled by the full-checkerboard reference response. Relative errors
are blank for the constant mode, whose residual is checked against the
reference instead. Passing requires all applicable errors at most `1e-9`.
The utility writes the results before returning nonzero for numerical failure.

Every mode also compares the complete numerical fields for Laplacian/gen0,
JST/gen1 and diffStencil/RhieChow (`1e-12`). A secondary gamma check compares
`S_c` with `c*S_1` (`1e-14`) and requires bitwise equality between unit gamma
and the null-gamma interface. Set `gammaLinearityCheck 0` to disable it.
The regression validator requires both campaigns' coverage, all pass flags,
literal raw and normalised golden coefficients, the measured spacing ratios,
the reference response and the two negative-control modes. It also checks
nine constructor rejection cases for invalid `rStar`, unsupported models
and negative `laplacianPower`.
It uses only the Python standard library; plotting is optional.

## Outputs and options

Files are written below `postProcessing/stabilisationFourierCheck`:

- `results_<Nx>x<Ny>x<Nz>.csv`: one row per campaign/model/mode, including
  normalisation state, `rStar`, spectral relation, paper order where
  applicable, integer mode indices, both eigenvalues and error norms.
- `crossChecks_<resolution>.csv` and `gammaChecks_<resolution>.csv`:
  independent numerical pair and gamma comparisons.
- `symbols_<resolution>.csv` and `symbolMaps_<resolution>.csv`: analytical
  raw cuts and 2-D grids exported by `-symbolSweep`.
- `rejectionChecks.csv`: exit status and matched diagnostic for every invalid
  constructor configuration.

Metadata lines begin with `#`; use `pandas.read_csv(path, comment='#')`.
Model dictionaries are passed verbatim to the production selection table and
flattened into `params` without discarding additional settings.

```bash
stabilisationFourierCheck -dict stabilisationFourierDict -symbolSweep
stabilisationFourierCheck -writeFields -gammaLinearityCheck 0.37
python3 plotSymbols.py
```

`-dict` selects a dictionary name in `system`. `-writeFields` writes distinct
`fourierP_<campaign>_<model>_mode<i>` and
`fourierS_<campaign>_<model>_mode<i>` fields. It never
writes the production cache name `faceStabilisation(p)`, which uses
`READ_IF_PRESENT`. Sequential model scopes prevent registry-name reuse.
With a `fieldOutput` dictionary, the same option instead performs only the
named-mode field export, using the configured prefixes and without creating
regression CSV files.
`plotSymbols.py` requires matplotlib/numpy and reads only exported CSVs,
producing `verification.png` and `operatorComparison.png`; it contains no
analytical symbol formulas. Plot amplitudes are rescaled for presentation;
this does not normalise the production operators.
`verification.png` uses only the raw campaign (`normalise=0`), while
`operatorComparison.png` uses the raw analytical symbol maps.

## ParaView visualisation

Run the supplementary visualisation workflow on a single 16-by-16 mesh with:

```bash
./AllrunVisualisation
paraFoam
```

The repository responsibilities are deliberately separated. The general
solids4foam utility reads the named modes and runtime-selected model
dictionaries from `system/stabilisationFourierVisualisationDict`, then writes
only the original pressure modes and production stabilisation fields. This
case selects seven normalised models with `referenceNyquistDirections 2` and
the three modes:

- `xNyquist`, `(pi,0)`: alternating vertical stripes;
- `yNyquist`, `(0,pi)`: alternating horizontal stripes;
- `checkerboard`, `(pi,pi)`: alternating cells in both directions.

Exactly one original pressure field is written per mode as
`pMode_<mode>`. For every runtime-selected model and mode, `S_<model>_<mode>`
is the actual production stabilisation residual obtained through
`stabilisationModel::New`, `updateScalar` and `cellScalar`.

The case-specific `createIllustrativeFilteredFields.py` script measures each
model's `lambdaRef` directly from its exported checkerboard pressure and
production stabilisation fields. It then writes
`pIllustrativeFiltered_<model>_<mode>` using
`p + alpha*S`, where `alpha = visualisationOmega/abs(lambdaRef)` and
`visualisationOmega` is `0.5`. The output retains the pressure dimensions and
the cyclic/empty boundary definitions. This is a synthetic one-step
visualisation of the operator's spectral damping action. It is **not** an
update performed by the mixed pressure-displacement solver and must not be
interpreted as one.

This visualisation is supplementary. It is not a convergence test or a test
of solver stability, and it does not replace the CSV regression campaign.

All visualisation fields are cell-centred. In ParaView, disable the OpenFOAM
reader's automatic cell-to-point interpolation (`Create cell-to-point filtered
data`) and colour by the cell field. Point interpolation can obscure or cancel
Nyquist and checkerboard patterns. The expected pressure patterns are vertical
stripes for `xNyquist`, horizontal stripes for `yNyquist`, and alternating
neighbours in both directions for `checkerboard`.

For a pure Fourier eigenmode, `S[p] = lambda*p`, so the production
stabilisation field has the same pattern as `p`, with a different amplitude
and, for these damping operators, the opposite sign. Independently rescaled
colour maps can therefore make `p`, `S` and the illustrative filtered pressure
look deceptively identical. Use fixed ranges of `[-1,1]` for all pressure and
filtered-pressure comparisons. For the stabilisation fields in this case, use
`[-94.72,94.72]` to compare all modes and models against the common normalised
checkerboard response.

## Paper figures

The plotting scripts require NumPy and Matplotlib. On the validated macOS
system these are provided by `/opt/miniconda3/bin/python`; another Python
environment containing both packages is equally suitable.

After the standard Fourier campaign, generate the quantitative paper figures
from the exported CSV data with:

```bash
/opt/miniconda3/bin/python plotPaperFigures.py
```

This writes PNG and PDF versions of the reference-response comparison,
normalised spectral cuts, normalised spectral maps and verification-error
summary under `postProcessing/paperFigures/`. The script does not implement
the operator symbols: curves and maps are read from the utility's analytical
exports and measurements are read from the production result rows.

After `./AllrunVisualisation`, generate the supplementary mode/filter montage
with:

```bash
/opt/miniconda3/bin/python plotVisualisationFields.py
```

The montage uses representative operators by default. Pass `--models` followed
by any selection of `laplacian`, `gen0`, `JST`, `gen1`, `gen2`, `diffStencil`
and `RhieChow` to change its columns. The montage is explicitly illustrative
and is not a mixed-solver update.

## Raw and normalised symbols

The raw Laplacian and generalised power 0 have symbol `-4*s*sigma`, whereas
JST/generalised powers 1 and 2 retain a factor `1/h^2`. At fixed mode angles,
doubling N therefore leaves Laplacian/gen0 unchanged and multiplies the
other operators by four. This verifies the current special-case branch;
the normalized ideal paper-`m=1` branch instead scales as `1/h^2`.

For `a_q = sin^2(theta_q/2)` and `A = sum(a_q)`, the normalised coupled
family is

`lambda = -(s/h^2)*(A/rStar)^m`.

This includes the ideal normalised Laplacian at paper order `m=1`, JST and
generalised power 1 at `m=2`, and generalised power 2 at `m=3`. The
normalised diffStencil/RhieChow relation is separately checked as

`lambda = -(s/h^2)*sum(a_q^2)/rStar`.

It has the directionally split `m=2` spectral shape, but is neither the
coupled `m=2` operator nor a higher-order split-family implementation.

RhieChow uses the existing inheritance from diffStencil. Its symbol sums
fourth powers by direction; JST/gen1 square the sum of second powers.
The diagonal mode distinguishes their shapes. No higher-order directional
family, stabilisation algorithm change or solid solver change is included.

At the `rStar=2` checkerboard reference mode, every normalised model must
return `-s/h^2`. The `(pi,0)` and `(pi/2,pi/2)` modes independently
distinguish the coupled powers and split spectral shape. The legacy raw
paper-`m=1` mesh scaling remains documented and tested separately.
