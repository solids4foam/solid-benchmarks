#!/usr/bin/env python3
"""Render the retained Cook's membrane panels for each requested campaign.

Data handling (campaign manifests, displacement extraction, error reference,
series selection and shared axis bounds) is unchanged from the earlier
ReportLab version of this script.
The drawing layer now uses the shared manuscript style in
``papers/JFNK_mixed/plotStyle/paper_figure_style.py`` (matplotlib, figures
drawn at their printed size, embedded Helvetica, zero-based operator index
``m = laplacianPower``).

Outputs (13 PDFs, manuscript file names):
  figure5_structured_displacement_sm{1p0,0p1}.pdf
  figure5_execution_time_vs_error_sm{1p0,0p1}.pdf
  figure6_pressure_scale_{m1,m2,m3,rhiechow}_sm{1p0,0p1}.pdf
  figure7b_unstructured_displacement.pdf
The ``m1/m2/m3`` in the file names are the OLD one-based index of the
manuscript and are kept unchanged on purpose; the figure content uses the
zero-based index (``m1`` file -> coupled m = 0, etc.).
"""

from __future__ import annotations

import argparse
import csv
import math
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
# shared style: $JFNK_PAPER_STYLE_DIR, else the nearest plotStyle/ above this script (paperData/plotStyle)
import os
_candidates = [Path(os.environ["JFNK_PAPER_STYLE_DIR"])] if "JFNK_PAPER_STYLE_DIR" in os.environ else []
_candidates += [parent / "plotStyle" for parent in Path(__file__).resolve().parents]
STYLE_DIR = next((d for d in _candidates if (d / "paper_figure_style.py").is_file()), _candidates[-1])
sys.path.insert(0, str(STYLE_DIR))
try:
    import paper_figure_style as pfs
except ImportError as error:
    raise SystemExit(f"ERROR: shared style module not found in {STYLE_DIR}: {error}") from error

from matplotlib.ticker import (  # noqa: E402
    FixedLocator, FuncFormatter, LogLocator, MaxNLocator, MultipleLocator, NullFormatter,
)

BENCHMARK_FILE = Path(__file__).resolve().parent / "Bijelona.csv"
NORMALISATION_TAG = "normalised_r2"
MOMENTUM_SCALES = ("1.0", "0.1")
# (campaign method name, style identity).  Order is the legend order.
METHODS = (
    ("jst", "jst"),
    ("laplacian", "laplacian"),
    ("rhiechow", "rhiechow"),
    ("evenlap_m0", "coupled_m0"),
    ("evenlap_m1", "coupled_m1"),
    ("evenlap_m2", "coupled_m2"),
)
SCALE_COLOURS = pfs.pressure_scale_colours()          # keys "0.01" ... "1000"
# Shared y-bounds (mm) for the structured/unstructured displacement panels.
# The structured bounds cover both momentum campaigns (s_m = 1: 3.8-7.7 mm,
# s_m = 0.1: 7.4-10.0 mm); the legend sits in the empty lower-right region.
STRUCTURED_Y_BOUNDS = (3.0, 11.0)
UNSTRUCTURED_Y_BOUNDS = (3.0, 10.0)
# Axis labels.  The displacement unit is the existing one (dy_scaled =
# D_y x 1e-3); the physical unit of the linear Cook's case is being checked by
# the authors and is deliberately NOT reinterpreted here.
DISPLACEMENT_LABEL = "Vertical displacement [mm]"
DISPLACEMENT_ERROR_LABEL = "Displacement error [mm]"
CELLS_LABEL = "Cells per side"
TIME_LABEL = "Execution time [s]"
BENCHMARK_LABEL = "Bijelonja (2006)"
# File-name tag (old index) -> campaign method -> legend text (new index).
PARAMETER_PLOTS = (
    ("m1", "evenlap_m0", "coupled_m0"),
    ("m2", "evenlap_m1", "coupled_m1"),
    ("m3", "evenlap_m2", "coupled_m2"),
    ("rhiechow", "rhiechow", "rhiechow"),
)


