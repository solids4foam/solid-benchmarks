#!/usr/bin/env python3
"""Regression validation of the generated Cook's membrane case dictionaries.

The campaign sweeps the pressure-stabilisation residual coefficient `sp`, while
the approximate Jacobian coefficient is a fixed experimental control at 1.0.
An earlier revision assigned `scaleFactorJacobian = sp`, which silently changed
the preconditioner alongside the residual and invalidated the comparison.

This script drives the real preparation mechanism (`shutil.copytree` of the base
case followed by `workflow.configure_case`) for the complete full and test
campaigns, then re-reads the generated OpenFOAM `constant/solidProperties`
dictionaries with an independent parser.  It deliberately does not reuse
`workflow.validate_dictionary`, so it still fails if that validation is itself
weakened.
"""
from __future__ import annotations

import argparse
import importlib.util
import re
import shutil
import sys
import tempfile
from pathlib import Path

SCRIPTS = Path(__file__).resolve().parent
ROOT = SCRIPTS.parent

EXPECTED_JACOBIAN = 1.0
EXPECTED_NORMALISE = "true"
EXPECTED_REFERENCE_DIRECTIONS = 2
EXPECTED_MOMENTUM_TYPE = "diffStencilLaplacian"
EXPECTED_MOMENTUM_SCALES = {"0.1", "1.0"}
EXPECTED_PRESSURE_SCALES = ("0.01", "0.1", "1", "10", "100", "1000")
EXPECTED_PARAMETER_METHODS = {"evenlap_m0", "evenlap_m1", "evenlap_m2", "rhiechow"}
EXPECTED_COUNTS = {"structured": 72, "parameter": 288, "unstructured": 36}
EXPECTED_TOTAL = 396
FORBIDDEN_MOMENTUM_SCALES = {"0.2"}


def load_workflow():
    spec = importlib.util.spec_from_file_location("workflow", SCRIPTS / "workflow.py")
    if spec is None or spec.loader is None:
        raise RuntimeError("cannot load workflow.py")
    module = importlib.util.module_from_spec(spec)
    # Register before executing so dataclass field resolution can find the module.
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def read_block(text: str, name: str) -> str:
    """Return the body of a named dictionary block, independent of workflow.py."""
    match = re.search(rf"(?m)^\s*{re.escape(name)}\s*\{{", text)
    if not match:
        raise ValueError(f"block '{name}' not found")
    opening = text.index("{", match.start())
    depth = 0
    for position in range(opening, len(text)):
        if text[position] == "{":
            depth += 1
        elif text[position] == "}":
            depth -= 1
            if depth == 0:
                return text[opening + 1 : position]
    raise ValueError(f"block '{name}' is not closed")


def entry(block: str, key: str) -> str:
    matches = re.findall(rf"(?m)^\s*{re.escape(key)}\s+([^;\s]+)\s*;", block)
    if len(matches) != 1:
        raise ValueError(f"entry '{key}' occurs {len(matches)} times")
    return matches[0]


def check_case(dictionary: Path, spec, failures: list[str]) -> None:
    where = f"{spec.study}/{spec.method.tag}/sp={spec.sp}/sm={spec.sm}/mesh_{spec.mesh_index}"
    try:
        text = dictionary.read_text()
        stabilisation = read_block(text, "stabilisation")
        momentum = read_block(stabilisation, "momentum")
        pressure = read_block(stabilisation, "pressure")

        momentum_type = entry(momentum, "type")
        if momentum_type != EXPECTED_MOMENTUM_TYPE:
            failures.append(f"{where}: momentum type={momentum_type}")
        if float(entry(momentum, "scaleFactor")) != float(spec.sm):
            failures.append(f"{where}: momentum scaleFactor != sm={spec.sm}")

        pressure_type = entry(pressure, "type")
        if pressure_type != spec.method.pressure_type:
            failures.append(f"{where}: pressure type={pressure_type}")

        scale = float(entry(pressure, "scaleFactor"))
        if scale != float(spec.sp):
            failures.append(f"{where}: scaleFactor={scale}, expected sp={spec.sp}")

        jacobian = float(entry(pressure, "scaleFactorJacobian"))
        if jacobian != EXPECTED_JACOBIAN:
            failures.append(
                f"{where}: scaleFactorJacobian={jacobian}, expected {EXPECTED_JACOBIAN}"
            )
        # Explicit anti-regression: the Jacobian must not track the sweep.
        if float(spec.sp) != EXPECTED_JACOBIAN and jacobian == float(spec.sp):
            failures.append(
                f"{where}: scaleFactorJacobian tracks sp={spec.sp}; it must stay fixed"
            )

        normalise = entry(pressure, "normalise")
        if normalise != EXPECTED_NORMALISE:
            failures.append(f"{where}: normalise={normalise}")
        directions = int(entry(pressure, "referenceNyquistDirections"))
        if directions != EXPECTED_REFERENCE_DIRECTIONS:
            failures.append(f"{where}: referenceNyquistDirections={directions}")

        if spec.method.laplacian_power is not None:
            power = int(entry(pressure, "laplacianPower"))
            if power != spec.method.laplacian_power:
                failures.append(
                    f"{where}: laplacianPower={power}, expected {spec.method.laplacian_power}"
                )
    except (OSError, ValueError) as error:
        failures.append(f"{where}: {error}")


