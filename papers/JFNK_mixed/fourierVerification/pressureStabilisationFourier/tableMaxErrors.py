#!/usr/bin/env python3
"""Reproduce Table "Maximum errors in the Fourier verification"
(tab:fourier_verification_errors) from the results_*.csv files.

Takes the maximum of
relativeEigenvalueError (E_lambda), eigenmodeErr (E_mode) and eigenmodeErrRef
(reference-scaled eigenmode error) over all models, meshes and modes, separately
for normalise=0 (unnormalised) and normalise=1 (normalised). Empty entries
(constant mode for the relative errors) are skipped, as stated in the caption.

Usage: python3 tableMaxErrors.py [postProcessing/stabilisationFourierCheck]

The directory is the one written by ./Allrun (default: relative to the current
directory). The script stops if it holds no results_*.csv file.
"""
import csv, glob, os, sys

directory = sys.argv[1] if len(sys.argv) > 1 else os.path.join("postProcessing", "stabilisationFourierCheck")
if not glob.glob(os.path.join(directory, "results_*.csv")):
    raise SystemExit(f"ERROR: no results_*.csv in {directory}")
metrics = (("relativeEigenvalueError", "E_lambda"),
           ("eigenmodeErr", "E_mode"),
           ("eigenmodeErrRef", "Reference-scaled eigenmode error"))
maxima = {}
for path in sorted(glob.glob(os.path.join(directory, "results_*.csv"))):
    with open(path) as stream:
        for row in csv.DictReader(l for l in stream if not l.startswith("#")):
            for key, _ in metrics:
                if row[key]:
                    k = (row["normalise"], key)
                    maxima[k] = max(maxima.get(k, 0.0), float(row[key]))
missing = [f"{label} (normalise={flag})" for key, label in metrics for flag in ("0", "1") if (flag, key) not in maxima]
if missing:
    raise SystemExit(f"ERROR: no values in {directory} for: " + ", ".join(missing))
print(f"{'Error measure':34s} {'Unnormalised':>14s} {'Normalised':>14s}")
for key, label in metrics:
    print(f"{label:34s} {maxima[('0', key)]:14.2e} {maxima[('1', key)]:14.2e}")