def read_results(path: Path, expected_sm: str | None = None) -> list[dict[str, object]]:
    if not path.is_file() or path.stat().st_size == 0:
        raise ValueError(f"processed result file is missing or empty: {path}")
    rows: list[dict[str, object]] = []
    with path.open(newline="") as handle:
        reader = csv.DictReader(handle, delimiter="\t")
        required = {
            "mesh_index",
            "cells_per_side",
            "method",
            "paper_m",
            "sp",
            "sm",
            "normalise",
            "referenceNyquistDirections",
            "dy_scaled",
            "execution_time_s",
            "status",
        }
        missing = required.difference(reader.fieldnames or ())
        if missing:
            raise ValueError(f"missing columns in {path}: {', '.join(sorted(missing))}")
        for source in reader:
            if source["status"] != "OK":
                raise ValueError(f"non-OK result in {path}: {source}")
            if source["normalise"] != "true" or source["referenceNyquistDirections"] != "2":
                raise ValueError(f"non-normalised or wrong-rStar result in {path}: {source}")
            if expected_sm is not None and source["sm"] != expected_sm:
                raise ValueError(
                    f"mixed momentum campaign in {path}: expected sm={expected_sm}, got {source['sm']}"
                )
            try:
                row = dict(source)
                row["mesh_index"] = int(source["mesh_index"])
                row["cells_per_side"] = float(source["cells_per_side"])
                row["paper_m"] = int(source["paper_m"]) if source["paper_m"] else None
                row["dy_scaled"] = float(source["dy_scaled"])
                row["execution_time_s"] = (
                    float(source["execution_time_s"]) if source["execution_time_s"] else math.nan
                )
            except ValueError as error:
                raise ValueError(f"malformed numeric result in {path}: {source}") from error
            if not math.isfinite(row["dy_scaled"]):
                raise ValueError(f"non-finite displacement in {path}: {source}")
            rows.append(row)
    if not rows:
        raise ValueError(f"no data rows in {path}")
    return rows


def read_hpc_results(data_dir: Path, study: str, sm: str) -> list[dict[str, object]]:
    """Read one completed campaign directly from the read-only HPC archive."""
    campaign_dir = data_dir / NORMALISATION_TAG / f"sm{sm.replace('.', 'p')}"
    manifest_path = campaign_dir / f"{study}_manifest.tsv"
    progress_path = campaign_dir / f"{study}_progress.tsv"
    if not manifest_path.is_file() or manifest_path.stat().st_size == 0:
        raise ValueError(f"HPC manifest is missing or empty: {manifest_path}")
    if not progress_path.is_file() or progress_path.stat().st_size == 0:
        raise ValueError(f"HPC progress file is missing or empty: {progress_path}")

    with progress_path.open(newline="") as handle:
        progress = list(csv.DictReader(handle, delimiter="\t"))
    incomplete = [row for row in progress if row.get("status") != "OK"]
    if incomplete:
        raise ValueError(f"HPC campaign contains non-OK cases in {progress_path}")
    progress_cases = {row.get("case", "") for row in progress}

    rows: list[dict[str, object]] = []
    with manifest_path.open(newline="") as handle:
        reader = csv.DictReader(handle, delimiter="\t")
        required = {
            "study",
            "case",
            "mesh_index",
            "cells_per_side",
            "method",
            "paper_m",
            "sp",
            "sm",
            "normalise",
            "referenceNyquistDirections",
        }
        missing = required.difference(reader.fieldnames or ())
        if missing:
            raise ValueError(
                f"missing columns in {manifest_path}: {', '.join(sorted(missing))}"
            )
        for source in reader:
            if source["case"] not in progress_cases:
                raise ValueError(f"HPC case has no progress record: {source['case']}")
            if source["study"] != study or source["sm"] != sm:
                raise ValueError(f"mixed HPC campaign in {manifest_path}: {source}")
            if source["normalise"] != "true" or source["referenceNyquistDirections"] != "2":
                raise ValueError(f"non-normalised or wrong-rStar HPC result: {source}")

            case = data_dir / source["case"]
            displacement_path = (
                case / "postProcessing" / "0" / "solidPointDisplacement_pointDisp.dat"
            )
            if not displacement_path.is_file():
                raise ValueError(f"HPC displacement output is missing: {displacement_path}")
            data_lines = [
                line.split()
                for line in displacement_path.read_text().splitlines()
                if line.strip() and not line.lstrip().startswith("#")
            ]
            if not data_lines or len(data_lines[-1]) < 3:
                raise ValueError(f"malformed HPC displacement output: {displacement_path}")

            log_path = case / "log.solids4Foam"
            if not log_path.is_file():
                raise ValueError(f"HPC solver log is missing: {log_path}")
            log_text = log_path.read_text(errors="replace")
            if not re.search(r"(?m)^End\s*$", log_text):
                raise ValueError(f"HPC solver log has no successful terminal 'End': {log_path}")
            timing = re.findall(r"ExecutionTime\s*=\s*([0-9.eE+-]+)", log_text)
            if study == "structured" and not timing:
                raise ValueError(f"ExecutionTime is missing from HPC solver log: {log_path}")

            try:
                dy_scaled = float(data_lines[-1][2]) * 0.001
                execution_time = float(timing[-1]) if study == "structured" else math.nan
                row = dict(source)
                row["mesh_index"] = int(source["mesh_index"])
                row["cells_per_side"] = float(source["cells_per_side"])
                row["paper_m"] = int(source["paper_m"]) if source["paper_m"] else None
                row["dy_scaled"] = dy_scaled
                row["execution_time_s"] = execution_time
                row["status"] = "OK"
            except ValueError as error:
                raise ValueError(f"malformed numeric HPC result for {source['case']}") from error
            if not math.isfinite(dy_scaled):
                raise ValueError(f"non-finite HPC displacement for {source['case']}")
            rows.append(row)

    if not rows:
        raise ValueError(f"no HPC data rows in {manifest_path}")
    if len(rows) != len(progress):
        raise ValueError(
            f"HPC manifest/progress row mismatch in {campaign_dir}: "
            f"{len(rows)} != {len(progress)}"
        )
    return rows


