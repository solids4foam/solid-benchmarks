# Pressure stabilisation Fourier verification

This directory contains the Paper-1 benchmark and verification case for the
pressure-stabilisation Fourier symbols and spectral normalisation.

## Layout

- `pressureStabilisationFourier/`: executable OpenFOAM case, analytical
  checker, plotting scripts, visualisation workflow and invalid-input tests.
- `reports/verification-report.md`: verification report and provenance notes.

Generated CSVs, plots, meshes, logs, ParaView fields and post-processing
output are not publication source and are excluded by `.gitignore`. A local
`results/` directory may be retained for private comparisons, but it is not
required by any runner, checker or plotting script and is never committed.

## solids4foam requirement

The case requires the `stabilisationFourierCheck` utility from solids4foam.
Build both that executable and `libsolids4FoamModels` from the matching
spectral-normalisation-enabled solids4foam branch or commit before running the
case. Record the solids4foam commit alongside any newly curated results.

This directory does not build or carry a private baseline solids4foam library.
The executable and shared library must come from the same matching solids4foam
build. This avoids a hidden dependency on a second checkout or worktree.

## Run

After loading the matching OpenFOAM and solids4foam environment, ensure
`stabilisationFourierCheck` and `solids4FoamScripts.sh` are on `PATH`, then
run:

On macOS, the solids4foam `Allrun` and `Allclean` scripts require GNU sed (`gsed`).

```bash
cd pressureStabilisationFourier
./Allclean
./Allrun
python3 checkResults.py
```

This recreates the complete 825-check numerical campaign below
`postProcessing/stabilisationFourierCheck/` without consulting any historical
results. To regenerate the standard and paper-oriented figures, use a Python
environment containing NumPy and Matplotlib:

```bash
python3 plotSymbols.py
python3 plotPaperFigures.py
```

Generate the separate ParaView demonstration with:

```bash
./AllrunVisualisation
python3 plotVisualisationFields.py
paraFoam
```

`AllrunVisualisation` produces 45 cell-centred fields in time `0`: three
pressure modes, 21 production stabilisation fields and 21 synthetic filtered
fields. `Allclean` removes all generated case output while preserving the
source dictionaries and scripts, after which either workflow can be rerun.

For an isolated regression copy, run `./regressionTest.sh`. Its
`regressionTests/` directory is temporary and ignored.
