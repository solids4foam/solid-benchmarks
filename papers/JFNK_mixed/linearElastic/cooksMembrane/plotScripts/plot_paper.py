#!/usr/bin/env python3
"""Render only the six retained linear Cook's membrane paper panels.

The dimensions, fonts, colours, markers, labels, grids and legend layout are
adapted from the ReportLab and gnuplot scripts archived with DataHPC.
"""

from __future__ import annotations

import argparse
import csv
import math
from pathlib import Path

try:
    from reportlab.lib import colors
    from reportlab.lib.pagesizes import landscape
    from reportlab.pdfgen import canvas
except ImportError as error:
    raise SystemExit("ERROR: the Python 'reportlab' package is required for paper plotting") from error


ROOT = Path(__file__).resolve().parents[1]
BENCHMARK_FILE = Path(__file__).resolve().parent / "Bijelona.csv"
METHODS = (
    ("jst", "JST", colors.HexColor("#4C78A8"), "square"),
    ("laplacian", "Laplacian", colors.HexColor("#5B8E55"), "circle"),
    ("rhiechow", "Rhie-Chow", colors.HexColor("#7B6AA8"), "triangle"),
    ("evenlap_m0", "Even Laplacian, m=1", colors.HexColor("#D7AAAA"), "cross"),
    ("evenlap_m1", "Even Laplacian, m=2", colors.HexColor("#B85C4B"), "cross"),
    ("evenlap_m2", "Even Laplacian, m=3", colors.HexColor("#7A2738"), "cross"),
)
SCALE_COLOURS = {
    "0.01": colors.HexColor("#7B6AA8"),
    "0.1": colors.HexColor("#4C78A8"),
    "1": colors.HexColor("#4F7F78"),
    "10": colors.HexColor("#5B8E55"),
    "100": colors.HexColor("#B8793D"),
    "1000": colors.HexColor("#7A2738"),
}


def read_results(path: Path) -> list[dict[str, object]]:
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