def check_structure(workflow, specs, mode: str, failures: list[str]) -> None:
    by_study: dict[str, list] = {}
    for spec in specs:
        by_study.setdefault(spec.study, []).append(spec)

    for study in ("structured", "parameter", "unstructured"):
        if study not in by_study:
            failures.append(f"{mode}: study '{study}' is missing")

    momentum = {spec.sm for spec in specs}
    forbidden = momentum & FORBIDDEN_MOMENTUM_SCALES
    if forbidden:
        failures.append(f"{mode}: forbidden momentum scales present: {sorted(forbidden)}")

    for study in ("structured", "parameter"):
        scales = {spec.sm for spec in by_study.get(study, [])}
        if scales != EXPECTED_MOMENTUM_SCALES:
            failures.append(f"{mode}: {study} sm={sorted(scales)}, expected 0.1 and 1.0")

    unstructured_sm = {spec.sm for spec in by_study.get("unstructured", [])}
    if unstructured_sm != {"1.0"}:
        failures.append(f"{mode}: unstructured sm={sorted(unstructured_sm)}, expected 1.0 only")

    parameter = by_study.get("parameter", [])
    methods = {spec.method.tag for spec in parameter}
    if methods != EXPECTED_PARAMETER_METHODS:
        failures.append(f"{mode}: parameter methods={sorted(methods)}")

    per_method = {
        tag: sorted({spec.sp for spec in parameter if spec.method.tag == tag}, key=float)
        for tag in methods
    }
    lists = {tuple(value) for value in per_method.values()}
    if len(lists) > 1:
        failures.append(f"{mode}: pressure-sweep models have differing sp lists: {per_method}")

    if mode == "full":
        expected_sp = sorted(EXPECTED_PRESSURE_SCALES, key=float)
        for tag, values in per_method.items():
            if values != expected_sp:
                failures.append(f"{mode}: {tag} sp={values}, expected {expected_sp}")
        for study, expected in EXPECTED_COUNTS.items():
            actual = len(by_study.get(study, []))
            if actual != expected:
                failures.append(f"{mode}: {study} has {actual} cases, expected {expected}")
        if len(specs) != EXPECTED_TOTAL:
            failures.append(f"{mode}: {len(specs)} cases, expected {EXPECTED_TOTAL}")


def run_mode(workflow, mode: str, failures: list[str]) -> int:
    specs = workflow.enumerate_specs(mode, "all")
    try:
        workflow.validate_specs(specs, mode, "all")
    except (OSError, RuntimeError, ValueError) as error:
        # Record and continue: the independent per-case checks below are the
        # authority, and must still run if workflow's own validation is broken.
        failures.append(f"{mode}: workflow.validate_specs failed: {error}")
    check_structure(workflow, specs, mode, failures)

    swept = {spec.sp for spec in specs if spec.study == "parameter"}
    if not any(float(value) != EXPECTED_JACOBIAN for value in swept):
        failures.append(f"{mode}: no sp differs from the fixed Jacobian; check has no teeth")

    with tempfile.TemporaryDirectory(prefix="cooks-validate-") as scratch:
        root = Path(scratch)
        for index, spec in enumerate(specs):
            base = (
                workflow.STRUCTURED_BASE
                if spec.study != "unstructured"
                else workflow.UNSTRUCTURED_BASE
            )
            case = root / f"case_{index:04d}"
            shutil.copytree(base, case)
            try:
                workflow.configure_case(case, spec)
            except (OSError, RuntimeError, ValueError) as error:
                failures.append(f"{mode}: case generation failed for {spec.relative_case}: {error}")
                shutil.rmtree(case)
                continue
            check_case(case / "constant" / "solidProperties", spec, failures)
            shutil.rmtree(case)
    return len(specs)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--mode",
        choices=("full", "test", "both"),
        default="both",
        help="campaign(s) to validate (default: both)",
    )
    args = parser.parse_args()
    workflow = load_workflow()

    configured = getattr(workflow, "JACOBIAN_SCALE", None)
    if configured is None:
        print(
            "FAIL: workflow.py defines no JACOBIAN_SCALE constant; the fixed "
            "Jacobian coefficient must not be derived from sp",
            file=sys.stderr,
        )
        return 1
    if configured != str(EXPECTED_JACOBIAN):
        print(
            f"FAIL: workflow.JACOBIAN_SCALE={configured!r}, "
            f"expected {str(EXPECTED_JACOBIAN)!r}",
            file=sys.stderr,
        )
        return 1

    modes = ("full", "test") if args.mode == "both" else (args.mode,)
    failures: list[str] = []
    counts: dict[str, int] = {}
    for mode in modes:
        counts[mode] = run_mode(workflow, mode, failures)

    if failures:
        print(f"FAIL: {len(failures)} validation error(s)", file=sys.stderr)
        for failure in failures[:40]:
            print(f"  {failure}", file=sys.stderr)
        if len(failures) > 40:
            print(f"  ... and {len(failures) - 40} more", file=sys.stderr)
        return 1

    for mode, count in counts.items():
        print(
            f"PASS: {mode} campaign, {count} generated dictionaries verified "
            f"(scaleFactor==sp, scaleFactorJacobian=={EXPECTED_JACOBIAN}, "
            f"normalise=={EXPECTED_NORMALISE}, "
            f"referenceNyquistDirections=={EXPECTED_REFERENCE_DIRECTIONS})"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
