#!/usr/bin/env python3
"""Create a paper montage from the optional Fourier visualisation fields."""

import argparse
import math
import re
from pathlib import Path


MODE_ORDER = ("xNyquist", "yNyquist", "checkerboard")
MODE_LABELS = {
    "xNyquist": r"$\boldsymbol{\theta}=(\pi,0)$",
    "yNyquist": r"$\boldsymbol{\theta}=(0,\pi)$",
    "checkerboard": r"$\boldsymbol{\theta}=(\pi,\pi)$",
}
DEFAULT_MODELS = ("laplacian", "JST", "gen2", "RhieChow")
MODEL_LABELS = {
    "laplacian": "Coupled $m=1$",
    "JST": "Coupled $m=2$ / JST",
    "gen0": "Generalised $m=1$",
    "gen1": "Generalised $m=2$",
    "gen2": "Coupled $m=3$",
    "diffStencil": "diffStencil",
    "RhieChow": "Rhie--Chow",
}


def read_internal_field(path):
    """Read a nonuniform ASCII OpenFOAM scalar internal field."""
    if not path.is_file():
        raise RuntimeError(
            f"Missing {path}; run ./AllrunVisualisation before plotting"
        )
    text = path.read_text()
    match = re.search(
        r"internalField\s+nonuniform\s+List<scalar>\s+"
        r"(\d+)\s*\(\s*(.*?)\s*\)\s*;",
        text,
        re.DOTALL,
    )
    if not match:
        raise RuntimeError(f"Cannot read nonuniform scalar field from {path}")
    count = int(match.group(1))
    values = [float(value) for value in match.group(2).split()]
    if len(values) != count:
        raise RuntimeError(
            f"Expected {count} internal values in {path}, found {len(values)}"
        )
    side = math.isqrt(count)
    if side * side != count:
        raise RuntimeError(
            f"The paper montage expects a square 2-D mesh, found {count} cells"
        )
    return values, side


def save_figure(fig, output_directory, stem):
    output_directory.mkdir(parents=True, exist_ok=True)
    png = output_directory / f"{stem}.png"
    pdf = output_directory / f"{stem}.pdf"
    fig.savefig(png, dpi=300, bbox_inches="tight")
    fig.savefig(pdf, bbox_inches="tight")
    print(f"Wrote {png} and {pdf}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--time",
        default="0",
        help="OpenFOAM time directory containing visualisation fields",
    )
    parser.add_argument(
        "--models",
        nargs="+",
        choices=tuple(MODEL_LABELS),
        default=DEFAULT_MODELS,
        help="filtered models to include after the original pressure column",
    )
    parser.add_argument(
        "--output",
        default="postProcessing/paperFigures",
        help="output directory for PNG and PDF figures",
    )
    args = parser.parse_args()
    time_directory = Path(args.time)

    try:
        import matplotlib
        import numpy as np
    except ModuleNotFoundError as error:
        parser.error(
            f"{error.name} is required; use a Python environment containing "
            "NumPy and Matplotlib"
        )

    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    columns = ("pressure", *args.models)
    fig, axes = plt.subplots(
        len(MODE_ORDER),
        len(columns),
        figsize=(2.45 * len(columns), 7.5),
        squeeze=False,
    )
    artist = None

    for row_index, mode in enumerate(MODE_ORDER):
        pressure, side = read_internal_field(time_directory / f"pMode_{mode}")
        fields = [pressure]
        for model in args.models:
            values, model_side = read_internal_field(
                time_directory
                / f"pIllustrativeFiltered_{model}_{mode}"
            )
            if model_side != side:
                raise RuntimeError(f"Inconsistent field size for {model}, {mode}")
            fields.append(values)

        for column_index, (name, values) in enumerate(zip(columns, fields)):
            ax = axes[row_index, column_index]
            image = np.asarray(values).reshape((side, side))
            artist = ax.imshow(
                image,
                origin="lower",
                interpolation="nearest",
                cmap="RdBu_r",
                vmin=-1,
                vmax=1,
                extent=(0, 1, 0, 1),
            )
            ax.set_xticks([])
            ax.set_yticks([])
            ax.set_aspect("equal")
            if row_index == 0:
                ax.set_title(
                    "Original $p$" if name == "pressure" else MODEL_LABELS[name]
                )
            if column_index == 0:
                ax.set_ylabel(MODE_LABELS[mode], fontsize=11)

    fig.subplots_adjust(left=0.07, right=0.89, bottom=0.1, top=0.9, wspace=0.06, hspace=0.12)
    colorbar_axis = fig.add_axes((0.91, 0.2, 0.015, 0.62))
    fig.colorbar(artist, cax=colorbar_axis, label="Pressure amplitude")
    fig.suptitle(
        r"Synthetic one-step spectral-damping illustration, "
        r"$p_{\rm illustrative}=p+\alpha S$"
    )
    fig.text(
        0.5,
        0.025,
        "Visualisation only: this is not an update performed by the mixed solver.",
        ha="center",
        fontsize=9,
    )
    save_figure(fig, Path(args.output), "visualisationModes")
    plt.close(fig)


if __name__ == "__main__":
    main()
