#!/usr/bin/env python3
"""Create synthetic filtered pressure fields from exported production fields.

For each model, lambdaRef is measured by a Rayleigh quotient from the exported
checkerboard pressure and stabilisation fields. No analytical stabilisation
formula is implemented here. The generated field is the visualisation-only

    pIllustrativeFiltered = p + omega/abs(lambdaRef) * S[p]

and is not an update performed by the mixed pressure-displacement solver.
"""

import argparse
import csv
import math
import re
from dataclasses import dataclass
from pathlib import Path


INTERNAL_FIELD = re.compile(
    r"internalField\s+nonuniform\s+List<scalar>\s+"
    r"(\d+)\s*\(\s*(.*?)\s*\)\s*;",
    re.DOTALL,
)
OBJECT_ENTRY = re.compile(r"(^\s*object\s+)\S+(\s*;)", re.MULTILINE)
DIMENSIONS_ENTRY = re.compile(r"^\s*dimensions\s+\[([^]]+)\]\s*;", re.MULTILINE)
BOUNDARY_FIELD = re.compile(r"boundaryField\s*(\{.*\})\s*//", re.DOTALL)
BOUNDARY_TYPE = re.compile(r"\btype\s+(\w+)\s*;")


@dataclass
class ScalarField:
    path: Path
    text: str
    dimensions: tuple
    values: list
    boundary: str
    boundary_types: tuple


def read_scalar_entry(text, name):
    match = re.search(
        rf"^\s*{re.escape(name)}\s+([^;\s]+)\s*;",
        text,
        re.MULTILINE,
    )
    if not match:
        raise RuntimeError(f"Missing {name} in visualisation dictionary")
    value = float(match.group(1))
    if not math.isfinite(value):
        raise RuntimeError(f"{name} must be finite")
    return value


def read_field(path):
    if not path.is_file():
        raise RuntimeError(f"Missing OpenFOAM field {path}")
    text = path.read_text()
    internal = INTERNAL_FIELD.search(text)
    dimensions = DIMENSIONS_ENTRY.search(text)
    boundary = BOUNDARY_FIELD.search(text)
    if not internal or not dimensions or not boundary:
        raise RuntimeError(f"Unsupported OpenFOAM scalar-field format in {path}")
    count = int(internal.group(1))
    values = [float(value) for value in internal.group(2).split()]
    if len(values) != count:
        raise RuntimeError(
            f"Expected {count} internal values in {path}, found {len(values)}"
        )
    dimension_values = tuple(int(value) for value in dimensions.group(1).split())
    if len(dimension_values) != 7:
        raise RuntimeError(f"Expected seven dimensions in {path}")
    boundary_text = boundary.group(1)
    if re.search(r"^\s*value\s+", boundary_text, re.MULTILINE):
        raise RuntimeError(
            f"Explicit boundary values in {path} require field arithmetic in OpenFOAM"
        )
    return ScalarField(
        path,
        text,
        dimension_values,
        values,
        boundary_text,
        tuple(BOUNDARY_TYPE.findall(boundary_text)),
    )


def dot(left, right):
    return sum(a * b for a, b in zip(left, right))


def measured_eigenvalue(pressure, stabilisation):
    denominator = dot(pressure, pressure)
    if denominator <= 0:
        raise RuntimeError("Cannot measure an eigenvalue from a zero pressure field")
    return dot(pressure, stabilisation) / denominator


def replace_internal_field(text, values):
    formatted = "\n".join(f"{value:.17g}" for value in values)
    replacement = (
        "internalField   nonuniform List<scalar> \n"
        f"{len(values)}\n(\n{formatted}\n)\n;"
    )
    result, count = INTERNAL_FIELD.subn(replacement, text, count=1)
    if count != 1:
        raise RuntimeError("Could not replace OpenFOAM internal field")
    return result


def write_field(template, path, name, values):
    text, count = OBJECT_ENTRY.subn(
        lambda match: match.group(1) + name + match.group(2),
        template.text,
        count=1,
    )
    if count != 1:
        raise RuntimeError(f"Could not replace object name in {template.path}")
    path.write_text(replace_internal_field(text, values))


def discover_fields(time_directory, pressure_prefix, stabilisation_prefix):
    pressure_paths = {
        path.name[len(pressure_prefix) + 1:]: path
        for path in time_directory.glob(f"{pressure_prefix}_*")
    }
    if not pressure_paths:
        raise RuntimeError(f"No {pressure_prefix}_* fields in {time_directory}")

    modes_by_length = sorted(pressure_paths, key=len, reverse=True)
    stabilisation_paths = {}
    for path in time_directory.glob(f"{stabilisation_prefix}_*"):
        for mode in modes_by_length:
            suffix = "_" + mode
            if path.name.endswith(suffix):
                model = path.name[len(stabilisation_prefix) + 1:-len(suffix)]
                if not model:
                    raise RuntimeError(f"Cannot determine model name from {path}")
                key = (model, mode)
                if key in stabilisation_paths:
                    raise RuntimeError(f"Duplicate stabilisation field for {key}")
                stabilisation_paths[key] = path
                break
        else:
            raise RuntimeError(f"Cannot match {path} to an exported pressure mode")

    models = sorted({key[0] for key in stabilisation_paths})
    missing = [
        (model, mode)
        for model in models
        for mode in pressure_paths
        if (model, mode) not in stabilisation_paths
    ]
    if missing:
        raise RuntimeError(f"Missing stabilisation fields: {missing}")
    return pressure_paths, stabilisation_paths, models


