#!/usr/bin/env python3
"""Generate, run, extract and plot the linear Cook's membrane paper cases."""

from __future__ import annotations

import argparse
import csv
import math
import os
import re
import shutil
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
STRUCTURED_BASE = ROOT / "base" / "hex.snes"
UNSTRUCTURED_BASE = ROOT / "unstructured" / "base"
PLOTTER = ROOT / "plotScripts" / "plot_paper.py"

MESH_CELLS_PER_SIDE = {1: 3, 2: 6, 3: 12, 4: 24, 5: 48, 6: 96}
UNSTRUCTURED_CELLS = {1: 19, 2: 62, 3: 241, 4: 941, 5: 3793, 6: 15131}
PRESSURE_SCALES = ("0.01", "0.1", "1", "10", "100", "1000")


@dataclass(frozen=True)
class Method:
    tag: str
    label: str
    pressure_type: str
    laplacian_power: int | None = None

    @property
    def paper_m(self) -> int | None:
        return None if self.laplacian_power is None else self.laplacian_power + 1


METHODS = (
    Method("rhiechow", "Rhie-Chow", "RhieChow"),
    Method("laplacian", "Laplacian", "laplacian"),
    Method("jst", "JST", "JamesonSchmidtTurkel"),
    Method("evenlap_m0", "Even Laplacian, m=1", "generalisedEvenOrderLaplacian", 0),
    Method("evenlap_m1", "Even Laplacian, m=2", "generalisedEvenOrderLaplacian", 1),
    Method("evenlap_m2", "Even Laplacian, m=3", "generalisedEvenOrderLaplacian", 2),
)
EVEN_METHODS = METHODS[3:]


@dataclass(frozen=True)
class CaseSpec:
    study: str
    method: Method
    mesh_index: int
    sp: str
    sm: str
    relative_case: Path

    @property
    def cells_per_side(self) -> int:
        return MESH_CELLS_PER_SIDE[self.mesh_index]


RESULT_FIELDS = (
    "study",
    "case",
    "mesh_index",
    "cells_per_side",
    "actual_cells",
    "method",
    "method_label",
    "paper_m",
    "laplacian_power",
    "sp",
    "sm",
    "dy_raw",
    "dy_scaled",
    "execution_time_s",
    "solver_log",
    "status",
)


def mesh_indices(mode: str) -> tuple[int, ...]:
    return (1, 2) if mode == "test" else (1, 2, 3, 4, 5, 6)


def scale_slug(value: str) -> str:
    return value.replace(".", "p")


def enumerate_specs(mode: str, target: str) -> list[CaseSpec]:
    meshes = mesh_indices(mode)
    specs: list[CaseSpec] = []
    if target in {"all", "structured"}:
        for method in METHODS:
            for mesh in meshes:
                specs.append(
                    CaseSpec(
                        "structured",
                        method,
                        mesh,
                        "10.0",
                        "0.1",
                        Path("structured") / method.tag / f"mesh_{mesh:02d}",
                    )
                )
    if target in {"all", "parameter"}:
        for method in EVEN_METHODS:
            for sp in PRESSURE_SCALES:
                for mesh in meshes:
                    specs.append(
                        CaseSpec(
                            "parameter",
                            method,
                            mesh,
                            sp,
                            "0.1",
                            Path("parameter")
                            / f"m{method.paper_m}"
                            / f"sp_{scale_slug(sp)}"
                            / f"mesh_{mesh:02d}",
                        )
                    )
    if target in {"all", "unstructured"}:
        for method in METHODS:
            for mesh in meshes:
                specs.append(
                    CaseSpec(
                        "unstructured",
                        method,
                        mesh,
                        "10.0",
                        "1.0",
                        Path("unstructured") / method.tag / f"mesh_{mesh:02d}",
                    )
                )
    return specs


def find_named_block(text: str, name: str) -> tuple[int, int]:
    match = re.search(rf"(?m)^\s*{re.escape(name)}\s*\{{", text)
    if not match:
        raise ValueError(f"dictionary block '{name}' not found")
    opening = text.find("{", match.start())
    depth = 0
    for position in range(opening, len(text)):
        if text[position] == "{":
            depth += 1
        elif text[position] == "}":
            depth -= 1
            if depth == 0:
                return opening + 1, position
    raise ValueError(f"dictionary block '{name}' is not closed")


