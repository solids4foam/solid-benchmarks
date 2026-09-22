#!/usr/bin/env python3
"""Create paper figures from the Fourier verification CSV output.

The script contains no independent stabilisation-symbol implementation.
Analytical curves and maps come from the utility's exported raw symbols and
are scaled by each exported checkerboard response. Production measurements
come directly from the raw and normalised result rows.
"""

import argparse
import csv
from pathlib import Path


MODEL_ORDER = (
    "laplacian",
    "gen0",
    "JST",
    "gen1",
    "gen2",
    "diffStencil",
    "RhieChow",
)
MODEL_LABELS = {
    "laplacian": "Laplacian",
    "gen0": "Generalised $m=1$",
    "JST": "JST",
    "gen1": "Generalised $m=2$",
    "gen2": "Generalised $m=3$",
    "diffStencil": "diffStencil",
    "RhieChow": "Rhie--Chow",
}
REPRESENTATIVES = ("laplacian", "JST", "gen2", "RhieChow")
REPRESENTATIVE_LABELS = {
    "laplacian": "Coupled $m=1$",
    "JST": "Coupled $m=2$ / JST",
    "gen2": "Coupled $m=3$",
    "RhieChow": "diffStencil / Rhie--Chow",
}
COLORS = {
    "laplacian": "#2868a3",
    "JST": "#df7c18",
    "gen2": "#3e916c",
    "RhieChow": "#965bb0",
}


def csv_rows(path):
    """Read a verification CSV while ignoring its metadata comments."""
    with path.open() as stream:
        return list(
            csv.DictReader(line for line in stream if not line.startswith("#"))
        )


def metadata(path):
    """Read key=value metadata comments from a verification CSV."""
    result = {}
    with path.open() as stream:
        for line in stream:
            if not line.startswith("#"):
                break
            key, separator, value = line[1:].strip().partition("=")
            if separator:
                result[key] = value
    return result


def resolution_key(path):
    tag = path.stem.split("_")[-1]
    return tuple(int(value) for value in tag.split("x"))


def require_one(selected, description):
    if len(selected) != 1:
        raise RuntimeError(
            f"Expected one {description}, found {len(selected)}"
        )
    return selected[0]


def save_figure(fig, output_directory, stem):
    output_directory.mkdir(parents=True, exist_ok=True)
    png = output_directory / f"{stem}.png"
    pdf = output_directory / f"{stem}.pdf"
    fig.savefig(png, dpi=300, bbox_inches="tight")
    fig.savefig(pdf, bbox_inches="tight")
    print(f"Wrote {png} and {pdf}")


def plot_reference_response(plt, np, result_rows, resolution, output):
    """Compare raw and normalised checkerboard response at one mesh size."""
    reference_rows = [row for row in result_rows if row["referenceMode"] == "1"]
    x = np.arange(len(MODEL_ORDER))
    width = 0.36
    fig, ax = plt.subplots(figsize=(11.2, 5.2), constrained_layout=True)

    for campaign, offset, color, label in (
        ("0", -width / 2, "#9aa0a6", "Raw"),
        ("1", width / 2, "#2868a3", "Normalised"),
    ):
        numerical = []
        analytical = []
        for model in MODEL_ORDER:
            row = require_one(
                [
                    item
                    for item in reference_rows
                    if item["normalise"] == campaign
                    and item["model"] == model
                ],
                f"checkerboard row for {model}, normalise={campaign}",
            )
            scale = float(row["hx"]) ** 2 / float(row["scaleFactor"])
            numerical.append(abs(float(row["lambda_num"])) * scale)
            analytical.append(abs(float(row["lambda_exact"])) * scale)

        positions = x + offset
        ax.bar(positions, numerical, width, color=color, label=label, zorder=2)
        ax.plot(
            positions,
            analytical,
            linestyle="none",
            marker="_",
            markersize=14,
            markeredgewidth=1.4,
            color="black",
            label="Analytical" if campaign == "1" else None,
            zorder=3,
        )

    ax.axhline(1, color="black", linewidth=0.8, linestyle=":")
    ax.set_yscale("log")
    ax.set_xticks(x, [MODEL_LABELS[model] for model in MODEL_ORDER], rotation=20)
    ax.set_ylabel(r"Reference response $-\lambda h^2/(s\,rAU_f)$")
    ax.set_title(
        rf"Full-checkerboard response at $r_\star=2$, "
        rf"${resolution[0]}\times{resolution[1]}$ mesh"
    )
    ax.grid(axis="y", alpha=0.2, which="both")
    ax.legend(ncols=3)
    ax.text(
        0.01,
        0.02,
        "The raw legacy m=1 response retains its historical mesh-size scaling.",
        transform=ax.transAxes,
        fontsize=9,
    )
    save_figure(fig, output, "referenceResponse")
    plt.close(fig)


