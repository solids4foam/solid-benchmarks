#!/usr/bin/env python3
"""Nonlinear Cook's membrane mesh-refinement figures (manuscript Figs 10b, 11).

Replaces the two ``stabVsLiterature.gnuplot`` scripts (compressible case in
this directory, near-incompressible case in
``../../LargeStrainIncompCooksMembrane/plotScripts``; both are kept) with the
shared manuscript style.  Data selection and transformations are unchanged:

Compressible, nu = 0.3 (LargeStrainCooksIncomp.pdf):
* present work: ``hex_snes__evenlap_m2.summary.txt`` meshes 1-8,
  x = dx / 2**(mesh-1) with dx = 12.649 mm, y = Uy [m] x 1000;
* Pelteret & McBride (2016) Q1 and Q2: ``deal.II.dat`` rows i = 0..5,
  x = dxZT / 2**i with dxZT = 18.973666 mm, y = columns 2 and 3 [mm];
* Abaqus CPE4H: ``abaqus.dat`` columns 2 (spacing [mm]) and 4 (Uy [mm]).

Strongly near-incompressible, nu = 0.4999
(largeStrainIncompCooksMembrane-neoHookeanTipDispConvergenceStabCompatible.pdf):
* present work: meshes >= 2 of the summary file, same transformation;
* Abaqus CPE4RH (384 x 384): constant 13.5843 mm (hard-coded in the original
  script; no source file on disk).

The ``m2`` in the run names is laplacianPower 2 = coupled m = 2 (sixth order).
"""

from __future__ import annotations

import argparse
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
from matplotlib.ticker import FixedLocator, FuncFormatter, LogLocator, MultipleLocator, NullFormatter  # noqa: E402

DX_MM = 12.649            # average cell spacing of mesh 1 (present work)
DX_ZT_MM = 18.973666      # average cell spacing of mesh 1 (Pelteret & McBride results)
ABAQUS_CPE4RH_MM = 13.5843
COMPRESSIBLE_FILE = "LargeStrainCooksIncomp.pdf"
INCOMPRESSIBLE_FILE = "largeStrainIncompCooksMembrane-neoHookeanTipDispConvergenceStabCompatible.pdf"
X_LABEL = "Average cell spacing [mm]"
Y_LABEL = "Vertical displacement [mm]"
PRESENT_LABEL = "Present work, coupled $m = 2$"
X_LIM = (0.098, 20.0)
COMPRESSIBLE_YLIM = (0.0, 17.0)
# Fig 11 ordinate: the manuscript range of the original gnuplot script
# (stabVsLiterature.gnuplot: `set yrange [0:16]`, `set xrange [0.098:20]`),
# restored on 30 Oct 2026 at the authors' request (a 13.3-13.8 mm range had
# been staged earlier that day).  All plotted values (13.45-13.71 mm) and the
# 13.5843 mm reference lie inside it.
INCOMPRESSIBLE_YLIM = (0.0, 16.0)


def read_rows(path: Path) -> list[list[float]]:
    rows = []
    for line in path.read_text().splitlines():
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        rows.append([float(v) for v in line.split()])
    if not rows:
        raise ValueError(f"no data in {path}")
    return rows


def present_work(summary: Path, min_mesh: int = 1) -> tuple[list[float], list[float]]:
    rows = [r for r in read_rows(summary) if int(r[0]) >= min_mesh]
    if not rows:
        raise ValueError(f"no rows with mesh >= {min_mesh} in {summary}")
    if any(len(r) < 4 or not math.isfinite(r[3]) for r in rows):
        raise ValueError(f"missing or non-finite displacement in {summary}")
    x = [DX_MM / 2.0 ** (int(r[0]) - 1) for r in rows]
    y = [r[3] * 1000.0 for r in rows]
    return x, y


def log_x_axis(ax) -> None:
    ax.set_xscale("log")
    ax.set_xlim(X_LIM)
    ax.xaxis.set_major_locator(FixedLocator([0.1, 1.0, 10.0]))
    ax.xaxis.set_major_formatter(FuncFormatter(lambda v, _: f"{v:g}"))
    ax.xaxis.set_minor_locator(LogLocator(base=10, subs=range(2, 10), numticks=20))
    ax.xaxis.set_minor_formatter(NullFormatter())
    ax.set_xlabel(X_LABEL)


