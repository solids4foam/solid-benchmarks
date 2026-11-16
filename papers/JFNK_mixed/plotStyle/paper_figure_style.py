#!/usr/bin/env python3
"""Shared publication style for the figures of the JFNK mixed-formulation paper.

Design rules (derived from the linear Cook's membrane figures, 26 Oct 2026,
`linearElastic/cooksMembrane/plotScripts/plot_paper.py`, and adjusted so that
the text is readable at the size printed in the cas-sc manuscript):

* Every figure is drawn at its printed size.  cas-sc has
  ``\\linewidth = 468.33 pt`` (6.48 in), body text 10 pt, captions 9 pt.  The
  font sizes below are therefore the printed sizes: legend, tick and
  annotation text is 8 pt (80 % of the body text), axis labels 9 pt.
* Font family Helvetica (the macOS TrueType file), embedded as a subset
  (``pdf.fonttype 42``); mathematics is set in the same family so that
  ``$m$``, ``$s_p^\\star$`` and ``$\\theta/\\pi$`` match the surrounding text.
* Full axes box, ticks outside on the bottom/left, a subtle dotted light-grey
  major grid drawn behind the data, white legend background without a frame.
* Line width 1.1 pt, open markers 4.5 pt with 1.0 pt edges.
* Method identities (colour, marker) are fixed across the paper, see
  :data:`METHOD_STYLES`.  Quantities that are not methods (pressure-scale
  sweeps, mesh families, mesh levels, error measures) use their own,
  separately documented encodings so that method colours are never reused
  for unrelated quantities.

Usage::

    import paper_figure_style as pfs
    pfs.apply_style()
    fig, ax = pfs.new_figure(width_fraction=0.49)
    ax.plot(x, y, **pfs.line_kwargs("coupled_m2"))
    pfs.style_axes(ax)
    pfs.legend(ax)
    pfs.save(fig, "figure.pdf")
"""

from __future__ import annotations

import json
import math
import os
import shutil
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
from matplotlib.lines import Line2D  # noqa: E402

# ---------------------------------------------------------------------------
# Manuscript geometry (measured with a cas-sc probe document, TeX Live 2025)
# ---------------------------------------------------------------------------
LINEWIDTH_PT = 468.3324          # \linewidth = \textwidth = \columnwidth
TEX_PT_PER_IN = 72.27
LINEWIDTH_IN = LINEWIDTH_PT / TEX_PT_PER_IN   # 6.480 in
BODY_FONT_PT = 10.0
CAPTION_FONT_PT = 9.0

# Printed font sizes [pt]
FONT_SIZES = {
    "tick": 8.0,
    "label": 9.0,
    "legend": 8.0,
    "legend_title": 8.0,
    "annotation": 8.0,
    "title": 9.0,
    "panel_label": 9.0,
}

FONT_FAMILY = "Helvetica"
FONT_FALLBACKS = ["Arial", "Liberation Sans", "DejaVu Sans"]

LINE_WIDTH = 1.1
MARKER_SIZE = 4.5
MARKER_EDGE_WIDTH = 1.0
REFERENCE_LINE_WIDTH = 1.1
GRID_COLOUR = "#D6D6D6"
INK = "#111111"


def fig_width(fraction: float) -> float:
    """Printed width [in] of a figure included at ``fraction * \\linewidth``."""
    return fraction * LINEWIDTH_IN