def raw_reference_responses(map_rows, np):
    """Return the exported raw response at (pi, pi) for each model."""
    response = {}
    for model in REPRESENTATIVES:
        row = require_one(
            [
                item
                for item in map_rows
                if item["model"] == model
                and np.isclose(float(item["thetaX_over_pi"]), 1)
                and np.isclose(float(item["thetaY_over_pi"]), 1)
            ],
            f"raw checkerboard map entry for {model}",
        )
        response[model] = abs(float(row["lambda_exact"]))
        if response[model] == 0:
            raise RuntimeError(f"Zero checkerboard response for {model}")
    return response


def on_cut(row, cut, np):
    theta_x = float(row["thetaX_over_pi"])
    theta_y = float(row["thetaY_over_pi"])
    return (
        np.isclose(theta_y, 0),
        np.isclose(theta_x, theta_y),
        np.isclose(theta_x, 1),
    )[cut]


def cut_coordinate(row, cut):
    return float(row["thetaY_over_pi"] if cut == 2 else row["thetaX_over_pi"])


def plot_normalised_cuts(
    plt,
    np,
    symbol_rows,
    map_rows,
    measurements,
    output,
):
    """Plot normalised analytical cuts and production measurements."""
    reference = raw_reference_responses(map_rows, np)
    titles = (
        r"Axial: $\boldsymbol{\theta}=(\theta,0)$",
        r"Diagonal: $\boldsymbol{\theta}=(\theta,\theta)$",
        r"Off-axis: $\boldsymbol{\theta}=(\pi,\theta)$",
    )
    markers = ("o", "s", "^")
    fig, axes = plt.subplots(
        1,
        3,
        figsize=(14.2, 4.6),
        sharey=True,
        constrained_layout=True,
    )

    for cut, ax in enumerate(axes):
        for model in REPRESENTATIVES:
            curve = [
                row
                for row in symbol_rows
                if row["model"] == model and int(row["cut"]) == cut
            ]
            ax.plot(
                [float(row["theta_over_pi"]) for row in curve],
                [abs(float(row["lambda_exact"])) / reference[model] for row in curve],
                color=COLORS[model],
                linewidth=2,
                label=REPRESENTATIVE_LABELS[model],
            )

            for resolution_index, (_, rows) in enumerate(measurements):
                selected = [
                    row
                    for row in rows
                    if row["normalise"] == "1"
                    and row["model"] == model
                    and on_cut(row, cut, np)
                ]
                ax.plot(
                    [cut_coordinate(row, cut) for row in selected],
                    [
                        abs(float(row["lambda_num"]))
                        / abs(float(row["lambda_ref"]))
                        for row in selected
                    ],
                    linestyle="none",
                    marker=markers[resolution_index],
                    markersize=7,
                    markerfacecolor="none",
                    markeredgecolor=COLORS[model],
                    zorder=3,
                )

        ax.set_title(titles[cut])
        ax.set_xlabel(r"$\theta/\pi$")
        ax.set_xlim(0, 1)
        ax.set_ylim(-0.02, 1.05)
        ax.grid(alpha=0.2)

    axes[0].set_ylabel(r"Normalised damping response $|\lambda|/|\lambda_{\rm ref}|$")
    axes[0].legend(fontsize=8, loc="upper left")

    from matplotlib.lines import Line2D

    resolution_handles = [
        Line2D(
            [],
            [],
            color="black",
            linestyle="none",
            marker=markers[index],
            markerfacecolor="none",
            label=tag,
        )
        for index, (tag, _) in enumerate(measurements)
    ]
    axes[2].legend(
        handles=resolution_handles,
        title="Production measurements",
        fontsize=8,
        loc="lower right",
    )
    fig.suptitle(
        r"Normalised operator spectra, $r_\star=2$: "
        "curves are exported analytical symbols"
    )
    save_figure(fig, output, "normalisedSpectralCuts")
    plt.close(fig)


def plot_normalised_maps(plt, np, map_rows, output):
    """Plot normalised two-dimensional exported analytical symbol maps."""
    reference = raw_reference_responses(map_rows, np)
    tested_modes = (
        (1, 0),
        (0.5, 0),
        (0.5, 0.5),
        (1, 0.5),
        (1, 1),
    )
    fig, axes = plt.subplots(
        1,
        4,
        figsize=(15.2, 3.9),
        sharex=True,
        sharey=True,
        constrained_layout=True,
    )
    artist = None
    for model, ax in zip(REPRESENTATIVES, axes):
        selected = [row for row in map_rows if row["model"] == model]
        theta_x = sorted({float(row["thetaX_over_pi"]) for row in selected})
        theta_y = sorted({float(row["thetaY_over_pi"]) for row in selected})
        x_index = {value: index for index, value in enumerate(theta_x)}
        y_index = {value: index for index, value in enumerate(theta_y)}
        response = np.full((len(theta_y), len(theta_x)), np.nan)
        for row in selected:
            response[
                y_index[float(row["thetaY_over_pi"])],
                x_index[float(row["thetaX_over_pi"])],
            ] = abs(float(row["lambda_exact"])) / reference[model]

        artist = ax.pcolormesh(
            theta_x,
            theta_y,
            response,
            shading="auto",
            cmap="viridis",
            vmin=0,
            vmax=1,
        )
        ax.scatter(
            [mode[0] for mode in tested_modes],
            [mode[1] for mode in tested_modes],
            marker="x",
            color="white",
            linewidth=1.2,
            s=28,
            label="Tested modes",
        )
        ax.set_title(REPRESENTATIVE_LABELS[model])
        ax.set_xlabel(r"$\theta_x/\pi$")
        ax.set_aspect("equal")

    axes[0].set_ylabel(r"$\theta_y/\pi$")
    axes[-1].legend(loc="lower left", fontsize=8)
    fig.colorbar(
        artist,
        ax=axes,
        label=r"Normalised damping response $|\lambda|/|\lambda_{\rm ref}|$",
        shrink=0.88,
    )
    fig.suptitle(r"Normalised spectral maps, $r_\star=2$")
    save_figure(fig, output, "normalisedSpectralMaps")
    plt.close(fig)


