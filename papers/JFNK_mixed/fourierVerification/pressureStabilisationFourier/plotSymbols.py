#!/usr/bin/env python3
"""Plot exported analytical symbols and measured eigenvalues; no symbol formulas."""
import argparse
import csv
from pathlib import Path


def rows(path):
    with path.open() as stream:
        return list(csv.DictReader(line for line in stream if not line.startswith('#')))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('directory', nargs='?', default='postProcessing/stabilisationFourierCheck')
    args = parser.parse_args()
    directory = Path(args.directory)
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    import numpy as np

    files = sorted(directory.glob('results_*.csv'), key=lambda p: int(p.stem.split('_')[-1].split('x')[0]))
    if not files:
        parser.error('No results CSVs')
    measurements = []
    for path in files:
        measured = [row for row in rows(path) if row.get('normalise', '0') == '0']
        if not measured:
            parser.error(f'No raw measurement rows in {path}')
        measurements.append((path.stem[len('results_'):], measured))
    resolution, last = measurements[-1]
    curves = rows(directory / f'symbols_{resolution}.csv')
    maps = rows(directory / f'symbolMaps_{resolution}.csv')
    # Representatives of the four distinct families; aliases are checked by the utility.
    models = ('laplacian', 'JST', 'gen2', 'RhieChow')
    colors = dict(zip(models, ('#2868a3', '#df7c18', '#3e916c', '#965bb0')))
    titles = (r'$\theta_y=0$', r'$\theta_y=\theta_x$', r'$\theta_x=\pi$')

    def amplitude(row, field, model):
        value = abs(float(row[field])) / float(row['scaleFactor'])
        return value if model == 'laplacian' else value * float(row['hx']) ** 2

    fig, axes = plt.subplots(1, 3, figsize=(13.5, 4.6), sharey=True, constrained_layout=True)
    for cut, ax in enumerate(axes):
        for model in models:
            selected = [row for row in curves if row['model'] == model and int(row['cut']) == cut]
            ax.plot([float(row['theta_over_pi']) for row in selected],
                    [amplitude(row, 'lambda_exact', model) if float(row['lambda_exact']) != 0 else np.nan for row in selected],
                    color=colors[model], label=model)
            for index, (tag, measured) in enumerate(measurements):
                selected = []
                for row in measured:
                    x, y = float(row['thetaX_over_pi']), float(row['thetaY_over_pi'])
                    on_cut = (y == 0, x == y, x == 1)[cut]
                    if row['model'] == model and on_cut and float(row['lambda_exact']) != 0:
                        selected.append(row)
                ax.plot([float(row['thetaY_over_pi'] if cut == 2 else row['thetaX_over_pi']) for row in selected],
                        [amplitude(row, 'lambda_num', model) for row in selected],
                        linestyle='none', marker=('o', 's', '^')[index % 3],
                        markersize=8 - index, markerfacecolor='none', markeredgecolor=colors[model])
        ax.set_title(titles[cut])
        ax.set_xlabel(r'$\theta/\pi$')
        ax.set_yscale('log')
        ax.set_xlim(0, 1)
        ax.grid(alpha=0.2)
    axes[0].set_ylabel(r'$|\lambda|h^2/s$ (Laplacian: $|\lambda|/s$)')
    axes[0].legend(loc='lower right', fontsize=9)
    from matplotlib.lines import Line2D
    handles = [Line2D([], [], color='black', linestyle='none', marker=('o', 's', '^')[i % 3],
                      markerfacecolor='none', label=tag) for i, (tag, _) in enumerate(measurements)]
    axes[2].legend(handles=handles, title='Runtime measurements', fontsize=9)
    measured_amplitudes = [amplitude(row, 'lambda_num', row['model']) for _, measured in measurements
                           for row in measured if row['model'] in models and float(row['lambda_exact']) != 0]
    curve_amplitudes = [amplitude(row, 'lambda_exact', row['model']) for row in curves if row['model'] in models]
    axes[0].set_ylim(min(measured_amplitudes) / 5, max(curve_amplitudes) * 2)
    fig.suptitle('Raw production operator verification: curves = analytical; markers = Rayleigh quotient')
    fig.savefig(directory / 'verification.png', dpi=180)
    plt.close(fig)

    fig, axes = plt.subplots(1, 3, figsize=(13.5, 4), constrained_layout=True)
    for model, ax in zip(('JST', 'gen2', 'RhieChow'), axes):
        selected = [row for row in maps if row['model'] == model]
        x = sorted({float(row['thetaX_over_pi']) for row in selected})
        y = sorted({float(row['thetaY_over_pi']) for row in selected})
        xi, yi = {v: i for i, v in enumerate(x)}, {v: i for i, v in enumerate(y)}
        z = np.full((len(y), len(x)), np.nan)
        for row in selected:
            z[yi[float(row['thetaY_over_pi'])], xi[float(row['thetaX_over_pi'])]] = amplitude(row, 'lambda_exact', model)
        artist = ax.pcolormesh(x, y, z, shading='auto', cmap='viridis')
        ax.set_title(model)
        ax.set_xlabel(r'$\theta_x/\pi$')
        ax.set_ylabel(r'$\theta_y/\pi$')
        ax.set_aspect('equal')
        fig.colorbar(artist, ax=ax, label=r'$|\lambda|h^2/s$')
    fig.suptitle('Current Cartesian symbols: full-Laplacian powers and Rhie-Chow directional sum')
    fig.savefig(directory / 'operatorComparison.png', dpi=180)
    plt.close(fig)
    print(f'Wrote {directory / "verification.png"} and operatorComparison.png')


if __name__ == '__main__':
    main()