RC_PARAMS = {
    "font.family": "sans-serif",
    "font.sans-serif": [FONT_FAMILY, *FONT_FALLBACKS],
    "font.size": FONT_SIZES["annotation"],
    "axes.labelsize": FONT_SIZES["label"],
    "axes.titlesize": FONT_SIZES["title"],
    "xtick.labelsize": FONT_SIZES["tick"],
    "ytick.labelsize": FONT_SIZES["tick"],
    "legend.fontsize": FONT_SIZES["legend"],
    "legend.title_fontsize": FONT_SIZES["legend_title"],
    "figure.titlesize": FONT_SIZES["title"],
    "mathtext.fontset": "custom",
    "mathtext.rm": FONT_FAMILY,
    "mathtext.it": f"{FONT_FAMILY}:italic",
    "mathtext.bf": f"{FONT_FAMILY}:bold",
    "mathtext.default": "it",
    "mathtext.fallback": "stixsans",
    "pdf.fonttype": 42,
    "ps.fonttype": 42,
    "pdf.compression": 6,
    "axes.linewidth": 0.8,
    "axes.edgecolor": INK,
    "axes.labelcolor": INK,
    "axes.axisbelow": True,
    "axes.grid": True,
    "axes.grid.which": "major",
    "grid.color": GRID_COLOUR,
    "grid.linewidth": 0.5,
    "grid.linestyle": (0, (1.0, 2.0)),
    "xtick.direction": "out",
    "ytick.direction": "out",
    "xtick.major.size": 3.0,
    "ytick.major.size": 3.0,
    "xtick.minor.size": 1.8,
    "ytick.minor.size": 1.8,
    "xtick.major.width": 0.7,
    "ytick.major.width": 0.7,
    "xtick.minor.width": 0.5,
    "ytick.minor.width": 0.5,
    "xtick.color": INK,
    "ytick.color": INK,
    "xtick.top": False,
    "ytick.right": False,
    "lines.linewidth": LINE_WIDTH,
    "lines.markersize": MARKER_SIZE,
    "lines.markeredgewidth": MARKER_EDGE_WIDTH,
    "legend.frameon": True,
    "legend.framealpha": 1.0,
    "legend.edgecolor": "none",
    "legend.fancybox": False,
    "legend.borderpad": 0.3,
    "legend.labelspacing": 0.3,
    "legend.handlelength": 2.2,
    "legend.handletextpad": 0.6,
    "legend.borderaxespad": 0.4,
    "legend.columnspacing": 1.2,
    "figure.dpi": 100,
    "savefig.dpi": 300,
    "savefig.pad_inches": 0.01,
}


def apply_style() -> None:
    """Install the shared rcParams (idempotent)."""
    plt.rcParams.update(RC_PARAMS)


# ---------------------------------------------------------------------------
# Identity encodings
# ---------------------------------------------------------------------------
@dataclass(frozen=True)
class SeriesStyle:
    label: str
    colour: str
    marker: str
    linestyle: object = "-"
    filled: bool = False
    zorder: float = 3.0
    linewidth: float = LINE_WIDTH

    def kwargs(self, **overrides) -> dict:
        kw = {
            "color": self.colour,
            "marker": self.marker,
            "linestyle": self.linestyle,
            "linewidth": self.linewidth,
            "markersize": MARKER_SIZE,
            "markeredgewidth": MARKER_EDGE_WIDTH,
            "markeredgecolor": self.colour,
            "markerfacecolor": self.colour if self.filled else "none",
            "zorder": self.zorder,
            "label": self.label,
        }
        kw.update(overrides)
        return kw


# Pressure-stabilisation method identities.  Colours are the linear Cook's
# palette (plot_paper.py, 26 Oct 2026); the coupled m = 0 rose was darkened
# slightly (#D7AAAA -> #D08C8C) for legibility on white.  Markers separate the
# coupled members from each other and from the separately implemented
# JST-type / Laplacian / Rhie-Chow constructions, so the series remain
# distinguishable in greyscale and under colour-vision deficiency.
# Index convention (manuscript, 29 Oct 2026): m = laplacianPower, i.e.
# m = 0 Laplacian (order 2), m = 1 bi-Laplacian (order 4), m = 2 sixth order.
# Run and file names evenlap_m0/m1/m2 already use this zero-based index; the
# OLD manuscript labels "m = 1/2/3" referred to the same operators.
METHOD_STYLES: dict[str, SeriesStyle] = {
    "jst": SeriesStyle("JST-type", "#4C78A8", "s"),
    "laplacian": SeriesStyle("Laplacian", "#5B8E55", "o"),
    "rhiechow": SeriesStyle("Rhie–Chow", "#7B6AA8", "^"),
    "coupled_m0": SeriesStyle("Coupled $m = 0$", "#D08C8C", "x"),
    "coupled_m1": SeriesStyle("Coupled $m = 1$", "#B85C4B", "+"),
    "coupled_m2": SeriesStyle("Coupled $m = 2$", "#7A2738", "D"),
}
# Aliases used by the case/run naming (laplacianPower) and by the Fourier CSVs.
METHOD_ALIASES = {
    "evenlap_m0": "coupled_m0",
    "evenlap_m1": "coupled_m1",
    "evenlap_m2": "coupled_m2",
    "gen0": "coupled_m0",
    "gen1": "coupled_m1",
    "gen2": "coupled_m2",
    "JST": "jst",
    "RhieChow": "rhiechow",
}


def method_style(key: str) -> SeriesStyle:
    return METHOD_STYLES[METHOD_ALIASES.get(key, key)]


