#!/usr/bin/env python3
"""Render the combined Land problem 2 m=3 mid-wall deformation figure.

The plotted inputs are discovered from ``runs/mesh*/midLineDeformed.txt``.
This allows the script to plot either the default single-mesh run or any
selection of the six mesh levels produced by ``Allrun``.

Only x and z are read from the result files; coordinates are converted from m
to mm for plotting. No numerical values are modified or interpolated.
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass
from pathlib import Path

from reportlab import __file__ as reportlab_init
from reportlab.lib import colors
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfgen import canvas


PT = 72.0
PAGE_WIDTH = 6.0 * PT
PAGE_HEIGHT = 7.2 * PT
OUTPUT_NAME = "land_problem2_m3_combined.pdf"

INK = colors.HexColor("#171717")
GRID = colors.HexColor("#D7D7D7")
PANEL_GUIDE = colors.HexColor("#8A8A8A")
FONT = "PublicationSans"
FONT_BOLD = "PublicationSans-Bold"

REPORTLAB_FONT_DIR = Path(reportlab_init).resolve().parent / "fonts"
pdfmetrics.registerFont(TTFont(FONT, str(REPORTLAB_FONT_DIR / "Vera.ttf")))
pdfmetrics.registerFont(TTFont(FONT_BOLD, str(REPORTLAB_FONT_DIR / "VeraBd.ttf")))

TICK_FONT_SIZE = 7.8
AXIS_FONT_SIZE = 9.6
PANEL_FONT_SIZE = 10.5
SERIES_LINE_WIDTH = 1.45
MARKER_LINE_WIDTH = 1.0
MARKER_SIZE = 2.35


@dataclass(frozen=True)
class Series:
    mesh: str
    label: str
    colour: object
    marker: str


# Okabe-Ito-derived colours retain good separation in print and for
# colour-vision deficiencies. Styles are assigned in mesh-level order.
PALETTE = (
    (colors.HexColor("#0072B2"), "circle"),
    (colors.HexColor("#D55E00"), "square"),
    (colors.HexColor("#009E73"), "triangle"),
    (colors.HexColor("#CC79A7"), "circle"),
    (colors.HexColor("#E69F00"), "square"),
    (colors.HexColor("#56B4E9"), "triangle"),
)


def mesh_level(path: Path) -> int:
    """Return the numeric level of a meshN directory, for ordering."""

    digits = "".join(character for character in path.name if character.isdigit())
    return int(digits) if digits else 0


def discover_series(runs_dir: Path) -> tuple[Series, ...]:
    """Build plot series from completed mesh cases beneath runs_dir."""

    meshes = sorted(
        (path.parent for path in runs_dir.glob("mesh*/midLineDeformed.txt")),
        key=mesh_level,
    )
    if not meshes:
        raise SystemExit(
            f"No mesh*/midLineDeformed.txt found under {runs_dir}; run ./Allrun first."
        )
    return tuple(
        Series(mesh.name, f"Mesh {mesh_level(mesh)}", *PALETTE[index % len(PALETTE)])
        for index, mesh in enumerate(meshes)
    )


@dataclass(frozen=True)
class Panel:
    label: str
    x_bounds: tuple[float, float]
    y_bounds: tuple[float, float]
    x_ticks: tuple[float, ...]
    y_ticks: tuple[float, ...]
    left: float
    bottom: float
    width: float
    height: float
    marker_stride: int


# Panel (a) preserves a 1:1 x-z coordinate scale so the global deformation is
# geometrically faithful. Panels (b) and (c) retain the square magnification
# format used by the existing local plots.
PANELS = (
    Panel(
        "(a)",
        (-13.5, 0.0),
        (-28.0, 5.0),
        (-10.0, -5.0, 0.0),
        (-25.0, -20.0, -15.0, -10.0, -5.0, 0.0, 5.0),
        142.0,
        245.0,
        106.4,
        260.0,
        8,
    ),
    Panel(
        "(b)",
        (-5.0, 0.0),
        (-28.0, -25.0),
        (-5.0, -4.0, -3.0, -2.0, -1.0, 0.0),
        (-28.0, -27.5, -27.0, -26.5, -26.0, -25.5, -25.0),
        50.0,
        42.0,
        154.0,
        154.0,
        2,
    ),
    Panel(
        "(c)",
        (-13.4, -12.4),
        (-9.0, -2.0),
        (-13.4, -13.2, -13.0, -12.8, -12.6, -12.4),
        (-9.0, -8.0, -7.0, -6.0, -5.0, -4.0, -3.0, -2.0),
        265.0,
        42.0,
        154.0,
        154.0,
        2,
    ),
)


def read_midline(path: Path) -> list[tuple[float, float]]:
    """Read x and z from an existing OpenFOAM midline result, in mm."""

    points: list[tuple[float, float]] = []
    with path.open(encoding="utf-8") as handle:
        for line_number, line in enumerate(handle, start=1):
            if not line.strip() or line.lstrip().startswith("#"):
                continue
            fields = line.split()
            if len(fields) < 3:
                raise ValueError(f"Expected x y z in {path}:{line_number}")
            points.append((1.0e3 * float(fields[0]), 1.0e3 * float(fields[2])))
    if not points:
        raise ValueError(f"No midline points found in {path}")
    return points


def tx(panel: Panel, x: float) -> float:
    lo, hi = panel.x_bounds
    return panel.left + (x - lo) / (hi - lo) * panel.width


def ty(panel: Panel, z: float) -> float:
    lo, hi = panel.y_bounds
    return panel.bottom + (z - lo) / (hi - lo) * panel.height


def draw_marker(
    pdf: canvas.Canvas,
    x: float,
    y: float,
    series: Series,
    size: float = MARKER_SIZE,
) -> None:
    pdf.setStrokeColor(series.colour)
    pdf.setFillColor(colors.white)
    pdf.setLineWidth(MARKER_LINE_WIDTH)
    if series.marker == "circle":
        pdf.circle(x, y, size, stroke=1, fill=1)
    elif series.marker == "square":
        pdf.rect(x - size, y - size, 2 * size, 2 * size, stroke=1, fill=1)
    else:
        path = pdf.beginPath()
        path.moveTo(x, y + size + 0.35)
        path.lineTo(x - size - 0.25, y - size)
        path.lineTo(x + size + 0.25, y - size)
        path.close()
        pdf.drawPath(path, stroke=1, fill=1)


def draw_axes(pdf: canvas.Canvas, panel: Panel) -> None:
    top = panel.bottom + panel.height
    right = panel.left + panel.width

    pdf.setStrokeColor(GRID)
    pdf.setLineWidth(0.4)
    pdf.setDash(1.2, 2.0)
    for value in panel.x_ticks:
        x = tx(panel, value)
        pdf.line(x, panel.bottom, x, top)
    for value in panel.y_ticks:
        y = ty(panel, value)
        pdf.line(panel.left, y, right, y)
    pdf.setDash()

    pdf.setStrokeColor(INK)
    pdf.setLineWidth(0.85)
    pdf.rect(panel.left, panel.bottom, panel.width, panel.height, stroke=1, fill=0)

    pdf.setFillColor(INK)
    pdf.setFont(FONT, TICK_FONT_SIZE)
    for value in panel.x_ticks:
        pdf.drawCentredString(tx(panel, value), panel.bottom - 12.0, f"{value:g}")
    for value in panel.y_ticks:
        pdf.drawRightString(panel.left - 5.0, ty(panel, value) - 2.6, f"{value:g}")

    pdf.setFont(FONT, AXIS_FONT_SIZE)
    pdf.drawCentredString((panel.left + right) / 2.0, panel.bottom - 29.0, "x [mm]")
    pdf.saveState()
    pdf.translate(panel.left - 34.0, (panel.bottom + top) / 2.0)
    pdf.rotate(90)
    pdf.drawCentredString(0.0, 0.0, "z [mm]")
    pdf.restoreState()

    label_y = top + (2.0 if panel.label == "(a)" else 8.0)
    pdf.setFont(FONT_BOLD, PANEL_FONT_SIZE)
    pdf.drawString(panel.left - 28.0, label_y, panel.label)


def draw_series(
    pdf: canvas.Canvas,
    panel: Panel,
    points: list[tuple[float, float]],
    series: Series,
) -> None:
    mapped = [(tx(panel, x), ty(panel, z)) for x, z in points]

    # Clip the complete polyline at the axes boundary. This preserves segments
    # crossing a magnification boundary without modifying/interpolating data.
    pdf.saveState()
    clip = pdf.beginPath()
    clip.rect(panel.left, panel.bottom, panel.width, panel.height)
    pdf.clipPath(clip, stroke=0, fill=0)

    pdf.setStrokeColor(series.colour)
    pdf.setLineWidth(SERIES_LINE_WIDTH)
    path = pdf.beginPath()
    path.moveTo(*mapped[0])
    for point in mapped[1:]:
        path.lineTo(*point)
    pdf.drawPath(path, stroke=1, fill=0)

    visible_indices = [
        index
        for index, (x, z) in enumerate(points)
        if panel.x_bounds[0] <= x <= panel.x_bounds[1]
        and panel.y_bounds[0] <= z <= panel.y_bounds[1]
    ]
    selected = visible_indices[:: panel.marker_stride]
    if visible_indices and selected[-1] != visible_indices[-1]:
        selected.append(visible_indices[-1])
    for index in selected:
        draw_marker(pdf, *mapped[index], series)
    pdf.restoreState()


def draw_legend(pdf: canvas.Canvas, series_list: tuple[Series, ...]) -> None:
    """Draw the single shared legend beside the primary panel."""

    font_size = 9.2
    row_height = 19.0
    sample_width = 25.0
    text_width = max(
        pdfmetrics.stringWidth(item.label, FONT, font_size) for item in series_list
    )
    box_width = 12.0 + sample_width + 8.0 + text_width + 12.0
    box_height = 13.0 + row_height * len(series_list)
    x = 276.0
    y = 356.0

    pdf.setFillColor(colors.white)
    pdf.setStrokeColor(colors.HexColor("#B8B8B8"))
    pdf.setLineWidth(0.55)
    pdf.roundRect(x, y, box_width, box_height, 2.5, stroke=1, fill=1)

    row_y = y + box_height - 16.0
    pdf.setFont(FONT, font_size)
    for series in series_list:
        sample_y = row_y + 3.0
        pdf.setStrokeColor(series.colour)
        pdf.setLineWidth(SERIES_LINE_WIDTH)
        pdf.line(x + 9.0, sample_y, x + 9.0 + sample_width, sample_y)
        draw_marker(pdf, x + 9.0 + sample_width / 2.0, sample_y, series, size=2.2)
        pdf.setFillColor(INK)
        pdf.drawString(x + 9.0 + sample_width + 7.0, row_y, series.label)
        row_y -= row_height


def draw_magnification_guides(pdf: canvas.Canvas) -> None:
    """Subtly identify the two regions magnified in panels (b) and (c)."""

    full = PANELS[0]
    pdf.setStrokeColor(PANEL_GUIDE)
    pdf.setLineWidth(0.65)
    pdf.setDash(2.0, 1.8)
    for x_bounds, z_bounds in (
        (PANELS[1].x_bounds, PANELS[1].y_bounds),
        (PANELS[2].x_bounds, PANELS[2].y_bounds),
    ):
        x0, x1 = (tx(full, value) for value in x_bounds)
        y0, y1 = (ty(full, value) for value in z_bounds)
        pdf.rect(x0, y0, x1 - x0, y1 - y0, stroke=1, fill=0)
    pdf.setDash()


def render(runs_dir: Path, output: Path) -> Path:
    series_list = discover_series(runs_dir)
    print(f"Plotting {', '.join(series.label for series in series_list)} from {runs_dir}")
    datasets = {
        series.mesh: read_midline(runs_dir / series.mesh / "midLineDeformed.txt")
        for series in series_list
    }

    output.parent.mkdir(parents=True, exist_ok=True)
    pdf = canvas.Canvas(
        str(output),
        pagesize=(PAGE_WIDTH, PAGE_HEIGHT),
        pageCompression=1,
    )
    pdf.setTitle("Land Problem 2: m=3 mid-wall deformation")
    pdf.setSubject("Combined full-line, apical, and inflection-region result plots")
    pdf.setAuthor("solids4foam")

    for panel in PANELS:
        draw_axes(pdf, panel)
        for series in series_list:
            draw_series(pdf, panel, datasets[series.mesh], series)

    draw_magnification_guides(pdf)
    draw_legend(pdf, series_list)
    pdf.showPage()
    pdf.save()
    print(f"Wrote {output}")
    return output


def main() -> None:
    # The script lives in <case>/plotScripts. Inputs and the default output are
    # therefore resolved from <case>, not from a machine-specific location or
    # from the caller's working directory.
    case_dir = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(
        description="Render the Land problem 2 mid-wall figure for completed meshes."
    )
    parser.add_argument(
        "--runs-dir",
        type=Path,
        default=case_dir / "runs",
        help="Directory holding meshN cases (default: <inflation>/runs).",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=case_dir / OUTPUT_NAME,
        help=f"Output PDF (default: <inflation>/{OUTPUT_NAME}).",
    )
    args = parser.parse_args()
    render(args.runs_dir, args.output)


if __name__ == "__main__":
    main()
