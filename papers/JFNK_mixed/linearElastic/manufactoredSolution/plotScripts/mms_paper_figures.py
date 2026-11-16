#!/usr/bin/env python3
"""Manufactured-solution convergence figures (manuscript Figs 3-5).

Replaces the six gnuplot scripts ``{disp,stress,pressure}Errors.gnuplot`` and
``orderOfAccuracy{Disp,Stress,Pressure}.gnuplot`` (kept next to this file)
with one generator in the shared manuscript style.  The data selection, the mesh
spacing model and every numerical transformation are those of the gnuplot
scripts:

* mesh spacing  h = 1e3 * dx / 2**(mesh-1) mm with dx = 0.04 m (error plots)
  and h = 1e3 * dx / 2**k mm for the k-th successive pair (order plots);
* displacement errors: columns D_L2, D_Linf [m] x 1e6 -> [um];
* stress errors:       columns S_L2, S_Linf [Pa] x 1e-6 -> [MPa];
* pressure errors:     columns P_L2, P_Linf [Pa] x 1e-6 -> [MPa];
* observed orders:     orderOfAccuracy.txt columns (2,3), (4,5), (6,7);
* slope guides:        orderOfAccuracySlopes*.dat, first-order column x 7 for
  the displacement plot (as in dispErrors.gnuplot), otherwise unchanged.

"L2" in the summary files is the equally weighted cell-wise RMS of the
cell error (``sqrt(mean(e^2))`` in build_summaries.py / the function object's
``gAverage``), so it is labelled "cell-wise RMS"; "Linf" is the maximum cell
error, labelled "maximum".  Nothing is re-weighted by cell volume.

Outputs (manuscript file names): mms_dispErrors.pdf,
mms_disp_orderOfAccuracy.pdf, mms_stressErrors_v2.pdf,
mms_stress_orderOfAccuracy_v2.pdf, mms_pressureErrors.pdf,
mms_pressure_orderOfAccuracy.pdf.
"""

from __future__ import annotations

import argparse
import dataclasses
import math
import os
import sys
from pathlib import Path


def _load_paper_style():
    candidates = [Path(os.environ["JFNK_PAPER_STYLE_DIR"])] if "JFNK_PAPER_STYLE_DIR" in os.environ else []
    candidates += [parent / "plotStyle" for parent in Path(__file__).resolve().parents]
    for directory in candidates:
        if (directory / "paper_figure_style.py").is_file():
            sys.path.insert(0, str(directory))
            import paper_figure_style  # noqa: E402

            return paper_figure_style
    raise SystemExit("ERROR: paper_figure_style.py not found (set JFNK_PAPER_STYLE_DIR)")


pfs = _load_paper_style()
import numpy as np  # noqa: E402
from matplotlib.ticker import FixedLocator, FuncFormatter, LogLocator, MultipleLocator, NullFormatter  # noqa: E402

SCRIPT_DIR = Path(__file__).resolve().parent
DX_M = 0.04                      # nominal spacing of mesh 1 [m]
FAMILIES = ("hex", "distHex", "poly")
# quantity -> (summary RMS col, summary max col, order RMS col, order max col,
#              y scale factor, y label, slope file, first-order multiplier,
#              error y-limits, error file, order file)
QUANTITIES = {
    "disp": dict(
        rms_col=3, max_col=4, order_rms_col=1, order_max_col=2, scale=1e6,
        ylabel="Displacement error [μm]", slopes="orderOfAccuracySlopesDisp.dat",
        first_order_factor=7.0, error_ylim=(2e-4, 5.0),
        error_file="mms_dispErrors.pdf", order_file="mms_disp_orderOfAccuracy.pdf",
    ),
    "stress": dict(
        rms_col=5, max_col=6, order_rms_col=3, order_max_col=4, scale=1e-6,
        ylabel="Stress error [MPa]", slopes="orderOfAccuracySlopesStress.dat",
        first_order_factor=1.0, error_ylim=(1e-3, 10.0),
        error_file="mms_stressErrors_v2.pdf", order_file="mms_stress_orderOfAccuracy_v2.pdf",
    ),
    "pressure": dict(
        rms_col=9, max_col=10, order_rms_col=5, order_max_col=6, scale=1e-6,
        ylabel="Pressure error [MPa]", slopes="orderOfAccuracySlopesPressure.dat",
        first_order_factor=1.0, error_ylim=(1e-3, 10.0),
        error_file="mms_pressureErrors.pdf", order_file="mms_pressure_orderOfAccuracy.pdf",
    ),
}
X_LABEL = "Average cell spacing [mm]"
ORDER_LABEL = "Observed order of accuracy"
ERROR_XLIM = (1.8, 55.0)
ORDER_XLIM = (1.8, 28.0)
ORDER_YLIM = (0.0, 3.0)
PANEL_WIDTH_FRACTION = 0.49
PANEL_HEIGHT_IN = 2.75


def read_table(path: Path) -> np.ndarray:
    rows = []
    for line in path.read_text().splitlines():
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        rows.append([float(v) for v in line.split()])
    if not rows:
        raise ValueError(f"no data rows in {path}")
    width = {len(r) for r in rows}
    if len(width) != 1:
        raise ValueError(f"ragged table in {path}")
    return np.array(rows)