def replace_block_entry(text: str, block_name: str, key: str, value: str) -> str:
    start, end = find_named_block(text, block_name)
    block = text[start:end]
    pattern = re.compile(rf"(?m)^(\s*{re.escape(key)}\s+)[^;\s]+(\s*;)")
    block, count = pattern.subn(rf"\g<1>{value}\g<2>", block, count=1)
    if count != 1:
        raise ValueError(f"entry '{key}' not found exactly once in block '{block_name}'")
    return text[:start] + block + text[end:]


def block_entry(text: str, block_name: str, key: str) -> str:
    start, end = find_named_block(text, block_name)
    block = text[start:end]
    matches = re.findall(rf"(?m)^\s*{re.escape(key)}\s+([^;\s]+)\s*;", block)
    if len(matches) != 1:
        raise ValueError(
            f"entry '{key}' occurs {len(matches)} times in block '{block_name}'"
        )
    return matches[0]


def validate_dictionary(text: str, method: Method, sp: str, sm: str, source: Path) -> None:
    errors: list[str] = []
    try:
        momentum_type = block_entry(text, "momentum", "type")
        momentum_scale = block_entry(text, "momentum", "scaleFactor")
        pressure_type = block_entry(text, "pressure", "type")
        pressure_scale = block_entry(text, "pressure", "scaleFactor")
        jacobian_scale = block_entry(text, "pressure", "scaleFactorJacobian")
        if momentum_type != "diffStencilLaplacian":
            errors.append(f"momentum type={momentum_type}")
        if not math.isclose(float(momentum_scale), float(sm)):
            errors.append(f"sm={momentum_scale}, expected {sm}")
        if pressure_type != method.pressure_type:
            errors.append(f"pressure type={pressure_type}, expected {method.pressure_type}")
        if not math.isclose(float(pressure_scale), float(sp)):
            errors.append(f"sp={pressure_scale}, expected {sp}")
        if not math.isclose(float(jacobian_scale), float(sp)):
            errors.append(f"Jacobian sp={jacobian_scale}, expected {sp}")
        if method.laplacian_power is not None:
            power = int(block_entry(text, "pressure", "laplacianPower"))
            if power != method.laplacian_power:
                errors.append(f"laplacianPower={power}, expected {method.laplacian_power}")
    except (ValueError, TypeError) as error:
        errors.append(str(error))
    if errors:
        raise RuntimeError(f"invalid stabilisation dictionary {source}: " + "; ".join(errors))


def validate_sources() -> None:
    for base, sp, sm in (
        (STRUCTURED_BASE, "10.0", "0.1"),
        (UNSTRUCTURED_BASE, "10.0", "1.0"),
    ):
        for method in METHODS:
            path = base / "constant" / f"solidProperties.{method.tag}"
            if not path.is_file():
                raise RuntimeError(f"required canonical dictionary is missing: {path}")
            validate_dictionary(path.read_text(), method, sp, sm, path)
        control_dict = base / "system" / "controlDict"
        text = control_dict.read_text()
        if not re.search(r"point\s*\(\s*48\.0\s+60\.0\s+0\s*\)\s*;", text):
            raise RuntimeError(f"Cook displacement point is missing from {control_dict}")

    for mesh, cells_per_side in MESH_CELLS_PER_SIDE.items():
        path = STRUCTURED_BASE / "system" / f"blockMeshDict.{mesh}"
        text = path.read_text()
        pattern = rf"hex\s*\([^)]*\)\s*\(\s*{cells_per_side}\s+{cells_per_side}\s+1\s*\)"
        if not re.search(pattern, text):
            raise RuntimeError(
                f"structured mesh {mesh} is not {cells_per_side}x{cells_per_side}x1: {path}"
            )
        spacing = UNSTRUCTURED_BASE / "meshes" / f"meshSpacing{mesh}.geo"
        if not spacing.is_file():
            raise RuntimeError(f"unstructured spacing file is missing: {spacing}")