def render_compressible(data_dir: Path, output_dir: Path, *, width_fraction: float = 0.60,
                        reference_dir: Path | None = None) -> Path:
    name = COMPRESSIBLE_FILE
    fig, ax = pfs.new_figure(width_fraction, 0.70)
    pfs.style_axes(ax)
    x, y = present_work(data_dir / "hex_snes__evenlap_m2.summary.txt")
    reference_dir = data_dir if reference_dir is None else reference_dir
    deal = read_rows(reference_dir / "deal.II.dat")
    dx_zt = [DX_ZT_MM / 2.0 ** i for i in range(len(deal))]
    q1 = [r[1] for r in deal]
    q2 = [r[2] for r in deal]
    abaqus = read_rows(reference_dir / "abaqus.dat")
    ax_x = [r[1] for r in abaqus]
    ax_y = [r[3] for r in abaqus]

    ax.plot(dx_zt, q1, **pfs.reference_kwargs(2, label="Pelteret & McBride (2016), Q1"))
    ax.plot(dx_zt, q2, **pfs.reference_kwargs(1, label="Pelteret & McBride (2016), Q2"))
    ax.plot(ax_x, ax_y, **pfs.reference_kwargs(0, label="Abaqus, CPE4H"))
    ax.plot(x, y, **pfs.line_kwargs("coupled_m2", label=PRESENT_LABEL, zorder=4))
    pfs.record_series(name, "present:coupled_m2", x, y)
    pfs.record_series(name, "Pelteret-McBride Q1", dx_zt, q1)
    pfs.record_series(name, "Pelteret-McBride Q2", dx_zt, q2)
    pfs.record_series(name, "Abaqus CPE4H", ax_x, ax_y)

    log_x_axis(ax)
    ax.set_ylim(COMPRESSIBLE_YLIM)
    ax.yaxis.set_major_locator(MultipleLocator(2))
    ax.set_ylabel(Y_LABEL)
    handles, labels = ax.get_legend_handles_labels()
    order = [labels.index(PRESENT_LABEL)] + [i for i, l in enumerate(labels) if l != PRESENT_LABEL]
    leg = pfs.legend(ax, [handles[i] for i in order], [labels[i] for i in order], loc="lower right")
    pfs.assert_legend_clear(fig, ax, leg, name)
    pfs.record_axes(name, ax)
    return pfs.save(fig, output_dir / name, title="Nonlinear Cook's membrane, nu = 0.3: mesh refinement")


def render_incompressible(data_dir: Path, output_dir: Path, *, width_fraction: float = 0.70,
                          ylim=INCOMPRESSIBLE_YLIM, name: str = INCOMPRESSIBLE_FILE) -> Path:
    fig, ax = pfs.new_figure(width_fraction, 0.62)
    pfs.style_axes(ax)
    x, y = present_work(data_dir / "hex_snes__evenlap_m2.summary.txt", min_mesh=2)
    ax.axhline(ABAQUS_CPE4RH_MM, **pfs.reference_kwargs(0, marker="None",
                                                         label=r"Abaqus, CPE4RH ($384\times384$)"))
    ax.plot(x, y, **pfs.line_kwargs("coupled_m2", label=PRESENT_LABEL, zorder=4))
    pfs.record_series(name, "present:coupled_m2", x, y)
    pfs.record_series(name, "Abaqus CPE4RH", [X_LIM[0], X_LIM[1]], [ABAQUS_CPE4RH_MM] * 2)
    log_x_axis(ax)
    ax.set_ylim(ylim)
    if ylim[1] - ylim[0] > 5:
        ax.yaxis.set_major_locator(MultipleLocator(2))
    else:
        ax.yaxis.set_major_locator(MultipleLocator(0.1))
        ax.yaxis.set_major_formatter(FuncFormatter(lambda v, _: f"{v:.1f}"))
    ax.set_ylabel(Y_LABEL)
    handles, labels = ax.get_legend_handles_labels()
    order = [labels.index(PRESENT_LABEL)] + [i for i, l in enumerate(labels) if l != PRESENT_LABEL]
    leg = pfs.legend(ax, [handles[i] for i in order], [labels[i] for i in order], loc="lower right")
    pfs.assert_legend_clear(fig, ax, leg, name)
    pfs.record_axes(name, ax)
    return pfs.save(fig, output_dir / name, title="Nonlinear Cook's membrane, nu = 0.4999: mesh refinement")


def main() -> None:
    script_dir = Path(__file__).resolve().parent
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--compressible-data", type=Path,
                        help="run directory of ../Allrun holding hex_snes__evenlap_m2.summary.txt (nu = 0.3)")
    parser.add_argument("--incompressible-data", type=Path,
                        help="run directory of ../../LargeStrainIncompCooksMembrane/Allrun holding "
                             "hex_snes__evenlap_m2.summary.txt (nu = 0.4999)")
    parser.add_argument("--reference-dir", type=Path, default=script_dir,
                        help="directory with the published reference tables deal.II.dat and abaqus.dat "
                             "(default: the directory of this script)")
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--dump-series", type=Path)
    args = parser.parse_args()
    if args.compressible_data is None and args.incompressible_data is None:
        parser.error("give --compressible-data and/or --incompressible-data; there is no default data set")
    args.output_dir.mkdir(parents=True, exist_ok=True)
    try:
        if args.compressible_data is not None:
            print("Wrote", render_compressible(args.compressible_data, args.output_dir,
                                               reference_dir=args.reference_dir))
        if args.incompressible_data is not None:
            print("Wrote", render_incompressible(args.incompressible_data, args.output_dir))
    except (OSError, ValueError, IndexError) as error:
        raise SystemExit(f"ERROR: {error}") from error
    if args.dump_series is not None:
        pfs.write_records(args.dump_series)


if __name__ == "__main__":
    main()
