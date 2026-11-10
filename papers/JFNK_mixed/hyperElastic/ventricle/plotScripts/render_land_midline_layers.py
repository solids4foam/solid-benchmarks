#!/usr/bin/env python3
"""Data layers of the ventricular mid-wall figures (manuscript Figs 15 and 16).

The published figures ``land_problem2_m3_combined_overlay.pdf`` (inflation,
Land et al. 2015 problem 2) and ``land_problem3_m3_combined_overlay.pdf``
(active contraction, problem 3) are Keynote composites made by P. Cardiff:
faint JPEG crops of the published Land et al. result figures behind the
vector data layer rendered by ``render_land_problem2_m3_combined.py`` /
``render_land_problem3_m3_midlines.py`` (kept in ``../inflation/plotScripts``
and ``../contraction/plotScripts``).

This script re-renders ONLY the data layer in the shared manuscript style
(embedded Helvetica, printed font sizes, shared mesh-level identities) while
keeping the page size and every panel rectangle, axis window, tick set,
marker stride and clipping IDENTICAL to the original layer, so that the
layer can be put back under the same Keynote transforms with
``composite_land_overlay.py`` and stays aligned with the faint reference
layers.  No numerical value is changed: x and z are read from
``midLineDeformed.txt`` (m) and converted to mm as before.

Font sizes are the printed sizes divided by the composite's scale
(0.783 for Fig 15, 0.788 for Fig 16): 8 pt ticks/legend and 9 pt axis
labels on the page.
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass
from pathlib import Path

from reportlab.lib import colors
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfgen import canvas

PT = 72.0
PAGE_WIDTH = 6.0 * PT
PAGE_HEIGHT = 7.2 * PT

# --- shared style (paper_figure_style.py values expressed at layer scale) ---
LAYER_SCALE = 0.783           # layer -> printed (Keynote 0.877 x LaTeX 0.892)
FONT = "HelveticaTT"
FONT_BOLD = "HelveticaTT-Bold"
# macOS Helvetica by default; set JFNK_PAPER_FONT_FILE to another .ttc holding regular (index 0) and bold (index 1)
import os  # noqa: E402
FONT_FILE = os.environ.get("JFNK_PAPER_FONT_FILE", "/System/Library/Fonts/Helvetica.ttc")
if os.path.isfile(FONT_FILE):
    pdfmetrics.registerFont(TTFont(FONT, FONT_FILE, subfontIndex=0))
    pdfmetrics.registerFont(TTFont(FONT_BOLD, FONT_FILE, subfontIndex=1))
elif "JFNK_PAPER_FONT_FILE" in os.environ:
    raise SystemExit(f"ERROR: font file not found: {FONT_FILE} (JFNK_PAPER_FONT_FILE)")
else:
    # No Helvetica collection on this system (e.g. Linux): use the PDF base-14 Helvetica.
    # The numbers and the geometry are unchanged; the font is then not embedded.
    import sys  # noqa: E402
    print("WARNING: /System/Library/Fonts/Helvetica.ttc not found; using the non-embedded base-14 "
          "Helvetica (set JFNK_PAPER_FONT_FILE to a .ttc with regular and bold faces to embed)",
          file=sys.stderr)
    FONT, FONT_BOLD = "Helvetica", "Helvetica-Bold"

TICK_FONT_SIZE = round(8.0 / LAYER_SCALE, 1)      # 10.2 -> 8 pt printed
AXIS_FONT_SIZE = round(9.0 / LAYER_SCALE, 1)      # 11.5 -> 9 pt printed
PANEL_FONT_SIZE = round(9.0 / LAYER_SCALE, 1)
LEGEND_FONT_SIZE = TICK_FONT_SIZE
SERIES_LINE_WIDTH = 1.45                          # 1.1 pt printed
MARKER_LINE_WIDTH = 1.25                          # 1.0 pt printed
MARKER_SIZE = 2.9                                 # 4.5 pt markers printed
GRID_LINE_WIDTH = 0.6
FRAME_LINE_WIDTH = 1.0
INK = colors.HexColor("#111111")
GRID = colors.HexColor("#D6D6D6")
PANEL_GUIDE = colors.HexColor("#8A8A8A")


@dataclass(frozen=True)
class Series:
    mesh: str
    label: str
    colour: object
    marker: str


# Mesh-level identities (paper_figure_style.MESH_LEVEL_STYLES, Okabe-Ito)
SERIES = (
    Series("mesh1", "Mesh 1", colors.HexColor("#0072B2"), "circle"),
    Series("mesh2", "Mesh 2", colors.HexColor("#D55E00"), "square"),
    Series("mesh3", "Mesh 3", colors.HexColor("#009E73"), "triangle"),
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


# Geometry copied unchanged from the HPC scripts that produced the paper layers.
PROBLEMS = {
    2: dict(
        title="Land Problem 2: m = 2 mid-wall deformation",
        runs_subdir="runs",
        panels=(
            Panel("(a)", (-13.5, 0.0), (-28.0, 5.0), (-10.0, -5.0, 0.0),
                  (-25.0, -20.0, -15.0, -10.0, -5.0, 0.0, 5.0), 142.0, 245.0, 106.4, 260.0, 8),
            Panel("(b)", (-5.0, 0.0), (-28.0, -25.0), (-5.0, -4.0, -3.0, -2.0, -1.0, 0.0),
                  (-28.0, -27.5, -27.0, -26.5, -26.0, -25.5, -25.0), 50.0, 42.0, 154.0, 154.0, 2),
            Panel("(c)", (-13.4, -12.4), (-9.0, -2.0), (-13.4, -13.2, -13.0, -12.8, -12.6, -12.4),
                  (-9.0, -8.0, -7.0, -6.0, -5.0, -4.0, -3.0, -2.0), 265.0, 42.0, 154.0, 154.0, 2),
        ),
    ),
    3: dict(
        title="Land Problem 3: m = 2 mid-wall deformation",
        runs_subdir="",
        panels=(
            Panel("(a)", (-10.0, 0.0), (-20.0, 5.0), (-10.0, -5.0, 0.0),
                  (-20.0, -15.0, -10.0, -5.0, 0.0, 5.0), 142.0, 245.0, 104.0, 260.0, 8),
            Panel("(b)", (-2.0, 0.0), (-15.0, -13.0), (-2.0, -1.5, -1.0, -0.5, 0.0),
                  (-15.0, -14.5, -14.0, -13.5, -13.0), 50.0, 42.0, 154.0, 154.0, 2),
            # The paper layer had a single x tick (-8.5); the labels -8.75 and
            # -8.25 were added by hand in Keynote.  They are drawn natively here.
            Panel("(c)", (-8.75, -8.25), (-2.0, 2.0), (-8.75, -8.5, -8.25),
                  (-2.0, -1.0, 0.0, 1.0, 2.0), 265.0, 42.0, 154.0, 154.0, 2),
        ),
    ),
}


def read_midline(path: Path) -> list[tuple[float, float]]:
    """Read x and z from an OpenFOAM midline result (m) and convert to mm."""
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


def fmt(value: float) -> str:
    return f"{value:g}"


def draw_marker(pdf, x, y, series: Series, size: float = MARKER_SIZE) -> None:
    pdf.setStrokeColor(series.colour)
    pdf.setFillColor(colors.white)
    pdf.setLineWidth(MARKER_LINE_WIDTH)
    if series.marker == "circle":
        pdf.circle(x, y, size, stroke=1, fill=1)
    elif series.marker == "square":
        pdf.rect(x - size, y - size, 2 * size, 2 * size, stroke=1, fill=1)
    else:
        path = pdf.beginPath()
        path.moveTo(x, y + size + 0.4)
        path.lineTo(x - size - 0.3, y - size)
        path.lineTo(x + size + 0.3, y - size)
        path.close()
        pdf.drawPath(path, stroke=1, fill=1)


def draw_axes(pdf, panel: Panel) -> None:
    top = panel.bottom + panel.height
    right = panel.left + panel.width

    pdf.setStrokeColor(GRID)
    pdf.setLineWidth(GRID_LINE_WIDTH)
    pdf.setDash(1.0, 2.0)
    for value in panel.x_ticks:
        x = tx(panel, value)
        pdf.line(x, panel.bottom, x, top)
    for value in panel.y_ticks:
        y = ty(panel, value)
        pdf.line(panel.left, y, right, y)
    pdf.setDash()

    pdf.setStrokeColor(INK)
    pdf.setLineWidth(FRAME_LINE_WIDTH)
    pdf.rect(panel.left, panel.bottom, panel.width, panel.height, stroke=1, fill=0)
    tick = 3.0 / LAYER_SCALE * 0.8
    for value in panel.x_ticks:
        x = tx(panel, value)
        pdf.line(x, panel.bottom, x, panel.bottom - tick)
    for value in panel.y_ticks:
        y = ty(panel, value)
        pdf.line(panel.left, y, panel.left - tick, y)

    pdf.setFillColor(INK)
    pdf.setFont(FONT, TICK_FONT_SIZE)
    for value in panel.x_ticks:
        pdf.drawCentredString(tx(panel, value), panel.bottom - tick - 1.5 - 0.72 * TICK_FONT_SIZE, fmt(value))
    tick_width = max(pdfmetrics.stringWidth(fmt(v), FONT, TICK_FONT_SIZE) for v in panel.y_ticks)
    for value in panel.y_ticks:
        pdf.drawRightString(panel.left - tick - 2.0, ty(panel, value) - 0.36 * TICK_FONT_SIZE, fmt(value))

    pdf.setFont(FONT, AXIS_FONT_SIZE)
    pdf.drawCentredString((panel.left + right) / 2.0, panel.bottom - 29.5, "x [mm]")
    pdf.saveState()
    # rotated label: glyphs extend ~0.72 em to the left of the baseline
    pdf.translate(panel.left - tick - 2.0 - tick_width - 6.0, (panel.bottom + top) / 2.0)
    pdf.rotate(90)
    pdf.drawCentredString(0.0, 0.0, "z [mm]")
    pdf.restoreState()

    label_y = top + (2.0 if panel.label == "(a)" else 8.0)
    pdf.setFont(FONT_BOLD, PANEL_FONT_SIZE)
    pdf.drawString(panel.left - 28.0, label_y, panel.label)


def draw_series(pdf, panel: Panel, points, series: Series) -> None:
    mapped = [(tx(panel, x), ty(panel, z)) for x, z in points]
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


def draw_legend(pdf, x: float = 276.0, y: float = 356.0, series_list=None) -> None:
    series_list = SERIES if series_list is None else series_list
    row_height = 1.9 * LEGEND_FONT_SIZE
    sample_width = 25.0
    text_width = max(pdfmetrics.stringWidth(item.label, FONT, LEGEND_FONT_SIZE) for item in series_list)
    box_width = 12.0 + sample_width + 8.0 + text_width + 12.0
    box_height = 12.0 + row_height * len(series_list)

    # White opaque patch without a frame, as for every other legend of the
    # paper (paper_figure_style.legend); the HPC layer had a grey frame.
    pdf.setFillColor(colors.white)
    pdf.roundRect(x, y, box_width, box_height, 2.5, stroke=0, fill=1)

    row_y = y + box_height - 10.0 - 0.72 * LEGEND_FONT_SIZE
    pdf.setFont(FONT, LEGEND_FONT_SIZE)
    for series in series_list:
        sample_y = row_y + 0.36 * LEGEND_FONT_SIZE
        pdf.setStrokeColor(series.colour)
        pdf.setLineWidth(SERIES_LINE_WIDTH)
        pdf.line(x + 9.0, sample_y, x + 9.0 + sample_width, sample_y)
        draw_marker(pdf, x + 9.0 + sample_width / 2.0, sample_y, series)
        pdf.setFillColor(INK)
        pdf.drawString(x + 9.0 + sample_width + 7.0, row_y, series.label)
        row_y -= row_height


def draw_magnification_guides(pdf, panels) -> None:
    full = panels[0]
    pdf.setStrokeColor(PANEL_GUIDE)
    pdf.setLineWidth(0.65)
    pdf.setDash(2.0, 1.8)
    for panel in panels[1:]:
        x0, x1 = (tx(full, value) for value in panel.x_bounds)
        y0, y1 = (ty(full, value) for value in panel.y_bounds)
        pdf.rect(x0, y0, x1 - x0, y1 - y0, stroke=1, fill=0)
    pdf.setDash()


def render(problem: int, data_dir: Path, output: Path, series_json: Path | None = None,
           meshes: tuple[int, ...] = (1, 2, 3), runs_subdir: str | None = None) -> Path:
    """Draw the mid-wall lines of the requested mesh levels.

    Every requested level must have a ``midLineDeformed.txt``; a missing file
    is an error, so that a curve is never left out without notice.
    """
    spec = PROBLEMS[problem]
    subdir = spec["runs_subdir"] if runs_subdir is None else runs_subdir
    base = data_dir / subdir if subdir else data_dir
    wanted = {f"mesh{level}" for level in meshes}
    unknown = wanted - {s.mesh for s in SERIES}
    if unknown or not wanted:
        raise ValueError(f"mesh levels must be chosen from 1, 2, 3; received {sorted(meshes)}")
    series_list = [s for s in SERIES if s.mesh in wanted]
    missing = [str(base / s.mesh / "midLineDeformed.txt") for s in series_list
               if not (base / s.mesh / "midLineDeformed.txt").is_file()]
    if missing:
        raise FileNotFoundError("missing mid-wall result(s): " + ", ".join(missing))
    datasets = {s.mesh: read_midline(base / s.mesh / "midLineDeformed.txt") for s in series_list}

    output.parent.mkdir(parents=True, exist_ok=True)
    pdf = canvas.Canvas(str(output), pagesize=(PAGE_WIDTH, PAGE_HEIGHT), pageCompression=1,
                        initialFontName=FONT, initialFontSize=TICK_FONT_SIZE)
    pdf.setTitle(spec["title"])
    pdf.setSubject("Data layer: full line, apical and inflection regions (restyled 2026-10-29, geometry unchanged)")
    pdf.setAuthor("solids4foam")
    for panel in spec["panels"]:
        draw_axes(pdf, panel)
        for series in series_list:
            draw_series(pdf, panel, datasets[series.mesh], series)
    draw_magnification_guides(pdf, spec["panels"])
    draw_legend(pdf, series_list=series_list)
    pdf.showPage()
    pdf.save()
    if series_json is not None:
        import json

        series_json.parent.mkdir(parents=True, exist_ok=True)
        series_json.write_text(json.dumps({
            f"land_problem{problem}_layer": {
                "series": {s.mesh: {"x": [p[0] for p in datasets[s.mesh]], "y": [p[1] for p in datasets[s.mesh]]}
                           for s in series_list},
                "panels": [p.__dict__ for p in spec["panels"]],
            }
        }, indent=1))
    print(f"Wrote {output} (mesh levels: {' '.join(s.mesh[4:] for s in series_list)})")
    if len(series_list) < len(SERIES):
        print(f"NOTE: {output.name} is incomplete with respect to the paper figure, which shows "
              "mesh levels 1 2 3")
    return output


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--problem", type=int, choices=(2, 3), required=True)
    parser.add_argument("--data-dir", type=Path, required=True,
                        help="directory containing mesh{1,2,3}/midLineDeformed.txt (see --runs-subdir)")
    parser.add_argument("--runs-subdir", default=None,
                        help="sub-directory of --data-dir that holds the meshN folders "
                             "(default: 'runs' for problem 2 and none for problem 3, the paperData layout; "
                             "pass '' when --data-dir is the runs directory itself)")
    parser.add_argument("--meshes", type=int, nargs="+", default=(1, 2, 3), choices=(1, 2, 3),
                        help="mesh levels to draw (default: 1 2 3, the paper figure); every one must exist")
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--dump-series", type=Path)
    args = parser.parse_args()
    try:
        render(args.problem, args.data_dir, args.output, args.dump_series,
               meshes=tuple(args.meshes), runs_subdir=args.runs_subdir)
    except (OSError, ValueError) as error:
        raise SystemExit(f"ERROR: {error}") from error


if __name__ == "__main__":
    main()
