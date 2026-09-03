#!/usr/bin/env python3
"""Render Land problem 1 tip-coordinate plots in the paper style."""

from __future__ import annotations

import argparse
import math
from dataclasses import dataclass
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.pagesizes import landscape
from reportlab.pdfgen import canvas


REFERENCE_MM = 4.2


@dataclass(frozen=True)
class SeriesSpec:
    path: Path
    label: str
    colour: object
    cell_size_in_column: bool


def read_summary(spec: SeriesSpec) -> list[tuple[float, float]]:
    points: list[tuple[float, float]] = []
    with spec.path.open() as handle:
        for line in handle:
            if line.startswith("#") or not line.strip():
                continue
            fields = line.split()
            mesh = int(fields[0])
            cell_size_mm = (
                float(fields[1])
                if spec.cell_size_in_column
                else 1.0 / (2 ** (mesh - 1))
            )
            raw_dz_m = float(fields[3])
            tip_z_mm = 1.0 + 1.0e3 * raw_dz_m
            points.append((cell_size_mm, tip_z_mm))
    return sorted(points)


def log_bounds(values: list[float]) -> tuple[float, float]:
    lo, hi = min(values), max(values)
    if lo == hi:
        return lo / math.sqrt(2.0), hi * math.sqrt(2.0)
    factor = (hi / lo) ** 0.035
    return lo / factor, hi * factor


def linear_bounds(values: list[float]) -> tuple[float, float]:
    lo, hi = min(values), max(values)
    if lo == hi:
        pad = max(abs(lo) * 0.08, 0.1)
        return lo - pad, hi + pad
    pad = (hi - lo) * 0.08
    return lo - pad, hi + pad


def nice_linear_ticks(bounds: tuple[float, float], target: int = 7) -> list[float]:
    lo, hi = bounds
    raw_step = (hi - lo) / target
    magnitude = 10 ** math.floor(math.log10(raw_step))
    normalized = raw_step / magnitude
    if normalized <= 1:
        step = magnitude
    elif normalized <= 2:
        step = 2 * magnitude
    elif normalized <= 5:
        step = 5 * magnitude
    else:
        step = 10 * magnitude
    first = math.ceil(lo / step) * step
    ticks: list[float] = []
    value = first
    while value <= hi + step * 1.0e-9:
        ticks.append(value)
        value += step
    return ticks


class Plot:
    def __init__(
        self,
        path: Path,
        specs: list[SeriesSpec],
        ylabel: str,
        reference_label: str,
    ):
        self.path = path
        self.specs = specs
        self.ylabel = ylabel
        self.reference_label = reference_label
        self.width, self.height = landscape((7.0 * 72, 4.8 * 72))
        self.left, self.right, self.bottom, self.top = 58, 20, 54, 22
        self.c = canvas.Canvas(str(path), pagesize=(self.width, self.height))

    def tx(self, x: float, bounds: tuple[float, float]) -> float:
        lo, hi = (math.log10(value) for value in bounds)
        return self.left + (math.log10(x) - lo) / (hi - lo) * (
            self.width - self.left - self.right
        )

    def ty(self, y: float, bounds: tuple[float, float]) -> float:
        lo, hi = bounds
        return self.bottom + (y - lo) / (hi - lo) * (
            self.height - self.bottom - self.top
        )

    def draw_axes(self, xb: tuple[float, float], yb: tuple[float, float]) -> None:
        c = self.c
        xticks = [
            value
            for value in [0.03125, 0.0625, 0.125, 0.25, 0.5, 1.0]
            if xb[0] <= value <= xb[1]
        ]
        yticks = nice_linear_ticks(yb)

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

        c.setFillColor(colors.black)
        c.setFont("Helvetica", 9)
        for x in xticks:
            c.drawCentredString(self.tx(x, xb), self.bottom - 14, f"{x:g}")
        for y in yticks:
            c.drawRightString(self.left - 6, self.ty(y, yb) - 3, f"{y:g}")

        c.setFont("Helvetica", 11)
        c.drawCentredString(
            (self.left + self.width - self.right) / 2,
            18,
            "Cell size [mm]",
        )
        c.saveState()
        c.translate(15, (self.bottom + self.height - self.top) / 2)
        c.rotate(90)
        c.drawCentredString(0, 0, self.ylabel)
        c.restoreState()

    def marker(self, x: float, y: float, colour) -> None:
        c = self.c
        size = 3.2
        c.setStrokeColor(colour)
        c.line(x - size, y - size, x + size, y + size)
        c.line(x - size, y + size, x + size, y - size)

    def draw_reference(self, xb: tuple[float, float], yb: tuple[float, float]) -> None:
        c = self.c
        c.setStrokeColor(colors.HexColor("#111111"))
        c.setLineWidth(1.6)
        c.setDash(6, 4)
        c.line(
            self.tx(xb[0], xb),
            self.ty(REFERENCE_MM, yb),
            self.tx(xb[1], xb),
            self.ty(REFERENCE_MM, yb),
        )
        c.setDash()

    def draw_series(
        self,
        points: list[tuple[float, float]],
        xb: tuple[float, float],
        yb: tuple[float, float],
        colour,
    ) -> None:
        c = self.c
        c.setStrokeColor(colour)
        c.setLineWidth(1.45)
        mapped = [(self.tx(x, xb), self.ty(y, yb)) for x, y in points]
        for (x0, y0), (x1, y1) in zip(mapped, mapped[1:]):
            c.line(x0, y0, x1, y1)
        for x, y in mapped:
            self.marker(x, y, colour)

    def legend(self) -> None:
        c = self.c
        entries = [
            (self.reference_label, colors.HexColor("#111111"), True),
            *[(spec.label, spec.colour, False) for spec in self.specs],
        ]
        font_size = 12
        row_step = 17
        c.setFont("Helvetica", font_size)
        legend_width = max(
            38 + c.stringWidth(label, "Helvetica", font_size)
            for label, _, _ in entries
        )
        x = self.left + 12
        y = self.bottom + row_step * (len(entries) - 1) + 15

        c.setFillColor(colors.white)
        c.rect(
            x - 5,
            y - row_step * (len(entries) - 1) - 5,
            legend_width + 10,
            row_step * len(entries) + 6,
            stroke=0,
            fill=1,
        )
        for label, colour, dashed in entries:
            c.setStrokeColor(colour)
            c.setLineWidth(1.6 if dashed else 1.45)
            if dashed:
                c.setDash(6, 4)
            c.line(x, y + 3, x + 18, y + 3)
            c.setDash()
            if not dashed:
                self.marker(x + 9, y + 3, colour)
            c.setFillColor(colors.black)
            c.drawString(x + 24, y, label)
            y -= row_step

    def finish(self) -> None:
        self.c.showPage()
        self.c.save()