class Plot:
    def __init__(
        self,
        path: Path,
        xlabel: str,
        ylabel: str,
        *,
        logx: bool = False,
        logy: bool = False,
        parameter_panel: bool = False,
    ):
        self.path = path
        self.xlabel = xlabel
        self.ylabel = ylabel
        self.logx = logx
        self.logy = logy
        self.parameter_panel = parameter_panel
        self.width, self.height = landscape((7.0 * 72, 4.8 * 72))
        self.left, self.right, self.bottom, self.top = 58, 20, 54, 22
        self.c = canvas.Canvas(str(path), pagesize=(self.width, self.height))

    def tx(self, x: float, bounds: tuple[float, float]) -> float:
        lo, hi = bounds
        if self.logx:
            x, lo, hi = math.log10(x), math.log10(lo), math.log10(hi)
        return self.left + (x - lo) / (hi - lo) * (self.width - self.left - self.right)

    def ty(self, y: float, bounds: tuple[float, float]) -> float:
        lo, hi = bounds
        if self.logy:
            y, lo, hi = math.log10(y), math.log10(lo), math.log10(hi)
        return self.bottom + (y - lo) / (hi - lo) * (self.height - self.bottom - self.top)

    def ticks(self, bounds: tuple[float, float], logscale: bool, axis: str) -> list[float]:
        lo, hi = bounds
        if self.parameter_panel and axis == "x":
            return [value for value in (3, 6, 12, 24, 48, 96, 192, 384) if lo <= value <= hi]
        if logscale:
            return [
                10**power
                for power in range(math.floor(math.log10(lo)), math.ceil(math.log10(hi)) + 1)
                if lo <= 10**power <= hi
            ]
        raw_step = (hi - lo) / 5
        magnitude = 10 ** math.floor(math.log10(raw_step))
        fraction = raw_step / magnitude
        if fraction <= 1.5:
            multiplier = 1
        elif fraction <= 3:
            multiplier = 2
        elif fraction <= 7:
            multiplier = 5
        else:
            multiplier = 10
        step = multiplier * magnitude
        first = math.ceil(lo / step) * step
        return [first + index * step for index in range(20) if lo <= first + index * step <= hi]

    def draw_axes(self, xb: tuple[float, float], yb: tuple[float, float]) -> None:
        c = self.c
        xticks = self.ticks(xb, self.logx, "x")
        yticks = self.ticks(yb, self.logy, "y")
        c.setStrokeColor(colors.HexColor("#d9d9d9"))
        c.setLineWidth(0.45)
        c.setDash(1, 2)
        for x in xticks:
            px = self.tx(x, xb)
            c.line(px, self.bottom, px, self.height - self.top)
        for y in yticks:
            py = self.ty(y, yb)
            c.line(self.left, py, self.width - self.right, py)
        c.setDash()
        c.setStrokeColor(colors.black)
        c.setLineWidth(1.1)
        c.rect(
            self.left,
            self.bottom,
            self.width - self.left - self.right,
            self.height - self.bottom - self.top,
            stroke=1,
            fill=0,
        )
        c.setFont("Helvetica", 9)
        for x in xticks:
            label = f"{x:g}" if not self.logx or self.xlabel == "Execution time [s]" else f"1e{int(round(math.log10(x)))}"
            c.drawCentredString(self.tx(x, xb), self.bottom - 14, label)
        for y in yticks:
            label = f"{y:.2f}" if not self.logy else f"1e{int(round(math.log10(y)))}"
            c.drawRightString(self.left - 6, self.ty(y, yb) - 3, label)
        c.setFont("Helvetica", 11)
        c.drawCentredString((self.left + self.width - self.right) / 2, 18, self.xlabel)
        c.saveState()
        c.translate(15, (self.bottom + self.height - self.top) / 2)
        c.rotate(90)
        c.drawCentredString(0, 0, self.ylabel)
        c.restoreState()

    def marker(self, x: float, y: float, colour, shape: str) -> None:
        c = self.c
        c.setStrokeColor(colour)
        size = 3.2
        if shape == "circle":
            c.circle(x, y, size, stroke=1, fill=0)
        elif shape == "square":
            c.rect(x - size, y - size, 2 * size, 2 * size, stroke=1, fill=0)
        elif shape == "triangle":
            c.line(x, y + size, x - size, y - size)
            c.line(x - size, y - size, x + size, y - size)
            c.line(x + size, y - size, x, y + size)
        else:
            c.line(x - size, y - size, x + size, y + size)
            c.line(x - size, y + size, x + size, y - size)

    def draw_series(
        self,
        points: list[tuple[float, float]],
        xb: tuple[float, float],
        yb: tuple[float, float],
        colour,
        shape: str,
        *,
        dashed: bool = False,
    ) -> None:
        if not points:
            return
        c = self.c
        c.setStrokeColor(colour)
        c.setLineWidth(1.6 if dashed else 1.45)
        if dashed:
            c.setDash(6, 4)
        mapped = [(self.tx(x, xb), self.ty(y, yb)) for x, y in points]
        for (x0, y0), (x1, y1) in zip(mapped, mapped[1:]):
            c.line(x0, y0, x1, y1)
        c.setDash()
        for x, y in mapped:
            self.marker(x, y, colour, shape)

    def legend(self, entries: list[tuple[str, object, str]], font_size: int = 12) -> None:
        c = self.c
        c.setFont("Helvetica", font_size)
        row_step = 17
        legend_width = max(34 + c.stringWidth(label, "Helvetica", font_size) for label, _, _ in entries)
        x = self.width - self.right - legend_width - 10
        y = self.height - self.top - 22
        c.setFillColor(colors.white)
        c.rect(
            x - 5,
            y - row_step * (len(entries) - 1) - 5,
            legend_width + 10,
            row_step * len(entries) + 6,
            stroke=0,
            fill=1,
        )
        for label, colour, shape in entries:
            c.setStrokeColor(colour)
            c.setLineWidth(1.45)
            if label == "Benchmark":
                c.setDash(6, 4)
            c.line(x, y + 3, x + 16, y + 3)
            c.setDash()
            self.marker(x + 8, y + 3, colour, shape)
            c.setFillColor(colors.black)
            c.drawString(x + 22, y, label)
            y -= row_step

    def annotation(self, text: str) -> None:
        self.c.setFillColor(colors.black)
        self.c.setFont("Helvetica-Bold", 12)
        self.c.drawCentredString(
            (self.left + self.width - self.right) / 2,
            self.height - self.top - 20,
            text,
        )

    def finish(self) -> None:
        self.c.showPage()
        self.c.save()


def method_points(rows: list[dict[str, object]], method: str) -> list[tuple[float, float]]:
    return sorted(
        (
            (float(row["cells_per_side"]), float(row["dy_scaled"]))
            for row in rows
            if row["method"] == method
        ),
        key=lambda point: point[0],
    )