def validate_specs(specs: list[CaseSpec], mode: str, target: str) -> None:
    validate_sources()
    case_names = [str(spec.relative_case) for spec in specs]
    if len(case_names) != len(set(case_names)):
        duplicates = sorted(name for name in set(case_names) if case_names.count(name) > 1)
        raise RuntimeError(f"duplicate generated case paths: {', '.join(duplicates)}")

    nmesh = len(mesh_indices(mode))
    expected_by_study = {
        "structured": len(METHODS) * nmesh,
        "parameter": len(EVEN_METHODS) * len(PRESSURE_SCALES) * nmesh,
        "unstructured": len(METHODS) * nmesh,
    }
    requested = (
        tuple(expected_by_study)
        if target == "all"
        else (() if target == "plots" else (target,))
    )
    for study in requested:
        actual = sum(spec.study == study for spec in specs)
        if actual != expected_by_study[study]:
            raise RuntimeError(f"{study}: enumerated {actual}, expected {expected_by_study[study]}")

    meshes = set(mesh_indices(mode))
    expected_keys: dict[str, set[tuple[object, ...]]] = {
        "structured": {
            (method.tag, mesh, "10.0", "0.1")
            for method in METHODS
            for mesh in meshes
        },
        "parameter": {
            (method.tag, mesh, sp, "0.1")
            for method in EVEN_METHODS
            for sp in PRESSURE_SCALES
            for mesh in meshes
        },
        "unstructured": {
            (method.tag, mesh, "10.0", "1.0")
            for method in METHODS
            for mesh in meshes
        },
    }
    for study in requested:
        actual_keys = {
            (spec.method.tag, spec.mesh_index, spec.sp, spec.sm)
            for spec in specs
            if spec.study == study
        }
        missing = expected_keys[study] - actual_keys
        extra = actual_keys - expected_keys[study]
        if missing or extra:
            raise RuntimeError(
                f"{study}: invalid parameter coverage; missing={sorted(missing)}, extra={sorted(extra)}"
            )

    for method in EVEN_METHODS:
        if method.paper_m != method.laplacian_power + 1:
            raise RuntimeError(f"invalid paper/internal m mapping for {method.tag}")


def manifest_row(spec: CaseSpec) -> dict[str, str | int]:
    return {
        "study": spec.study,
        "case": str(spec.relative_case),
        "mesh_index": spec.mesh_index,
        "cells_per_side": spec.cells_per_side,
        "method": spec.method.tag,
        "method_label": spec.method.label,
        "paper_m": "" if spec.method.paper_m is None else spec.method.paper_m,
        "laplacian_power": ""
        if spec.method.laplacian_power is None
        else spec.method.laplacian_power,
        "sp": spec.sp,
        "sm": spec.sm,
    }


def print_manifest(specs: list[CaseSpec], mode: str, target: str) -> None:
    print(f"Validated {len(specs)} unique {mode} cases for target '{target}'.")
    if not specs:
        return
    fields = tuple(manifest_row(specs[0]).keys())
    writer = csv.DictWriter(sys.stdout, fieldnames=fields, delimiter="\t", lineterminator="\n")
    writer.writeheader()
    writer.writerows(manifest_row(spec) for spec in specs)