def plot_verification_errors(plt, np, measurements, tolerance, output):
    """Plot worst operator errors for every mesh and campaign."""
    metrics = (
        ("relativeEigenvalueError", "Worst relative eigenvalue error"),
        ("eigenmodeErrRef", "Worst reference-scaled eigenmode error"),
    )
    campaigns = (("0", "Raw"), ("1", "Normalised"))
    markers = ("o", "s", "^")
    floor = 1e-17
    x = np.arange(len(MODEL_ORDER))
    fig, axes = plt.subplots(
        2,
        2,
        figsize=(13.2, 8.2),
        sharex=True,
        sharey=True,
        constrained_layout=True,
    )

    for column, (campaign, campaign_label) in enumerate(campaigns):
        for row_index, (metric, metric_label) in enumerate(metrics):
            ax = axes[row_index, column]
            for resolution_index, (tag, rows) in enumerate(measurements):
                maxima = []
                for model in MODEL_ORDER:
                    values = [
                        float(item[metric])
                        for item in rows
                        if item["normalise"] == campaign
                        and item["model"] == model
                        and item[metric]
                    ]
                    if not values:
                        raise RuntimeError(
                            f"No {metric} values for {model}, {tag}, "
                            f"normalise={campaign}"
                        )
                    maxima.append(max(max(values), floor))
                ax.plot(
                    x,
                    maxima,
                    linestyle="none",
                    marker=markers[resolution_index],
                    markersize=7,
                    markerfacecolor="none",
                    label=tag,
                )

            ax.axhline(tolerance, color="#b22222", linestyle="--", linewidth=1)
            ax.set_yscale("log")
            ax.set_ylim(floor / 2, max(tolerance * 100, 1e-8))
            ax.grid(axis="y", alpha=0.2, which="both")
            ax.set_title(f"{campaign_label}: {metric_label}")
            if column == 0:
                ax.set_ylabel("Error")
            if row_index == 1:
                ax.set_xticks(
                    x,
                    [MODEL_LABELS[model] for model in MODEL_ORDER],
                    rotation=20,
                )

    axes[0, 0].legend(title="Mesh")
    axes[0, 1].text(
        0.98,
        tolerance,
        "verification tolerance",
        transform=axes[0, 1].get_yaxis_transform(),
        ha="right",
        va="bottom",
        fontsize=8,
        color="#b22222",
    )
    fig.suptitle(
        "Production Fourier verification errors "
        "(exact zeros are displayed at $10^{-17}$)"
    )
    save_figure(fig, output, "verificationErrors")
    plt.close(fig)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "directory",
        nargs="?",
        default="postProcessing/stabilisationFourierCheck",
        help="directory containing verification CSV files",
    )
    parser.add_argument(
        "--output",
        default="postProcessing/paperFigures",
        help="output directory for PNG and PDF figures",
    )
    args = parser.parse_args()
    directory = Path(args.directory)
    output = Path(args.output)

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

    result_files = sorted(directory.glob("results_*.csv"), key=resolution_key)
    if not result_files:
        parser.error(f"No results CSVs in {directory}")

    measurements = []
    for path in result_files:
        rows = csv_rows(path)
        if not rows:
            parser.error(f"No result rows in {path}")
        measurements.append((path.stem[len("results_"):], rows))

    finest_path = result_files[-1]
    finest_resolution = resolution_key(finest_path)
    finest_rows = measurements[-1][1]
    symbol_path = directory / f"symbols_{measurements[-1][0]}.csv"
    map_path = directory / f"symbolMaps_{measurements[-1][0]}.csv"
    if not symbol_path.is_file() or not map_path.is_file():
        parser.error(f"Missing exported symbols or maps for {measurements[-1][0]}")
    symbol_rows = csv_rows(symbol_path)
    map_rows = csv_rows(map_path)
    tolerance = float(metadata(finest_path).get("tolerance", "1e-9"))

    plot_reference_response(
        plt,
        np,
        finest_rows,
        finest_resolution,
        output,
    )
    plot_normalised_cuts(
        plt,
        np,
        symbol_rows,
        map_rows,
        measurements,
        output,
    )
    plot_normalised_maps(plt, np, map_rows, output)
    plot_verification_errors(plt, np, measurements, tolerance, output)


if __name__ == "__main__":
    main()
