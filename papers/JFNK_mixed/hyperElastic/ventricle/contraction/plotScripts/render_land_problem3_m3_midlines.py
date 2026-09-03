#!/usr/bin/env python3
"""Render individual and combined Land problem 3 m=3 midline figures.

The source results are read directly from the meshN directories beneath the
data directory, which defaults to the runs directory created by Allrun. Every
mesh level that has a midLineDeformed.txt is plotted. The original Problem 3
axis windows are retained exactly. The legacy black dashed reference curve is
intentionally omitted.
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
INDIVIDUAL_PAGE = (7.0 * PT, 4.8 * PT)
COMBINED_PAGE = (6.0 * PT, 7.2 * PT)

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


# Colour and marker for each mesh level, in order. The first three entries
# reproduce the original Mesh 1-3 styling.
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


def discover_series(data_dir: Path) -> tuple[Series, ...]:
    """Build the series list from the mesh directories present in data_dir."""

    meshes = sorted(
        (path.parent for path in data_dir.glob("mesh*/midLineDeformed.txt")),
        key=mesh_level,
    )
    if not meshes:
        raise SystemExit(
            f"No mesh*/midLineDeformed.txt found under {data_dir}; run ./Allrun first."
        )
    return tuple(
        Series(mesh.name, f"Mesh {mesh_level(mesh)}", *PALETTE[index % len(PALETTE)])
        for index, mesh in enumerate(meshes)
    )


@dataclass(frozen=True)
class PlotSpec:
    key: str
    filename: str
    x_bounds: tuple[float, float]
    z_bounds: tuple[float, float]
    x_ticks: tuple[float, ...]
    z_ticks: tuple[float, ...]
    marker_stride: int
    equal_scale: bool


SPECS = (
    PlotSpec(
        "full",
        "ventricleInflation-midline-deformed.pdf",
        (-10.0, 0.0),
        (-20.0, 5.0),
        (-10.0, -5.0, 0.0),
        (-20.0, -15.0, -10.0, -5.0, 0.0, 5.0),
        8,
        True,
    ),
    PlotSpec(
        "apex",
        "ventricleInflation-midline-apex-deformed.pdf",
        (-2.0, 0.0),
        (-15.0, -13.0),
        (-2.0, -1.5, -1.0, -0.5, 0.0),
        (-15.0, -14.5, -14.0, -13.5, -13.0),
        2,
        False,
    ),
    PlotSpec(
        "inflection",
        "ventricleInflation-midline-inflection-deformed.pdf",
        (-8.75, -8.25),
        (-2.0, 2.0),
        (-8.5,),
        (-2.0, -1.0, 0.0, 1.0, 2.0),
        2,
        False,
    ),
)
SPEC_BY_KEY = {spec.key: spec for spec in SPECS}


@dataclass(frozen=True)
class Axes:
    spec: PlotSpec
    left: float
    bottom: float
    width: float
    height: float
    panel_label: str | None = None

    @property
    def right(self) -> float:
        return self.left + self.width

    @property
    def top(self) -> float:
        return self.bottom + self.height


def read_midline(path: Path) -> list[tuple[float, float]]:
    """Read unmodified x and z result coordinates and convert m to mm."""

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


def map_x(axes: Axes, value: float) -> float:
    lo, hi = axes.spec.x_bounds
    return axes.left + (value - lo) / (hi - lo) * axes.width


def map_z(axes: Axes, value: float) -> float:
    lo, hi = axes.spec.z_bounds
    return axes.bottom + (value - lo) / (hi - lo) * axes.height


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
        pdf.rect(x - size, y - size, 2.0 * size, 2.0 * size, stroke=1, fill=1)
    else:
        path = pdf.beginPath()
        path.moveTo(x, y + size + 0.35)
        path.lineTo(x - size - 0.25, y - size)
        path.lineTo(x + size + 0.25, y - size)
        path.close()
        pdf.drawPath(path, stroke=1, fill=1)


def draw_axes(pdf: canvas.Canvas, axes: Axes) -> None:
    pdf.setStrokeColor(GRID)
    pdf.setLineWidth(0.4)
    pdf.setDash(1.2, 2.0)
    for value in axes.spec.x_ticks:
        x = map_x(axes, value)
        pdf.line(x, axes.bottom, x, axes.top)
    for value in axes.spec.z_ticks:
        y = map_z(axes, value)
        pdf.line(axes.left, y, axes.right, y)
    pdf.setDash()

    pdf.setStrokeColor(INK)
    pdf.setLineWidth(0.85)
    pdf.rect(axes.left, axes.bottom, axes.width, axes.height, stroke=1, fill=0)

    pdf.setFillColor(INK)
    pdf.setFont(FONT, TICK_FONT_SIZE)
    for value in axes.spec.x_ticks:
        pdf.drawCentredString(map_x(axes, value), axes.bottom - 12.0, f"{value:g}")
    for value in axes.spec.z_ticks:
        pdf.drawRightString(axes.left - 5.0, map_z(axes, value) - 2.6, f"{value:g}")

    pdf.setFont(FONT, AXIS_FONT_SIZE)
    pdf.drawCentredString((axes.left + axes.right) / 2.0, axes.bottom - 29.0, "x [mm]")
    pdf.saveState()
    pdf.translate(axes.left - 34.0, (axes.bottom + axes.top) / 2.0)
    pdf.rotate(90)
    pdf.drawCentredString(0.0, 0.0, "z [mm]")
    pdf.restoreState()

    if axes.panel_label:
        label_y = axes.top + (2.0 if axes.panel_label == "(a)" else 8.0)
        pdf.setFont(FONT_BOLD, PANEL_FONT_SIZE)
        pdf.drawString(axes.left - 28.0, label_y, axes.panel_label)


def draw_series(
    pdf: canvas.Canvas,
    axes: Axes,
    points: list[tuple[float, float]],
    series: Series,
) -> None:
    mapped = [(map_x(axes, x), map_z(axes, z)) for x, z in points]

    pdf.saveState()
    clip = pdf.beginPath()
    clip.rect(axes.left, axes.bottom, axes.width, axes.height)
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
        if axes.spec.x_bounds[0] <= x <= axes.spec.x_bounds[1]
        and axes.spec.z_bounds[0] <= z <= axes.spec.z_bounds[1]
    ]
    selected = visible_indices[:: axes.spec.marker_stride]
    if visible_indices and selected[-1] != visible_indices[-1]:
        selected.append(visible_indices[-1])
    for index in selected:
        draw_marker(pdf, *mapped[index], series)
    pdf.restoreState()


def draw_legend(
    pdf: canvas.Canvas,
    x: float,
    y: float,
    series_list: tuple[Series, ...],
) -> None:
    font_size = 9.2
    row_height = 19.0
    sample_width = 25.0
    text_width = max(
        pdfmetrics.stringWidth(item.label, FONT, font_size) for item in series_list
    )
    box_width = 12.0 + sample_width + 8.0 + text_width + 12.0
    box_height = 13.0 + row_height * len(series_list)

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


def set_metadata(pdf: canvas.Canvas, subject: str) -> None:
    pdf.setTitle("Land Problem 3: m=3 mid-wall deformation")
    pdf.setSubject(subject)
    pdf.setAuthor("solids4foam")


def render_individual(
    output: Path,
    spec: PlotSpec,
    datasets: dict[str, list[tuple[float, float]]],
    series_list: tuple[Series, ...],
) -> None:
    pdf = canvas.Canvas(str(output), pagesize=INDIVIDUAL_PAGE, pageCompression=1)
    set_metadata(pdf, f"{spec.key.capitalize()} mid-wall result for {mesh_range(series_list)}")

    if spec.equal_scale:
        height = 274.0
        width = height * (spec.x_bounds[1] - spec.x_bounds[0]) / (
            spec.z_bounds[1] - spec.z_bounds[0]
        )
        axes = Axes(spec, 119.0, 51.0, width, height)
        legend_x = 286.0
    else:
        axes = Axes(spec, 61.0, 51.0, 250.0, 250.0)
        legend_x = 337.0

    draw_axes(pdf, axes)
    for series in series_list:
        draw_series(pdf, axes, datasets[series.mesh], series)
    draw_legend(pdf, legend_x, 145.0, series_list)
    pdf.showPage()
    pdf.save()


def draw_magnification_guides(pdf: canvas.Canvas, full_axes: Axes) -> None:
    pdf.setStrokeColor(PANEL_GUIDE)
    pdf.setLineWidth(0.65)
    pdf.setDash(2.0, 1.8)
    for key in ("apex", "inflection"):
        spec = SPEC_BY_KEY[key]
        x0, x1 = (map_x(full_axes, value) for value in spec.x_bounds)
        z0, z1 = (map_z(full_axes, value) for value in spec.z_bounds)
        pdf.rect(x0, z0, x1 - x0, z1 - z0, stroke=1, fill=0)
    pdf.setDash()


def mesh_range(series_list: tuple[Series, ...]) -> str:
    """Describe the plotted mesh levels, for the PDF metadata."""

    labels = [series.label for series in series_list]
    if len(labels) == 1:
        return labels[0]
    return f"{labels[0]}-{labels[-1].split()[-1]}"


def render_combined(
    output: Path,
    datasets: dict[str, list[tuple[float, float]]],
    series_list: tuple[Series, ...],
) -> None:
    pdf = canvas.Canvas(str(output), pagesize=COMBINED_PAGE, pageCompression=1)
    set_metadata(pdf, "Combined full-line, apical, and inflection-region result plots")

    axes_list = (
        Axes(SPEC_BY_KEY["full"], 142.0, 245.0, 104.0, 260.0, "(a)"),
        Axes(SPEC_BY_KEY["apex"], 50.0, 42.0, 154.0, 154.0, "(b)"),
        Axes(SPEC_BY_KEY["inflection"], 265.0, 42.0, 154.0, 154.0, "(c)"),
    )
    for axes in axes_list:
        draw_axes(pdf, axes)
        for series in series_list:
            draw_series(pdf, axes, datasets[series.mesh], series)

    draw_magnification_guides(pdf, axes_list[0])
    draw_legend(pdf, 276.0, 356.0, series_list)
    pdf.showPage()
    pdf.save()


def render(data_dir: Path, output_dir: Path) -> list[Path]:
    series_list = discover_series(data_dir)
    print(f"Plotting {', '.join(series.label for series in series_list)} from {data_dir}")
    datasets = {
        series.mesh: read_midline(data_dir / series.mesh / "midLineDeformed.txt")
        for series in series_list
    }
    output_dir.mkdir(parents=True, exist_ok=True)

    outputs: list[Path] = []
    for spec in SPECS:
        output = output_dir / spec.filename
        render_individual(output, spec, datasets, series_list)
        outputs.append(output)
        print(f"Wrote {output}")

    combined = output_dir / "land_problem3_m3_combined.pdf"
    render_combined(combined, datasets, series_list)
    outputs.append(combined)
    print(f"Wrote {combined}")
    return outputs


def main() -> None:
    # The script lives in <case>/plotScripts, so the case directory is its
    # parent: results are under <case>/runs and figures go to <case>.
    case_dir = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(
        description="Render Land problem 3 m=3 mid-wall figures for every mesh level run."
    )
    parser.add_argument(
        "--data-dir",
        type=Path,
        default=case_dir / "runs",
        help="Directory holding the meshN case directories (default: <case>/runs).",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        help="Directory to write the figures to (default: the case directory).",
    )
    args = parser.parse_args()
    render(args.data_dir, args.output_dir or case_dir)


if __name__ == "__main__":
    main()