def compatible(pressure, stabilisation):
    if len(pressure.values) != len(stabilisation.values):
        raise RuntimeError(
            f"Field-size mismatch: {pressure.path} and {stabilisation.path}"
        )
    if pressure.boundary_types != stabilisation.boundary_types:
        raise RuntimeError(
            f"Boundary-type mismatch: {pressure.path} and {stabilisation.path}"
        )


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--time", default="0", help="OpenFOAM time directory")
    parser.add_argument(
        "--dict",
        default="system/stabilisationFourierVisualisationDict",
        help="visualisation dictionary containing visualisationOmega",
    )
    parser.add_argument("--reference-mode", default="checkerboard")
    parser.add_argument("--pressure-prefix", default="pMode")
    parser.add_argument("--stabilisation-prefix", default="S")
    parser.add_argument("--output-prefix", default="pIllustrativeFiltered")
    parser.add_argument(
        "--report",
        default=(
            "postProcessing/stabilisationFourierVisualisation/"
            "filteredFieldChecks.csv"
        ),
    )
    args = parser.parse_args()

    dictionary_text = Path(args.dict).read_text()
    omega = read_scalar_entry(dictionary_text, "visualisationOmega")
    tolerance = read_scalar_entry(dictionary_text, "tolerance")
    if omega < 0:
        parser.error("visualisationOmega must be non-negative")

    time_directory = Path(args.time)
    pressure_paths, stabilisation_paths, models = discover_fields(
        time_directory,
        args.pressure_prefix,
        args.stabilisation_prefix,
    )
    if args.reference_mode not in pressure_paths:
        parser.error(f"Missing reference mode {args.reference_mode}")

    pressures = {
        mode: read_field(path) for mode, path in pressure_paths.items()
    }
    reference_pressure = pressures[args.reference_mode]
    reference_eigenvalues = {}
    alpha_dimensions = {}
    for model in models:
        reference_stabilisation = read_field(
            stabilisation_paths[(model, args.reference_mode)]
        )
        compatible(reference_pressure, reference_stabilisation)
        reference = measured_eigenvalue(
            reference_pressure.values,
            reference_stabilisation.values,
        )
        if not math.isfinite(reference) or reference == 0:
            raise RuntimeError(f"Invalid measured reference eigenvalue for {model}")
        reference_eigenvalues[model] = reference
        alpha_dimensions[model] = tuple(
            pressure_dimension - stabilisation_dimension
            for pressure_dimension, stabilisation_dimension in zip(
                reference_pressure.dimensions,
                reference_stabilisation.dimensions,
            )
        )

    report_path = Path(args.report)
    report_path.parent.mkdir(parents=True, exist_ok=True)
    maximum_error = 0.0
    written = 0
    with report_path.open("w", newline="") as stream:
        writer = csv.writer(stream)
        writer.writerow(
            (
                "model",
                "mode",
                "lambdaRef",
                "lambdaMode",
                "alpha",
                "alphaDimensions",
                "filteredAmplitudeFactor",
                "maxEigenmodeError",
            )
        )
        for model in models:
            reference = reference_eigenvalues[model]
            alpha = omega / abs(reference)
            for mode, pressure in pressures.items():
                stabilisation = read_field(stabilisation_paths[(model, mode)])
                compatible(pressure, stabilisation)
                eigenvalue = measured_eigenvalue(
                    pressure.values,
                    stabilisation.values,
                )
                factor = 1.0 + alpha * eigenvalue
                filtered = [
                    pressure_value + alpha * stabilisation_value
                    for pressure_value, stabilisation_value in zip(
                        pressure.values,
                        stabilisation.values,
                    )
                ]
                error = max(
                    abs(value - factor * pressure_value)
                    for value, pressure_value in zip(filtered, pressure.values)
                )
                maximum_error = max(maximum_error, error)
                name = f"{args.output_prefix}_{model}_{mode}"
                write_field(pressure, time_directory / name, name, filtered)
                written += 1
                writer.writerow(
                    (
                        model,
                        mode,
                        f"{reference:.17g}",
                        f"{eigenvalue:.17g}",
                        f"{alpha:.17g}",
                        "[" + " ".join(map(str, alpha_dimensions[model])) + "]",
                        f"{factor:.17g}",
                        f"{error:.17g}",
                    )
                )
                print(
                    f"{model} {mode}: lambdaRef={reference:.17g} "
                    f"lambda={eigenvalue:.17g} factor={factor:.17g} "
                    f"error={error:.3e}"
                )

    print(
        f"Wrote {written} synthetic fields; maximum eigenmode error "
        f"{maximum_error:.3e}; report {report_path}"
    )
    if maximum_error > tolerance:
        raise RuntimeError(
            f"Filtered-field error {maximum_error} exceeds tolerance {tolerance}"
        )


if __name__ == "__main__":
    main()