def render_method_displacement(path: Path, rows: list[dict[str, object]]) -> None:
    benchmark = read_benchmark()
    series = [
        (label, colour, shape, method_points(rows, method))
        for method, label, colour, shape in METHODS
    ]
    if any(not points for _, _, _, points in series):
        raise ValueError(f"a required method series is empty for {path}")
    xs = [x for *_, points in series for x, _ in points] + [x for x, _ in benchmark]
    ys = [y for *_, points in series for _, y in points] + [y for _, y in benchmark]
    plot = Plot(path, "Cells per side", "Vertical displacement")
    xb, yb = finite_bounds(xs), finite_bounds(ys)
    plot.draw_axes(xb, yb)
    plot.draw_series(benchmark, xb, yb, colors.HexColor("#111111"), "triangle", dashed=True)
    for _, colour, shape, points in series:
        plot.draw_series(points, xb, yb, colour, shape)
    plot.legend(
        [("Benchmark", colors.HexColor("#111111"), "triangle")]
        + [(label, colour, shape) for label, colour, shape, _ in series]
    )
    plot.finish()


def render_time_error(path: Path, rows: list[dict[str, object]], mode: str) -> None:
    reference_rows = [row for row in rows if row["method"] == "evenlap_m2"]
    if not reference_rows:
        raise ValueError("structured m=3 reference series is missing")
    reference_row = max(reference_rows, key=lambda row: int(row["mesh_index"]))
    reference_mesh = int(reference_row["mesh_index"])
    reference = float(reference_row["dy_scaled"])
    series: list[tuple[object, str, list[tuple[float, float]]]] = []
    for method, _, colour, shape in METHODS:
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
        series.append((colour, shape, points))
    xs = [x for _, _, points in series for x, _ in points]
    ys = [y for _, _, points in series for _, y in points]
    plot = Plot(path, "Execution time [s]", "|d_y - d_y,ref|", logx=True, logy=True)
    xb, yb = finite_bounds(xs, True), finite_bounds(ys, True)
    plot.draw_axes(xb, yb)
    for colour, shape, points in series:
        plot.draw_series(points, xb, yb, colour, shape)
    plot.finish()


def render_parameter_panel(path: Path, rows: list[dict[str, object]], paper_m: int) -> None:
    benchmark = read_benchmark()
    series: list[tuple[str, object, list[tuple[float, float]]]] = []
    for scale, colour in SCALE_COLOURS.items():
        points = sorted(
            (
                (float(row["cells_per_side"]), float(row["dy_scaled"]))
                for row in rows
                if row["paper_m"] == paper_m and str(row["sp"]) == scale
            ),
            key=lambda point: point[0],
        )
        if not points:
            raise ValueError(f"parameter series m={paper_m}, sp={scale} is empty")
        series.append((scale, colour, points))
    xs = [x for _, _, points in series for x, _ in points] + [x for x, _ in benchmark]
    ys = [y for _, _, points in series for _, y in points] + [y for _, y in benchmark]
    plot = Plot(path, "Cells per side", "Vertical displacement", parameter_panel=True)
    xb = finite_bounds(xs, padding=0.12)
    yb = finite_bounds(ys, padding=0.12)
    plot.draw_axes(xb, yb)
    plot.draw_series(benchmark, xb, yb, colors.HexColor("#111111"), "cross", dashed=True)
    for _, colour, points in series:
        plot.draw_series(points, xb, yb, colour, "cross")
    plot.annotation(f"m={paper_m}")
    plot.legend(
        [("Benchmark", colors.HexColor("#111111"), "cross")]
        + [(scale, colour, "cross") for scale, colour, _ in series]
    )
    plot.finish()


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--mode", choices=("full", "test"), required=True)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    results_dir = ROOT / "results" / args.mode
    output_dir = ROOT / "figures" / args.mode
    output_dir.mkdir(parents=True, exist_ok=True)
    structured = read_results(results_dir / "structured.tsv")
    parameter = read_results(results_dir / "parameter.tsv")
    unstructured = read_results(results_dir / "unstructured.tsv")

    render_method_displacement(output_dir / "figure5_structured_displacement.pdf", structured)
    render_time_error(output_dir / "figure5_execution_time_vs_error.pdf", structured, args.mode)
    for paper_m in (1, 2, 3):
        render_parameter_panel(
            output_dir / f"figure6_pressure_scale_m{paper_m}.pdf",
            parameter,
            paper_m,
        )
    render_method_displacement(
        output_dir / "figure7b_unstructured_displacement.pdf",
        unstructured,
    )
    print(f"Wrote 6 paper PDFs to {output_dir}")


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError) as error:
        raise SystemExit(f"ERROR: {error}") from error