def read_benchmark() -> list[tuple[float, float]]:
    points: list[tuple[float, float]] = []
    with BENCHMARK_FILE.open(newline="") as handle:
        for row in csv.reader(handle):
            if len(row) >= 2:
                points.append((float(row[1]), float(row[0])))
    if not points:
        raise ValueError(f"benchmark file is empty: {BENCHMARK_FILE}")
    return points


def finite_bounds(values: list[float], logscale: bool = False, padding: float = 0.03) -> tuple[float, float]:
    clean = [value for value in values if math.isfinite(value) and (value > 0 if logscale else True)]
    if not clean:
        raise ValueError("cannot plot an empty or non-finite data series")
    lo, hi = min(clean), max(clean)
    if lo == hi:
        if logscale:
            return lo / 1.35, hi * 1.35
        pad = abs(lo) * 0.1 if lo else 1.0
        return lo - pad, hi + pad
    if logscale:
        return lo / 1.35, hi * 1.35
    pad = (hi - lo) * padding
    return lo - pad, hi + pad


def method_points(rows: list[dict[str, object]], method: str) -> list[tuple[float, float]]:
    return sorted(
        (
            (float(row["cells_per_side"]), float(row["dy_scaled"]))
            for row in rows
            if row["method"] == method
        ),
        key=lambda point: point[0],
    )


def method_displacement_bounds(
    row_groups: list[list[dict[str, object]]],
) -> tuple[tuple[float, float], tuple[float, float]]:
    benchmark = read_benchmark()
    points = [
        point
        for rows in row_groups
        for method, _ in METHODS
        for point in method_points(rows, method)
    ]
    return (
        finite_bounds([x for x, _ in points] + [x for x, _ in benchmark]),
        finite_bounds([y for _, y in points] + [y for _, y in benchmark]),
    )