def render(
    path: Path,
    specs: list[SeriesSpec],
    ylabel: str = "Vertical displacement, D_z [mm]",
    reference_label: str = "Reference",
) -> None:
    datasets = [(spec, read_summary(spec)) for spec in specs]
    all_x = [x for _, points in datasets for x, _ in points]
    all_y = [y for _, points in datasets for _, y in points]
    xb = log_bounds(all_x)
    yb = linear_bounds([*all_y, REFERENCE_MM])

    plot = Plot(path, specs, ylabel, reference_label)
    plot.draw_axes(xb, yb)
    plot.draw_reference(xb, yb)
    for spec, points in datasets:
        plot.draw_series(points, xb, yb, spec.colour)
    plot.legend()
    plot.finish()


def parse_args() -> argparse.Namespace:
    script_path = Path(__file__).resolve()
    default_data_dir = script_path.parents[1]
    parser = argparse.ArgumentParser()
    parser.add_argument("--data-dir", type=Path, default=default_data_dir)
    parser.add_argument("--output-dir", type=Path)
    parser.add_argument("--m1-summary", type=Path)
    parser.add_argument("--m2-summary", type=Path)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    case_dir = args.data_dir
    output_dir = args.output_dir or case_dir / "plots"
    output_dir.mkdir(parents=True, exist_ok=True)

    m1_path = args.m1_summary or case_dir / "comparison_data" / "evenlap_m1_beam.summary.txt"
    m2_path = args.m2_summary or case_dir / "comparison_data" / "evenlap_m2_beam.summary.txt"
    m3_path = case_dir / "runs" / "beam.summary.txt"

    if not m3_path.is_file():
        raise SystemExit(f"Result summary not found: {m3_path}")

    m1 = SeriesSpec(m1_path, "Even Laplacian, m=1", colors.HexColor("#D7AAAA"), False)
    m2 = SeriesSpec(m2_path, "Even Laplacian, m=2", colors.HexColor("#B85C4B"), False)
    m3 = SeriesSpec(m3_path, "Even Laplacian, m=3", colors.HexColor("#7A2738"), True)

    m3_output = output_dir / "land_problem1_m3_verticalDisplacement_vs_cellSize.pdf"
    combined_output = output_dir / "land_problem1_m1_m2_m3_verticalDisplacement_vs_cellSize.pdf"
    render(
        m3_output,
        [m3],
        ylabel="Deformed tip coordinate, z_tip [mm]",
        reference_label="Land et al. ≈ 4.2 mm",
    )
    print(f"Wrote {m3_output}")
    if m1_path.is_file() and m2_path.is_file():
        render(combined_output, [m1, m2, m3])
        print(f"Wrote {combined_output}")
    else:
        print("Comparison summaries were not found; wrote the m=3 plot only.")


if __name__ == "__main__":
    main()