# Literature / benchmark references.  A single reference curve is black and
# dashed; when several references share a panel they get distinct greys,
# dash patterns and markers (in this order).
REFERENCE_STYLES: list[SeriesStyle] = [
    SeriesStyle("Reference", "#111111", "v", linestyle=(0, (5, 3)), zorder=2.5,
                linewidth=REFERENCE_LINE_WIDTH),
    SeriesStyle("Reference 2", "#5A5A5A", "s", linestyle=(0, (3, 2, 1, 2)), zorder=2.4,
                linewidth=REFERENCE_LINE_WIDTH),
    SeriesStyle("Reference 3", "#9B9B9B", "^", linestyle=(0, (1.5, 2)), zorder=2.3,
                linewidth=REFERENCE_LINE_WIDTH),
    SeriesStyle("Reference 4", "#3B3B3B", "o", linestyle=(0, (7, 2, 1, 2, 1, 2)), zorder=2.2,
                linewidth=REFERENCE_LINE_WIDTH),
]

# Pressure-coefficient sweep (linear Cook's Figs 8/18): an ORDERED quantity,
# so a sequential colour map (viridis, truncated to keep the light end
# readable).  Colours are NOT method colours; the marker in each panel is the
# marker of the method shown in that panel.
PRESSURE_SCALE_ORDER = ("0.01", "0.1", "1", "10", "100", "1000")


def pressure_scale_colours() -> dict[str, str]:
    cmap = matplotlib.colormaps["viridis"]
    n = len(PRESSURE_SCALE_ORDER)
    positions = [0.04 + 0.84 * i / (n - 1) for i in range(n)]
    return {
        scale: matplotlib.colors.to_hex(cmap(pos))
        for scale, pos in zip(PRESSURE_SCALE_ORDER, positions)
    }


# Mesh families of the manufactured solution (Figs 3-5): Okabe-Ito colours,
# one marker per family.  The ERROR MEASURE is encoded by the marker fill and
# line style: cell-wise RMS = filled marker, solid line; maximum = open marker,
# dashed line.
MESH_FAMILY_STYLES: dict[str, SeriesStyle] = {
    "hex": SeriesStyle("Hexahedral", "#0072B2", "o"),
    "distHex": SeriesStyle("Distorted hexahedral", "#E69F00", "^"),
    "poly": SeriesStyle("Polyhedral", "#009E73", "s"),
}
ERROR_MEASURE_STYLES = {
    "rms": {"filled": True, "linestyle": "-", "label": "Cell-wise RMS"},
    "max": {"filled": False, "linestyle": (0, (4, 2)), "label": "Maximum"},
}

# Mesh levels of the ventricular benchmarks (Figs 15/16): Okabe-Ito.
MESH_LEVEL_STYLES: dict[str, SeriesStyle] = {
    "mesh1": SeriesStyle("Mesh 1", "#0072B2", "o"),
    "mesh2": SeriesStyle("Mesh 2", "#D55E00", "s"),
    "mesh3": SeriesStyle("Mesh 3", "#009E73", "^"),
}

# Heart-tissue-beam reference statistics (Fig 13): three horizontal lines,
# distinct colours AND dash patterns.
LAND_STAT_STYLES: dict[str, SeriesStyle] = {
    "max": SeriesStyle("Land et al. (2015): maximum", "#009E73", "None",
                       linestyle=(0, (6, 2, 1.5, 2)), zorder=2.2),
    "median": SeriesStyle("Land et al. (2015): median", "#333333", "None",
                          linestyle="-", zorder=2.2),
    "min": SeriesStyle("Land et al. (2015): minimum", "#0072B2", "None",
                       linestyle=(0, (5, 3)), zorder=2.2),
}


def line_kwargs(key: str, **overrides) -> dict:
    """Keyword arguments for ``ax.plot`` for a method identity."""
    return method_style(key).kwargs(**overrides)


def reference_kwargs(index: int = 0, **overrides) -> dict:
    return REFERENCE_STYLES[index].kwargs(**overrides)


# ---------------------------------------------------------------------------
# Figure helpers
# ---------------------------------------------------------------------------
def new_figure(width_fraction: float = 0.49, aspect: float = 0.70, *,
               height_in: float | None = None, nrows: int = 1, ncols: int = 1,
               **subplot_kw):
    """Create a figure of the printed width.

    ``aspect`` is height / width of the whole figure; ``height_in`` overrides
    it.  Uses constrained layout so that labels never clip.
    """
    apply_style()
    width = fig_width(width_fraction)
    height = height_in if height_in is not None else width * aspect
    fig, axes = plt.subplots(nrows, ncols, figsize=(width, height),
                             layout="constrained", **subplot_kw)
    fig.get_layout_engine().set(w_pad=0.03, h_pad=0.03, wspace=0.04, hspace=0.04)
    return fig, axes