def load(data_dir: Path, slope_dir: Path):
    tables = {}
    for family in FAMILIES:
        summary = data_dir / f"{family}.hypre.summary.txt"
        order = data_dir / f"{family}.hypre.orderOfAccuracy.txt"
        for path in (summary, order):
            if not path.is_file():
                raise FileNotFoundError(f"missing input: {path}")
        tables[family] = (read_table(summary), read_table(order))
    slopes = {}
    for key, spec in QUANTITIES.items():
        path = slope_dir / spec["slopes"]
        if not path.is_file():
            raise FileNotFoundError(f"missing slope file: {path}")
        slopes[key] = read_table(path)
    return tables, slopes


def family_kwargs(family: str, measure: str, **overrides) -> dict:
    style = pfs.MESH_FAMILY_STYLES[family]
    spec = pfs.ERROR_MEASURE_STYLES[measure]
    kw = dataclasses.replace(style, filled=spec["filled"], linestyle=spec["linestyle"]).kwargs()
    kw["markerfacecolor"] = style.colour if spec["filled"] else "white"
    kw["label"] = f"{style.label}, {spec['label'].lower()}"
    kw.update(overrides)
    return kw


def shared_legend(fig) -> None:
    """Two-row legend below the axes: mesh families, then error measures."""
    from matplotlib.lines import Line2D

    family_handles = [
        Line2D([], [], color=s.colour, marker=s.marker, linestyle="-",
               markerfacecolor=s.colour, markeredgecolor=s.colour,
               markersize=pfs.MARKER_SIZE, markeredgewidth=pfs.MARKER_EDGE_WIDTH,
               label=s.label.replace("Distorted hexahedral", "Distorted hex."))
        for s in pfs.MESH_FAMILY_STYLES.values()
    ]
    measure_handles = [
        Line2D([], [], color=pfs.INK, marker="o", linestyle=spec["linestyle"],
               markerfacecolor=pfs.INK if spec["filled"] else "white", markeredgecolor=pfs.INK,
               markersize=pfs.MARKER_SIZE, markeredgewidth=pfs.MARKER_EDGE_WIDTH,
               label=spec["label"])
        for spec in pfs.ERROR_MEASURE_STYLES.values()
    ]
    pad = Line2D([], [], linestyle="none", label=" ")
    # column-major fill: row 1 = families, row 2 = measures
    handles = [family_handles[0], measure_handles[0],
               family_handles[1], measure_handles[1],
               family_handles[2], pad]
    leg = fig.legend(handles=handles, ncols=3, loc="outside lower center",
                     frameon=False, handlelength=1.6, columnspacing=0.9,
                     handletextpad=0.5, borderaxespad=0.1)
    return leg


def slope_text(ax, x0, y0, x1, y1, text, *, above: bool) -> None:
    """Rotated label along a guide line (angle computed in display space)."""
    xm = math.sqrt(x0 * x1)
    ym = math.sqrt(y0 * y1)
    p0 = ax.transData.transform((x0, y0))
    p1 = ax.transData.transform((x1, y1))
    angle = math.degrees(math.atan2(p1[1] - p0[1], p1[0] - p0[0]))
    offset = 1.25 if above else 1 / 1.25
    ax.text(xm, ym * offset, text, rotation=angle, rotation_mode="anchor",
            ha="center", va="bottom" if above else "top",
            fontsize=pfs.FONT_SIZES["annotation"], color=pfs.INK, zorder=4)


def spacing_formatter():
    return FuncFormatter(lambda v, _: f"{v:g}")