def time_error_series(
    rows: list[dict[str, object]], mode: str
) -> list[tuple[str, list[tuple[float, float]]]]:
    """(style identity, [(execution time, |dy - reference|), ...]) per method.

    The reference is the coupled m = 2 (evenlap_m2) result on the finest mesh
    of the same campaign; in ``full`` mode meshes 2 .. finest-1 are plotted.
    """
    reference_rows = [row for row in rows if row["method"] == "evenlap_m2"]
    if not reference_rows:
        raise ValueError("structured coupled m = 2 (evenlap_m2) reference series is missing")
    reference_row = max(reference_rows, key=lambda row: int(row["mesh_index"]))
    reference_mesh = int(reference_row["mesh_index"])
    reference = float(reference_row["dy_scaled"])
    series: list[tuple[str, list[tuple[float, float]]]] = []
    for method, style_key in METHODS:
        points: list[tuple[float, float]] = []
        for row in rows:
            mesh = int(row["mesh_index"])
            if row["method"] != method:
                continue
            if mode == "full" and not (2 <= mesh < reference_mesh):
                continue
            if mode == "test" and mesh > reference_mesh:
                continue
            execution_time = float(row["execution_time_s"])
            error = abs(float(row["dy_scaled"]) - reference)
            if execution_time > 0 and error > 0 and math.isfinite(execution_time) and math.isfinite(error):
                points.append((execution_time, error))
        points.sort()
        series.append((style_key, points))
    return series


def time_error_bounds(
    row_groups: list[list[dict[str, object]]], mode: str
) -> tuple[tuple[float, float], tuple[float, float]]:
    series = [item for rows in row_groups for item in time_error_series(rows, mode)]
    xs = [x for _, points in series for x, _ in points]
    ys = [y for _, points in series for _, y in points]
    return finite_bounds(xs, True), finite_bounds(ys, True)


def parameter_series(
    rows: list[dict[str, object]], method: str
) -> list[tuple[str, list[tuple[float, float]]]]:
    """(pressure scale, [(cells per side, dy), ...]) for one method, ordered by scale."""
    present_scales = {str(row["sp"]) for row in rows}
    scales = [scale for scale in SCALE_COLOURS if scale in present_scales]
    if present_scales != set(scales):
        raise ValueError(f"unknown pressure scales in parameter data: {sorted(present_scales)}")
    series: list[tuple[str, list[tuple[float, float]]]] = []
    for scale in scales:
        points = sorted(
            (
                (float(row["cells_per_side"]), float(row["dy_scaled"]))
                for row in rows
                if row["method"] == method and str(row["sp"]) == scale
            ),
            key=lambda point: point[0],
        )
        if not points:
            raise ValueError(f"parameter series method={method}, sp={scale} is empty")
        series.append((scale, points))
    return series


def parameter_bounds(
    row_groups: list[list[dict[str, object]]], method: str
) -> tuple[tuple[float, float], tuple[float, float]]:
    benchmark = read_benchmark()
    series = [item for rows in row_groups for item in parameter_series(rows, method)]
    xs = [x for _, points in series for x, _ in points] + [x for x, _ in benchmark]
    ys = [y for _, points in series for _, y in points] + [y for _, y in benchmark]
    # x uses the default padding so that every cells-per-side panel (Figs 7,
    # 8, 9b, 17, 18) has the same x-extent; only y keeps the wider margin.
    return finite_bounds(xs), finite_bounds(ys, padding=0.12)


# ---------------------------------------------------------------------------
# Drawing (shared manuscript style, printed size 0.49 \linewidth)
# ---------------------------------------------------------------------------
PANEL_WIDTH_FRACTION = 0.49          # Figs 7, 8, 17, 18: subfigure[t]{0.49\linewidth}
PANEL_ASPECT = 0.76
UNSTRUCTURED_WIDTH_FRACTION = 0.63   # Fig 9(b): subfigure[t]{0.63\linewidth}
UNSTRUCTURED_ASPECT = 0.62


def _cells_axis(ax, xb: tuple[float, float]) -> None:
    # Start at zero and leave 5 % beyond the finest mesh so the markers at
    # 96 cells per side are not clipped by the frame.
    ax.set_xlim(0.0, xb[1] * 1.05)
    ax.set_xlabel(CELLS_LABEL)
    ax.xaxis.set_major_locator(MultipleLocator(20))
    ax.xaxis.set_minor_locator(MultipleLocator(10))