def style_axes(ax, *, grid: bool = True, minor: bool = False) -> None:
    """Apply the common axes look (box, outside ticks, subtle grid)."""
    for side in ("top", "right", "bottom", "left"):
        ax.spines[side].set_visible(True)
        ax.spines[side].set_linewidth(plt.rcParams["axes.linewidth"])
    ax.tick_params(which="both", direction="out", top=False, right=False)
    ax.grid(grid, which="major")
    ax.grid(False, which="minor")
    if minor:
        ax.minorticks_on()
    ax.set_axisbelow(True)


def legend(target, *args, **kwargs):
    """Legend with the common formatting (white opaque patch, no frame)."""
    kwargs.setdefault("frameon", True)
    kwargs.setdefault("framealpha", 1.0)
    kwargs.setdefault("edgecolor", "none")
    kwargs.setdefault("fancybox", False)
    leg = target.legend(*args, **kwargs)
    leg.get_frame().set_linewidth(0.0)
    if leg.get_title():
        leg.get_title().set_fontsize(FONT_SIZES["legend_title"])
    return leg


def legend_overlaps(fig, ax, leg, *, samples: int = 24) -> list[tuple[str, int]]:
    """Return the plotted series whose points or segments lie under the legend.

    Every Line2D of ``ax`` is sampled (its data points plus ``samples``
    interior points per segment, in display space) and tested against the
    legend's window extent.  Used as an automatic QA check so that no legend
    hides data.
    """
    import numpy as np

    fig.canvas.draw()
    renderer = fig.canvas.get_renderer()
    bbox = leg.get_window_extent(renderer)
    hits: list[tuple[str, int]] = []
    for line in ax.get_lines():
        xy = line.get_xydata()
        if len(xy) == 0:
            continue
        pts = ax.transData.transform(xy)
        if len(pts) > 1:
            t = np.linspace(0.0, 1.0, samples + 2)[1:-1][:, None]
            seg = pts[:-1][:, None, :] * (1 - t) + pts[1:][:, None, :] * t
            pts = np.vstack([pts, seg.reshape(-1, 2)])
        inside = (
            (pts[:, 0] >= bbox.x0) & (pts[:, 0] <= bbox.x1)
            & (pts[:, 1] >= bbox.y0) & (pts[:, 1] <= bbox.y1)
        )
        if inside.any():
            hits.append((line.get_label(), int(inside.sum())))
    return hits


def assert_legend_clear(fig, ax, leg, context: str = "") -> None:
    """Report plotted data hidden by the legend.

    The legend positions were chosen for the published data.  A new run may
    put a curve under the legend; the figure is then still written and a
    warning is printed.  Set JFNK_PAPER_STRICT_LEGEND=1 to make it an error
    (the behaviour of the paperData copy of this module).
    """
    hits = legend_overlaps(fig, ax, leg)
    if hits:
        detail = ", ".join(f"{label} ({n})" for label, n in hits)
        message = f"legend covers plotted data{' in ' + context if context else ''}: {detail}"
        if os.environ.get("JFNK_PAPER_STRICT_LEGEND", "0") not in ("", "0"):
            raise RuntimeError(message)
        print(f"WARNING: {message}", file=sys.stderr)


def legend_handle(style: SeriesStyle, **overrides) -> Line2D:
    """A proxy artist for a style (used for shared legends)."""
    kw = style.kwargs(**overrides)
    label = kw.pop("label")
    return Line2D([], [], label=label, **kw)


def panel_label(ax, text: str, *, loc: str = "left") -> None:
    """Bold panel label such as (a), only for figures where LaTeX does not add one."""
    ax.set_title(text, loc=loc, fontsize=FONT_SIZES["panel_label"],
                 fontweight="bold", pad=3)


def annotate(ax, text: str, xy, **kwargs):
    kwargs.setdefault("fontsize", FONT_SIZES["annotation"])
    kwargs.setdefault("color", INK)
    return ax.text(*xy, text, transform=kwargs.pop("transform", ax.transAxes), **kwargs)


# ---------------------------------------------------------------------------
# Numerical-content record (for the before/after verification)
# ---------------------------------------------------------------------------
_RECORDS: dict[str, dict] = {}


def record_series(figure: str, name: str, x, y, **meta) -> None:
    """Record the exact arrays handed to matplotlib for one plotted series."""
    entry = _RECORDS.setdefault(figure, {"series": {}, "axes": {}})
    entry["series"][name] = {"x": [float(v) for v in x], "y": [float(v) for v in y], **meta}


