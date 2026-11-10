#!/usr/bin/env python3
"""Compose a field-render figure: ParaView image layer + vector colour bar.

The field colours come from a PNG written by ``render_field_layer.py``
(pvpython; transparent background, no text).  This script places that image
at the printed size and adds the colour bar, tick labels and title in the
shared manuscript style (``plotStyle/paper_figure_style.py``: Helvetica,
8 pt ticks, 9 pt title), so that the text is legible at the final size.
The colour limits, number of discrete levels and unit factor are given
explicitly and are the ones of the original figure (documented in the
manifest); nothing is inferred from the bitmap.

Output: PDF (vector text, embedded raster) and/or PNG at a chosen dpi,
under the manuscript file name.
"""
from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path

import numpy as np
from PIL import Image


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
import matplotlib  # noqa: E402
import matplotlib.pyplot as plt  # noqa: E402
from matplotlib.colors import BoundaryNorm, Normalize  # noqa: E402
from matplotlib.colorbar import ColorbarBase  # noqa: E402


def trim(im: Image.Image, pad: int = 4) -> Image.Image:
    """Crop the transparent margin of the render."""
    alpha = np.asarray(im.convert("RGBA"))[:, :, 3]
    ys, xs = np.where(alpha > 0)
    if len(xs) == 0:
        return im
    x0, x1, y0, y1 = max(xs.min() - pad, 0), min(xs.max() + pad, im.width), max(ys.min() - pad, 0), min(ys.max() + pad, im.height)
    return im.crop((x0, y0, x1, y1))


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--layer", type=Path, required=True, help="PNG from render_field_layer.py")
    ap.add_argument("--width-fraction", type=float, required=True, help="\\includegraphics width / \\linewidth")
    ap.add_argument("--aspect", type=float, required=True, help="figure height / width")
    ap.add_argument("--range", required=True, help="lo,hi in DISPLAY units (after --unit-factor)")
    ap.add_argument("--levels", type=int, default=0, help="discrete colour levels (0 = continuous)")
    ap.add_argument("--ticks", default=None, help="comma-separated tick positions in display units (default: ends + round values)")
    ap.add_argument("--tick-format", default="{:g}")
    ap.add_argument("--tick-labels", default=None, help="comma-separated labels for --ticks (overrides --tick-format)")
    ap.add_argument("--title", required=True, help="colour-bar title, e.g. 'Equivalent stress [kPa]'")
    ap.add_argument("--cmap", default="viridis")
    ap.add_argument("--title-top", action="store_true", help="write the title horizontally above the bar instead of rotated beside it")
    ap.add_argument("--image-box", default="0.02,0.04,0.72,0.92", help="left,bottom,width,height of the image area (figure fractions)")
    ap.add_argument("--bar-box", default="0.80,0.12,0.035,0.76", help="left,bottom,width,height of the colour bar (figure fractions)")
    ap.add_argument("--out", type=Path, nargs="+", required=True, help="output file(s): .pdf and/or .png")
    ap.add_argument("--png-dpi", type=int, default=600)
    ap.add_argument("--metadata", type=Path, default=None, help="JSON from render_field_layer.py --dump (recorded in the PDF subject)")
    a = ap.parse_args()

    lo, hi = (float(v) for v in a.range.split(","))
    pfs.apply_style()
    width = pfs.fig_width(a.width_fraction)
    fig = plt.figure(figsize=(width, width * a.aspect))
    fig.patch.set_facecolor("white")

    im = trim(Image.open(a.layer))
    l, b, w, h = (float(v) for v in a.image_box.split(","))
    ax = fig.add_axes([l, b, w, h])
    ax.set_axis_off()
    # keep the image aspect: fit inside the box
    box_aspect = (h * width * a.aspect) / (w * width)
    im_aspect = im.height / im.width
    if im_aspect > box_aspect:
        hh = h; ww = h * (width * a.aspect) / width / im_aspect
    else:
        ww = w; hh = w * width / (width * a.aspect) * im_aspect
    ax.set_position([l + (w - ww) / 2, b + (h - hh) / 2, ww, hh])
    # Place the layer pixel-for-pixel: the figure dpi is set to the layer's
    # native density over its display width and the array is drawn with
    # figimage (no resampling); the output is saved at that same dpi.
    native_dpi = im.width / (ww * width)
    fig.set_dpi(native_dpi)
    x0_px = int(round((l + (w - ww) / 2) * width * native_dpi))
    y0_px = int(round((b + (h - hh) / 2) * width * a.aspect * native_dpi))
    fig.figimage(np.asarray(im.convert("RGBA")), xo=x0_px, yo=y0_px, origin="upper", zorder=1)

    cmap = matplotlib.colormaps[a.cmap]
    if a.levels > 0:
        cmap = matplotlib.colors.ListedColormap([cmap(i / (a.levels - 1)) for i in range(a.levels)])
        norm = BoundaryNorm(np.linspace(lo, hi, a.levels + 1), a.levels)
    else:
        norm = Normalize(lo, hi)
    bl, bb, bw, bh = (float(v) for v in a.bar_box.split(","))
    cax = fig.add_axes([bl, bb, bw, bh])
    cb = ColorbarBase(cax, cmap=cmap, norm=norm, orientation="vertical", spacing="uniform",
                      ticks=[float(v) for v in a.ticks.split(",")] if a.ticks else None, drawedges=False)
    cb.outline.set_linewidth(0.6)
    cb.ax.tick_params(labelsize=pfs.FONT_SIZES["tick"], width=0.7, length=3, direction="out")
    if a.ticks and a.tick_labels:
        cb.set_ticklabels(a.tick_labels.split(","))
    elif a.ticks:
        cb.set_ticklabels([a.tick_format.format(float(v)) for v in a.ticks.split(",")])
    if a.title_top:
        cax.set_title(a.title, fontsize=pfs.FONT_SIZES["label"], loc="left", pad=6)
    else:
        cb.set_label(a.title, fontsize=pfs.FONT_SIZES["label"], labelpad=6)

    meta = {"Creator": "JFNK mixed paper figures (compose_field_figure.py)", "Title": a.title}
    if a.metadata and a.metadata.is_file():
        meta["Subject"] = json.dumps(json.loads(a.metadata.read_text()))[:1000]
    for out in a.out:
        out.parent.mkdir(parents=True, exist_ok=True)
        if out.suffix.lower() == ".pdf":
            fig.savefig(out, format="pdf", metadata=meta, facecolor="white", dpi=native_dpi)
            ok, report = pfs.fonts_embedded(out)
            if not ok:
                raise RuntimeError(f"non-embedded font in {out}:\n{report}")
        else:
            fig.savefig(out, dpi=native_dpi, facecolor="white")
        print("Wrote", out)
    plt.close(fig)


if __name__ == "__main__":
    main()