def render_method_displacement(
    path: Path,
    rows: list[dict[str, object]],
    axis_bounds: tuple[tuple[float, float], tuple[float, float]] | None = None,
    *,
    width_fraction: float = PANEL_WIDTH_FRACTION,
    aspect: float = PANEL_ASPECT,
) -> None:
    benchmark = read_benchmark()
    series = [(style_key, method_points(rows, method)) for method, style_key in METHODS]
    if any(not points for _, points in series):
        raise ValueError(f"a required method series is empty for {path}")
    xs = [x for _, points in series for x, _ in points] + [x for x, _ in benchmark]
    ys = [y for _, points in series for _, y in points] + [y for _, y in benchmark]
    xb, yb = axis_bounds if axis_bounds is not None else (finite_bounds(xs), finite_bounds(ys))

    fig, ax = pfs.new_figure(width_fraction, aspect)
    pfs.style_axes(ax)
    bx, by = zip(*benchmark)
    ax.plot(bx, by, **pfs.reference_kwargs(0, label=BENCHMARK_LABEL))
    pfs.record_series(path.name, BENCHMARK_LABEL, bx, by)
    for style_key, points in series:
        px, py = zip(*points)
        ax.plot(px, py, **pfs.line_kwargs(style_key))
        pfs.record_series(path.name, style_key, px, py)
    _cells_axis(ax, xb)
    ax.set_ylim(yb)
    ax.yaxis.set_major_locator(MaxNLocator(nbins=7, steps=[1, 2, 5]))
    ax.set_ylabel(DISPLACEMENT_LABEL)
    leg = pfs.legend(ax, loc="lower right", ncols=2)
    pfs.assert_legend_clear(fig, ax, leg, path.name)
    pfs.record_axes(path.name, ax)
    pfs.save(fig, path, title=f"Linear Cook's membrane: {path.stem}")


def _decimal_log_ticks(lo: float, hi: float) -> list[float]:
    """1-2-5 tick positions inside [lo, hi] for a logarithmic axis."""
    ticks = []
    for exponent in range(math.floor(math.log10(lo)), math.ceil(math.log10(hi)) + 1):
        for mantissa in (1.0, 2.0, 5.0):
            value = mantissa * 10.0 ** exponent
            if lo <= value <= hi:
                ticks.append(value)
    return ticks


def render_time_error(
    path: Path,
    rows: list[dict[str, object]],
    mode: str,
    axis_bounds: tuple[tuple[float, float], tuple[float, float]] | None = None,
) -> None:
    series = time_error_series(rows, mode)
    xs = [x for _, points in series for x, _ in points]
    ys = [y for _, points in series for _, y in points]
    xb, yb = axis_bounds if axis_bounds is not None else (finite_bounds(xs, True), finite_bounds(ys, True))

    fig, ax = pfs.new_figure(PANEL_WIDTH_FRACTION, PANEL_ASPECT)
    ax.set_xscale("log")
    ax.set_yscale("log")
    pfs.style_axes(ax)
    for style_key, points in series:
        if not points:
            continue
        px, py = zip(*points)
        ax.plot(px, py, **pfs.line_kwargs(style_key))
        pfs.record_series(path.name, style_key, px, py)
    ax.set_xlim(xb)
    ax.set_ylim(yb)
    ax.set_xlabel(TIME_LABEL)
    ax.set_ylabel(DISPLACEMENT_ERROR_LABEL)
    # The execution times span about one decade (0.1-1 s), so decimal
    # labels at 1-2-5 positions are used on the x-axis (as on the log x-axes of
    # Figs 10b, 11 and 13); the y-axis keeps 10^k labels over its 3.5 decades.
    ax.xaxis.set_major_locator(FixedLocator(_decimal_log_ticks(*xb)))
    ax.xaxis.set_major_formatter(FuncFormatter(lambda v, _: f"{v:g}"))
    ax.xaxis.set_minor_locator(LogLocator(base=10, subs=range(2, 10), numticks=12))
    ax.xaxis.set_minor_formatter(NullFormatter())
    ax.yaxis.set_major_locator(LogLocator(base=10, numticks=6))
    ax.yaxis.set_minor_locator(LogLocator(base=10, subs=range(2, 10), numticks=12))
    ax.yaxis.set_minor_formatter(NullFormatter())
    # Colours and markers identify the same methods as in the companion
    # displacement panel; the manuscript caption states this, so no legend.
    pfs.record_axes(path.name, ax)
    pfs.save(fig, path, title=f"Linear Cook's membrane: {path.stem}")