def record_axes(figure: str, ax) -> None:
    entry = _RECORDS.setdefault(figure, {"series": {}, "axes": {}})
    entry["axes"] = {
        "xscale": ax.get_xscale(), "yscale": ax.get_yscale(),
        "xlim": [float(v) for v in ax.get_xlim()], "ylim": [float(v) for v in ax.get_ylim()],
        "xlabel": ax.get_xlabel(), "ylabel": ax.get_ylabel(),
    }
    warn_outside_axes(figure)


def warn_outside_axes(figure: str) -> list[tuple[str, int, int]]:
    """Warn when recorded points of ``figure`` lie outside its axis window.

    The axis windows are those of the published figures.  Results of a new
    run can fall outside them and would then be clipped without notice, so
    every such series is reported as (name, points outside, points).
    """
    entry = _RECORDS.get(figure, {})
    axes = entry.get("axes") or {}
    if "xlim" not in axes or "ylim" not in axes:
        return []
    (x0, x1), (y0, y1) = sorted(axes["xlim"]), sorted(axes["ylim"])
    tol_x, tol_y = 1e-9 * max(abs(x0), abs(x1), 1e-300), 1e-9 * max(abs(y0), abs(y1), 1e-300)
    outside = []
    for name, data in entry.get("series", {}).items():
        if name.startswith("guide"):
            continue        # slope guides are drawn across the window on purpose
        pairs = [(x, y) for x, y in zip(data["x"], data["y"]) if math.isfinite(x) and math.isfinite(y)]
        n = sum(1 for x, y in pairs
                if not (x0 - tol_x <= x <= x1 + tol_x and y0 - tol_y <= y <= y1 + tol_y))
        if n:
            outside.append((name, n, len(pairs)))
            print(f"WARNING: {figure}: {n} of {len(pairs)} points of '{name}' lie outside the "
                  f"axis window x {axes['xlim']}, y {axes['ylim']} and are not visible",
                  file=sys.stderr)
    entry["outside_axes"] = {name: n for name, n, _ in outside}
    return outside


def write_records(path) -> None:
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    Path(path).write_text(json.dumps(_RECORDS, indent=1, sort_keys=True))


# ---------------------------------------------------------------------------
# Export
# ---------------------------------------------------------------------------
def fonts_embedded(pdf_path) -> tuple[bool, str]:
    """Check with poppler's pdffonts that every font is embedded."""
    exe = shutil.which("pdffonts")
    if exe is None:
        return True, "pdffonts not available; embedding not checked"
    out = subprocess.run([exe, str(pdf_path)], capture_output=True, text=True, check=False).stdout
    lines = out.splitlines()[2:]
    bad = []
    for line in lines:
        fields = line.split()
        if not fields:
            continue
        # columns: name type encoding emb sub uni object ID
        emb = fields[-5]
        if emb != "yes":
            bad.append(fields[0])
    return (not bad), out


def save(fig, path, *, title: str | None = None, metadata: dict | None = None,
         close: bool = True, check_fonts: bool = True) -> Path:
    """Write a vector PDF with embedded fonts and PDF metadata."""
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    meta = {"Creator": "JFNK mixed paper figures (paper_figure_style.py)"}
    if title:
        meta["Title"] = title
    if metadata:
        meta.update(metadata)
    fig.savefig(path, format="pdf", metadata=meta)
    if close:
        plt.close(fig)
    if check_fonts:
        ok, report = fonts_embedded(path)
        if not ok:
            raise RuntimeError(f"non-embedded font in {path}:\n{report}")
    return path


__all__ = [
    "LINEWIDTH_IN", "LINEWIDTH_PT", "BODY_FONT_PT", "CAPTION_FONT_PT", "FONT_SIZES",
    "FONT_FAMILY", "LINE_WIDTH", "MARKER_SIZE", "MARKER_EDGE_WIDTH", "INK", "GRID_COLOUR",
    "SeriesStyle", "METHOD_STYLES", "METHOD_ALIASES", "REFERENCE_STYLES",
    "PRESSURE_SCALE_ORDER", "pressure_scale_colours", "MESH_FAMILY_STYLES",
    "ERROR_MEASURE_STYLES", "MESH_LEVEL_STYLES", "LAND_STAT_STYLES",
    "apply_style", "fig_width", "new_figure", "style_axes", "legend", "legend_handle",
    "legend_overlaps", "assert_legend_clear",
    "panel_label", "annotate", "line_kwargs", "reference_kwargs", "method_style",
    "record_series", "record_axes", "warn_outside_axes", "write_records", "save", "fonts_embedded",
]