def render_errors(path: Path, key: str, tables, slopes) -> None:
    spec = QUANTITIES[key]
    fig, ax = pfs.new_figure(PANEL_WIDTH_FRACTION, height_in=PANEL_HEIGHT_IN)
    ax.set_xscale("log")
    ax.set_yscale("log")
    pfs.style_axes(ax)
    for family in FAMILIES:
        summary, _ = tables[family]
        h = 1e3 * DX_M / 2.0 ** (summary[:, 0] - 1)
        for measure, col in (("rms", spec["rms_col"]), ("max", spec["max_col"])):
            y = spec["scale"] * summary[:, col]
            ax.plot(h, y, **family_kwargs(family, measure))
            pfs.record_series(path.name, f"{family}:{measure}", h, y)
    # slope guides (black, unlabeled, as in the gnuplot scripts)
    guide = slopes[key]
    gx = guide[:, 0]
    first = spec["first_order_factor"] * guide[:, 1]
    second = guide[:, 2]
    ax.plot(gx, first, color=pfs.INK, linewidth=1.0, zorder=2, label="_first")
    ax.plot(gx, second, color=pfs.INK, linewidth=1.0, zorder=2, label="_second")
    pfs.record_series(path.name, "guide:first-order", gx, first)
    pfs.record_series(path.name, "guide:second-order", gx, second)
    ax.set_xlim(ERROR_XLIM)
    ax.set_ylim(spec["error_ylim"])
    ax.set_xlabel(X_LABEL)
    ax.set_ylabel(spec["ylabel"])
    ax.xaxis.set_major_locator(FixedLocator([2.5, 5, 10, 20, 40]))
    ax.xaxis.set_major_formatter(spacing_formatter())
    ax.xaxis.set_minor_locator(NullLocator())
    ax.yaxis.set_major_locator(LogLocator(base=10, numticks=8))
    ax.yaxis.set_minor_locator(LogLocator(base=10, subs=range(2, 10), numticks=20))
    ax.yaxis.set_minor_formatter(NullFormatter())
    # guide labels, placed at the middle of the part of each line that is
    # visible inside the axes limits
    xlo, xhi = ERROR_XLIM
    ylo, yhi = spec["error_ylim"]
    for arr, text, above in ((first, "1st order", True), (second, "2nd order", False)):
        xs = np.geomspace(max(xlo, gx.min()), min(xhi, gx.max()), 400)
        ys = np.exp(np.interp(np.log(xs), np.log(gx), np.log(arr)))
        margin = 1.6 if above else 1 / 1.6      # keep the label clear of the frame
        visible = (ys * margin > ylo) & (ys * margin < yhi) & (ys > ylo) & (ys < yhi)
        xs, ys = xs[visible], ys[visible]
        if len(xs) < 2:
            continue
        i0, i1 = len(xs) // 2 - len(xs) // 8, len(xs) // 2 + len(xs) // 8
        slope_text(ax, xs[i0], ys[i0], xs[i1], ys[i1], text, above=above)
    shared_legend(fig)
    pfs.record_axes(path.name, ax)
    pfs.save(fig, path, title=f"Manufactured solution: {path.stem}")


def render_orders(path: Path, key: str, tables) -> None:
    spec = QUANTITIES[key]
    fig, ax = pfs.new_figure(PANEL_WIDTH_FRACTION, height_in=PANEL_HEIGHT_IN)
    ax.set_xscale("log")
    pfs.style_axes(ax)
    for family in FAMILIES:
        _, order = tables[family]
        h = 1e3 * DX_M / 2.0 ** order[:, 0]
        for measure, col in (("rms", spec["order_rms_col"]), ("max", spec["order_max_col"])):
            y = order[:, col]
            ax.plot(h, y, **family_kwargs(family, measure))
            pfs.record_series(path.name, f"{family}:{measure}", h, y)
    ax.set_xlim(ORDER_XLIM)
    ax.set_ylim(ORDER_YLIM)
    ax.set_xlabel(X_LABEL)
    ax.set_ylabel(ORDER_LABEL)
    ax.xaxis.set_major_locator(FixedLocator([2.5, 5, 10, 20]))
    ax.xaxis.set_major_formatter(spacing_formatter())
    ax.xaxis.set_minor_locator(NullLocator())
    ax.yaxis.set_major_locator(MultipleLocator(0.5))
    shared_legend(fig)
    pfs.record_axes(path.name, ax)
    pfs.save(fig, path, title=f"Manufactured solution: {path.stem}")


from matplotlib.ticker import NullLocator  # noqa: E402


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--data-dir", type=Path, required=True,
                        help="directory with {hex,distHex,poly}.hypre.{summary,orderOfAccuracy}.txt, "
                             "i.e. a run_* directory written by ../Allrun")
    parser.add_argument("--slope-dir", type=Path, default=SCRIPT_DIR,
                        help="directory with orderOfAccuracySlopes*.dat")
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--quantities", nargs="+", choices=tuple(QUANTITIES), default=tuple(QUANTITIES))
    parser.add_argument("--dump-series", type=Path)
    args = parser.parse_args()

    try:
        tables, slopes = load(args.data_dir.resolve(), args.slope_dir.resolve())
        # every plotted column must be present and finite: a NaN would leave a curve out without notice
        for key in args.quantities:
            spec = QUANTITIES[key]
            for family, (summary, order) in tables.items():
                for kind, table, columns in (
                    ("summary", summary, (spec["rms_col"], spec["max_col"])),
                    ("orderOfAccuracy", order, (spec["order_rms_col"], spec["order_max_col"])),
                ):
                    if table.shape[1] <= max(columns) or not np.isfinite(table[:, list(columns)]).all():
                        raise ValueError(
                            f"{family}.hypre.{kind}.txt in {args.data_dir} has missing or non-finite "
                            f"values for the {key} plots (columns {[c + 1 for c in columns]})")
    except (OSError, ValueError) as error:
        raise SystemExit(f"ERROR: {error}") from error
    args.output_dir.mkdir(parents=True, exist_ok=True)
    for key in args.quantities:
        spec = QUANTITIES[key]
        render_errors(args.output_dir / spec["error_file"], key, tables, slopes)
        render_orders(args.output_dir / spec["order_file"], key, tables)
        print(f"Wrote {spec['error_file']} and {spec['order_file']} to {args.output_dir}")
    if args.dump_series is not None:
        pfs.write_records(args.dump_series)


if __name__ == "__main__":
    main()