def render_parameter_panel(
    path: Path,
    rows: list[dict[str, object]],
    method: str,
    style_key: str,
    axis_bounds: tuple[tuple[float, float], tuple[float, float]] | None = None,
) -> None:
    benchmark = read_benchmark()
    series = parameter_series(rows, method)
    xs = [x for _, points in series for x, _ in points] + [x for x, _ in benchmark]
    ys = [y for _, points in series for _, y in points] + [y for _, y in benchmark]
    xb, yb = axis_bounds if axis_bounds is not None else (
        finite_bounds(xs),
        finite_bounds(ys, padding=0.12),
    )
    method_marker = pfs.method_style(style_key).marker
    method_label = pfs.method_style(style_key).label

    fig, ax = pfs.new_figure(PANEL_WIDTH_FRACTION, PANEL_ASPECT)
    pfs.style_axes(ax)
    bx, by = zip(*benchmark)
    ax.plot(bx, by, **pfs.reference_kwargs(0, label=BENCHMARK_LABEL))
    pfs.record_series(path.name, BENCHMARK_LABEL, bx, by)
    for scale, points in series:
        px, py = zip(*points)
        ax.plot(
            px, py,
            color=SCALE_COLOURS[scale], marker=method_marker, linestyle="-",
            markerfacecolor="none", markeredgecolor=SCALE_COLOURS[scale],
            label=scale, zorder=3,
        )
        pfs.record_series(path.name, f"sp={scale}", px, py)
    _cells_axis(ax, xb)
    ax.set_ylim(yb)
    ax.yaxis.set_major_locator(MaxNLocator(nbins=7, steps=[1, 2, 5]))
    ax.set_ylabel(DISPLACEMENT_LABEL)
    # The legend title carries the method identity (new index) and the
    # meaning of the entries; the LaTeX sub-caption repeats the method name.
    leg = pfs.legend(ax, loc="upper right", ncols=2,
                     title=f"{method_label}: $s_p^\\star$")
    pfs.assert_legend_clear(fig, ax, leg, path.name)
    pfs.record_axes(path.name, ax)
    pfs.save(fig, path, title=f"Linear Cook's membrane: {path.stem}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--mode", choices=("full", "test"), required=True)
    parser.add_argument(
        "--results-dir",
        type=Path,
        help="read the processed tables <dir>/normalised_r2/sm*/{structured,parameter,unstructured}.tsv "
             "written by scripts/workflow.py (default: <case>/results/<mode>)",
    )
    parser.add_argument(
        "--data-dir",
        type=Path,
        help="read raw full-campaign results (manifests, point displacements, solver logs) from this "
             "campaign directory, e.g. <case>/runs/full or a copy of it",
    )
    parser.add_argument(
        "--summary-dir",
        type=Path,
        help="read the plotted rows from the simple tables {structured,parameter}_sm{1p0,0p1}.tsv and "
             "unstructured_sm1p0.tsv in this directory (paperData: data/derived_summary)",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        help="write the PDFs here instead of <case>/figures/<mode>",
    )
    parser.add_argument(
        "--dump-series",
        type=Path,
        help="write a JSON record of every plotted series (for verification)",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    output_dir = args.output_dir if args.output_dir is not None else ROOT / "figures" / args.mode
    output_dir.mkdir(parents=True, exist_ok=True)
    if args.summary_dir is not None:
        # paperData (10 Nov 2026): the same rows as read_hpc_results() extracts, stored as plain tables
        if args.mode != "full" or args.data_dir is not None or args.results_dir is not None:
            raise ValueError("--summary-dir is only valid with --mode full and without --data-dir or --results-dir")
        summary_dir = args.summary_dir.resolve()

        def table(study: str, sm: str) -> list[dict[str, object]]:
            return read_results(summary_dir / f"{study}_sm{sm.replace('.', 'p')}.tsv", sm)

        structured = {sm: table("structured", sm) for sm in MOMENTUM_SCALES}
        parameter = {sm: table("parameter", sm) for sm in MOMENTUM_SCALES}
        unstructured = table("unstructured", "1.0")
    elif args.data_dir is not None:
        if args.mode != "full" or args.results_dir is not None:
            raise ValueError("--data-dir is only valid for the full campaign and without --results-dir")
        data_dir = args.data_dir.resolve()
        structured = {
            sm: read_hpc_results(data_dir, "structured", sm) for sm in MOMENTUM_SCALES
        }
        parameter = {
            sm: read_hpc_results(data_dir, "parameter", sm) for sm in MOMENTUM_SCALES
        }
        unstructured = read_hpc_results(data_dir, "unstructured", "1.0")
    else:
        results_dir = (args.results_dir.resolve() if args.results_dir is not None
                       else ROOT / "results" / args.mode)
        structured = {
            sm: read_results(
                results_dir / NORMALISATION_TAG / f"sm{sm.replace('.', 'p')}" / "structured.tsv",
                sm,
            )
            for sm in MOMENTUM_SCALES
        }
        parameter = {
            sm: read_results(
                results_dir / NORMALISATION_TAG / f"sm{sm.replace('.', 'p')}" / "parameter.tsv",
                sm,
            )
            for sm in MOMENTUM_SCALES
        }
        unstructured = read_results(
            results_dir / NORMALISATION_TAG / "sm1p0" / "unstructured.tsv",
            "1.0",
        )

    structured_x_bounds, _ = method_displacement_bounds(list(structured.values()))
    structured_bounds = (structured_x_bounds, STRUCTURED_Y_BOUNDS)
    timing_bounds = time_error_bounds(list(structured.values()), args.mode)
    parameter_method_bounds = {
        method: parameter_bounds(list(parameter.values()), method)
        for _, method, _ in PARAMETER_PLOTS
    }
    parameter_axis_bounds = (
        (
            min(bounds[0][0] for bounds in parameter_method_bounds.values()),
            max(bounds[0][1] for bounds in parameter_method_bounds.values()),
        ),
        (
            min(bounds[1][0] for bounds in parameter_method_bounds.values()),
            max(bounds[1][1] for bounds in parameter_method_bounds.values()),
        ),
    )
    for sm in MOMENTUM_SCALES:
        suffix = f"sm{sm.replace('.', 'p')}"
        render_method_displacement(
            output_dir / f"figure5_structured_displacement_{suffix}.pdf",
            structured[sm],
            structured_bounds,
        )
        render_time_error(
            output_dir / f"figure5_execution_time_vs_error_{suffix}.pdf",
            structured[sm],
            args.mode,
            timing_bounds,
        )
        for name, method, style_key in PARAMETER_PLOTS:
            render_parameter_panel(
                output_dir / f"figure6_pressure_scale_{name}_{suffix}.pdf",
                parameter[sm],
                method,
                style_key,
                parameter_axis_bounds,
            )
    render_method_displacement(
        output_dir / "figure7b_unstructured_displacement.pdf",
        unstructured,
        (method_displacement_bounds([unstructured])[0], UNSTRUCTURED_Y_BOUNDS),
        width_fraction=UNSTRUCTURED_WIDTH_FRACTION,
        aspect=UNSTRUCTURED_ASPECT,
    )
    if args.dump_series is not None:
        pfs.write_records(args.dump_series)
    print(f"Wrote 13 paper PDFs to {output_dir}")


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError) as error:
        raise SystemExit(f"ERROR: {error}") from error