def write_tsv(path: Path, fields: tuple[str, ...], rows: list[dict[str, object]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    with temporary.open("w", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields, delimiter="\t", lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)
    temporary.replace(path)


def configure_case(case: Path, spec: CaseSpec) -> None:
    template = case / "constant" / f"solidProperties.{spec.method.tag}"
    if not template.is_file():
        raise RuntimeError(f"missing method template: {template}")
    text = template.read_text()
    text = replace_block_entry(text, "momentum", "scaleFactor", spec.sm)
    text = replace_block_entry(text, "pressure", "scaleFactor", spec.sp)
    text = replace_block_entry(text, "pressure", "scaleFactorJacobian", spec.sp)
    active = case / "constant" / "solidProperties"
    active.write_text(text)
    validate_dictionary(text, spec.method, spec.sp, spec.sm, active)


def executable(name: str) -> str:
    path = shutil.which(name)
    if path is None:
        raise RuntimeError(
            f"required executable '{name}' is unavailable; source the OpenFOAM/solids4foam environment first"
        )
    return path


def validate_executable_loads(path: str, name: str) -> None:
    try:
        completed = subprocess.run(
            [path, "-help"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.PIPE,
            text=True,
            timeout=20,
        )
    except subprocess.TimeoutExpired as error:
        raise RuntimeError(f"'{name} -help' timed out during prerequisite validation") from error
    if completed.returncode != 0:
        diagnostic = completed.stderr.strip().splitlines()
        detail = diagnostic[0] if diagnostic else f"exit code {completed.returncode}"
        raise RuntimeError(
            f"required executable '{path}' exists but cannot be loaded ({detail}); refresh the OpenFOAM environment before running"
        )


def gmsh_executable() -> str:
    path = shutil.which("gmsh")
    if path:
        return path
    mac_path = Path("/Applications/Gmsh.app/Contents/MacOS/gmsh")
    if mac_path.is_file():
        return str(mac_path)
    raise RuntimeError("Gmsh is required for the unstructured Cook's membrane study")


def required_commands(study: str) -> dict[str, str]:
    solver = executable("solids4Foam")
    validate_executable_loads(solver, "solids4Foam")
    commands = {"solids4Foam": solver}
    if study == "unstructured":
        commands.update(
            {
                "gmsh": gmsh_executable(),
                "gmshToFoam": executable("gmshToFoam"),
                "changeDictionary": executable("changeDictionary"),
                "checkMesh": executable("checkMesh"),
            }
        )
    else:
        commands["blockMesh"] = executable("blockMesh")
    return commands


def preflight(target: str) -> None:
    studies = (
        ("structured", "parameter", "unstructured")
        if target == "all"
        else (() if target == "plots" else (target,))
    )
    for study in studies:
        required_commands(study)
    if target in {"all", "plots"}:
        if not PLOTTER.is_file():
            raise RuntimeError(f"paper plot renderer is missing: {PLOTTER}")
        reportlab_python()
        benchmark = ROOT / "plotScripts" / "Bijelona.csv"
        if not benchmark.is_file() or benchmark.stat().st_size == 0:
            raise RuntimeError(f"benchmark data are missing or empty: {benchmark}")


def reportlab_python() -> str:
    candidates = (
        os.environ.get("COOKS_PLOT_PYTHON"),
        os.environ.get("CONDA_PYTHON_EXE"),
        sys.executable,
        shutil.which("python3"),
        shutil.which("python"),
    )
    checked: list[str] = []
    for candidate in candidates:
        if not candidate or candidate in checked or not Path(candidate).is_file():
            continue
        checked.append(candidate)
        completed = subprocess.run(
            [candidate, "-c", "import reportlab"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        if completed.returncode == 0:
            return candidate
    raise RuntimeError(
        "the Python 'reportlab' package is required for plotting; install it or set COOKS_PLOT_PYTHON to a Python interpreter that provides it"
    )


def run_logged(command: list[str], case: Path, log_name: str) -> str:
    log_path = case / log_name
    print(f"    {' '.join(command)} -> {log_path.name}", flush=True)
    with log_path.open("w") as log:
        completed = subprocess.run(command, cwd=case, stdout=log, stderr=subprocess.STDOUT)
    text = log_path.read_text(errors="replace")
    if completed.returncode != 0:
        raise RuntimeError(
            f"command failed with exit code {completed.returncode}: {' '.join(command)}; see {log_path}"
        )
    return text


def require_end(log_text: str, log_path: Path) -> None:
    if not re.search(r"(?m)^End\s*$", log_text):
        raise RuntimeError(f"solver log has no successful terminal 'End': {log_path}")


def prepare_structured_mesh(case: Path, spec: CaseSpec, commands: dict[str, str]) -> int:
    source = case / "system" / f"blockMeshDict.{spec.mesh_index}"
    destination = case / "system" / "blockMeshDict"
    if not source.is_file():
        raise RuntimeError(f"missing structured mesh dictionary: {source}")
    shutil.copy2(source, destination)
    log = run_logged([commands["blockMesh"]], case, "log.blockMesh")
    matches = re.findall(r"nCells:\s*(\d+)", log)
    if not matches:
        raise RuntimeError(f"could not extract cell count from {case / 'log.blockMesh'}")
    actual = int(matches[-1])
    expected = spec.cells_per_side * spec.cells_per_side
    if actual != expected:
        raise RuntimeError(f"structured mesh has {actual} cells, expected {expected}: {case}")
    return actual


def prepare_unstructured_mesh(case: Path, spec: CaseSpec, commands: dict[str, str]) -> int:
    spacing = case / "meshes" / f"meshSpacing{spec.mesh_index}.geo"
    if not spacing.is_file():
        raise RuntimeError(f"missing unstructured spacing definition: {spacing}")
    shutil.copy2(spacing, case / "meshes" / "meshSpacing.geo")
    zero = case / "0"
    temporary_zero = case / "0.tmp"
    zero.rename(temporary_zero)
    try:
        run_logged(
            [commands["gmsh"], "-3", "-format", "msh2", "meshes/cooksMembrane.geo"],
            case,
            "log.gmsh",
        )
        run_logged(
            [commands["gmshToFoam"], "meshes/cooksMembrane.msh"],
            case,
            "log.gmshToFoam",
        )
        run_logged([commands["changeDictionary"]], case, "log.changeDictionary")
        check_log = run_logged([commands["checkMesh"]], case, "log.checkMesh")
    finally:
        if temporary_zero.exists() and not zero.exists():
            temporary_zero.rename(zero)

    match = re.search(r"(?m)^\s*cells:\s*(\d+)\s*$", check_log)
    if not match:
        raise RuntimeError(f"could not extract cell count from {case / 'log.checkMesh'}")
    actual = int(match.group(1))
    expected = UNSTRUCTURED_CELLS[spec.mesh_index]
    if actual != expected:
        raise RuntimeError(
            f"unstructured mesh {spec.mesh_index} has {actual} cells, expected {expected}: {case}"
        )
    return actual


def extract_displacement(case: Path) -> tuple[float, float]:
    path = case / "postProcessing" / "0" / "solidPointDisplacement_pointDisp.dat"
    if not path.is_file():
        raise RuntimeError(f"expected displacement output is missing: {path}")
    data_lines = [
        line.split()
        for line in path.read_text().splitlines()
        if line.strip() and not line.lstrip().startswith("#")
    ]
    if not data_lines or len(data_lines[-1]) < 3:
        raise RuntimeError(f"expected displacement row is missing or malformed: {path}")
    try:
        raw = float(data_lines[-1][2])
    except ValueError as error:
        raise RuntimeError(f"vertical displacement is not numeric in {path}") from error
    if not math.isfinite(raw):
        raise RuntimeError(f"vertical displacement is not finite in {path}")
    return raw, raw * 0.001


def extract_execution_time(log_text: str, log_path: Path) -> float:
    matches = re.findall(r"ExecutionTime\s*=\s*([0-9.eE+-]+)", log_text)
    if not matches:
        raise RuntimeError(f"ExecutionTime could not be extracted from {log_path}")
    value = float(matches[-1])
    # OpenFOAM rounds ExecutionTime in its log; very small test cases can
    # therefore legitimately report 0 s.  Retain that trusted value.  The
    # logarithmic timing plot follows the original script and omits zero-time
    # points.
    if not math.isfinite(value) or value < 0:
        raise RuntimeError(f"invalid ExecutionTime {value} in {log_path}")
    return value


def run_case(spec: CaseSpec, run_root: Path, commands: dict[str, str]) -> dict[str, object]:
    case = run_root / spec.relative_case
    base = STRUCTURED_BASE if spec.study != "unstructured" else UNSTRUCTURED_BASE
    print(
        f"[{spec.study}] {spec.method.tag}, mesh={spec.mesh_index} "
        f"({spec.cells_per_side}/side), sp={spec.sp}, sm={spec.sm}",
        flush=True,
    )
    shutil.copytree(base, case)
    configure_case(case, spec)
    if spec.study == "unstructured":
        actual_cells = prepare_unstructured_mesh(case, spec, commands)
    else:
        actual_cells = prepare_structured_mesh(case, spec, commands)

    solver_log_path = case / "log.solids4Foam"
    solver_log = run_logged([commands["solids4Foam"]], case, solver_log_path.name)
    require_end(solver_log, solver_log_path)
    dy_raw, dy_scaled = extract_displacement(case)
    execution_time: float | str = ""
    if spec.study == "structured":
        execution_time = extract_execution_time(solver_log, solver_log_path)

    return {
        "study": spec.study,
        "case": str(spec.relative_case),
        "mesh_index": spec.mesh_index,
        "cells_per_side": spec.cells_per_side,
        "actual_cells": actual_cells,
        "method": spec.method.tag,
        "method_label": spec.method.label,
        "paper_m": "" if spec.method.paper_m is None else spec.method.paper_m,
        "laplacian_power": ""
        if spec.method.laplacian_power is None
        else spec.method.laplacian_power,
        "sp": spec.sp,
        "sm": spec.sm,
        "dy_raw": f"{dy_raw:.16g}",
        "dy_scaled": f"{dy_scaled:.16g}",
        "execution_time_s": "" if execution_time == "" else f"{execution_time:.16g}",
        "solver_log": str(solver_log_path.relative_to(ROOT)),
        "status": "OK",
    }


def run_study(study: str, specs: list[CaseSpec], mode: str) -> Path:
    study_specs = [spec for spec in specs if spec.study == study]
    if not study_specs:
        raise RuntimeError(f"no cases enumerated for study '{study}'")
    run_root = ROOT / "runs" / mode
    result_path = ROOT / "results" / mode / f"{study}.tsv"
    case_paths = [run_root / spec.relative_case for spec in study_specs]
    existing = [path for path in case_paths if path.exists()]
    if existing or result_path.exists():
        first = existing[0] if existing else result_path
        raise RuntimeError(f"generated output already exists: {first}; run ./Allclean before rerunning")

    commands = required_commands(study)
    manifest_fields = tuple(manifest_row(study_specs[0]).keys())
    write_tsv(
        run_root / f"{study}_manifest.tsv",
        manifest_fields,
        [manifest_row(spec) for spec in study_specs],
    )
    rows: list[dict[str, object]] = []
    for spec in study_specs:
        rows.append(run_case(spec, run_root, commands))
    if len(rows) != len(study_specs):
        raise RuntimeError(f"{study}: completed {len(rows)} of {len(study_specs)} cases")
    write_tsv(result_path, RESULT_FIELDS, rows)
    print(f"Wrote {len(rows)} validated rows to {result_path}")
    return result_path


def reject_existing_outputs(specs: list[CaseSpec], mode: str, target: str) -> None:
    if target == "plots":
        return
    run_root = ROOT / "runs" / mode
    studies = {spec.study for spec in specs}
    candidates = [run_root / spec.relative_case for spec in specs]
    candidates.extend(run_root / f"{study}_manifest.tsv" for study in studies)
    candidates.extend(ROOT / "results" / mode / f"{study}.tsv" for study in studies)
    existing = [path for path in candidates if path.exists()]
    if existing:
        raise RuntimeError(
            f"generated output already exists: {existing[0]}; run ./Allclean before rerunning"
        )


def expected_figures(mode: str) -> tuple[Path, ...]:
    figure_dir = ROOT / "figures" / mode
    return tuple(
        figure_dir / name
        for name in (
            "figure5_structured_displacement.pdf",
            "figure5_execution_time_vs_error.pdf",
            "figure6_pressure_scale_m1.pdf",
            "figure6_pressure_scale_m2.pdf",
            "figure6_pressure_scale_m3.pdf",
            "figure7b_unstructured_displacement.pdf",
        )
    )


def run_plots(mode: str) -> None:
    required_results = tuple(
        ROOT / "results" / mode / f"{study}.tsv"
        for study in ("structured", "parameter", "unstructured")
    )
    for path in required_results:
        if not path.is_file() or path.stat().st_size == 0:
            raise RuntimeError(f"required processed result file is missing or empty: {path}")
    completed = subprocess.run([reportlab_python(), str(PLOTTER), "--mode", mode], cwd=ROOT)
    if completed.returncode != 0:
        raise RuntimeError(f"paper plotting failed with exit code {completed.returncode}")
    missing = [
        path for path in expected_figures(mode) if not path.is_file() or path.stat().st_size == 0
    ]
    if missing:
        raise RuntimeError(
            "expected figure was not generated: " + ", ".join(str(path) for path in missing)
        )
    print("Generated paper figures:")
    for path in expected_figures(mode):
        print(f"  {path}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--mode", choices=("full", "test"), required=True)
    parser.add_argument(
        "--target",
        choices=("all", "structured", "parameter", "unstructured", "plots"),
        default="all",
    )
    parser.add_argument("--list", action="store_true", help="validate and list cases without writing")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    specs = enumerate_specs(args.mode, args.target)
    validate_specs(specs, args.mode, args.target)
    if args.list:
        print_manifest(specs, args.mode, args.target)
        return 0
    preflight(args.target)
    reject_existing_outputs(specs, args.mode, args.target)
    if args.target == "plots":
        run_plots(args.mode)
        return 0
    studies = (
        ("structured", "parameter", "unstructured")
        if args.target == "all"
        else (args.target,)
    )
    for study in studies:
        run_study(study, specs, args.mode)
    if args.target == "all":
        run_plots(args.mode)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, RuntimeError, ValueError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        raise SystemExit(1)
