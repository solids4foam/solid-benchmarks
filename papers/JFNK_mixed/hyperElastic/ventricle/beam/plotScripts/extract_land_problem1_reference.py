#!/usr/bin/env python3
"""Land et al. (2015) problem 1 reference statistics for the beam figure.

The plotted reference lines are the minimum, median and maximum of ALL
second-column values (deformed tip z-coordinate, mm) in the supplied point
set referenceData/land1Data.csv. No point is filtered or removed. The file has
no participant identifiers, so its points are not attributed to groups or
mesh levels here. For an even count the median is the mean of the two
central values.

Optionally, --problem-dir reads the per-solution VTK submissions of the
Land 2015 benchmark repository ("problem 1": one folder per code, one
sub-folder per solution named after its degrees of freedom) and writes the
deformed z of material point (10, 0.5, 1) mm for every solution to a
cross-check table. Those values do not enter the plotted statistics.

Outputs (in --output-dir): land_problem1_reference_stats.gp, defining landN,
landMin, landMedian and landMax for plotScripts/dz.gnuplot, and, with
--problem-dir, land_problem1_submissions.tsv.

Usage:
    extract_land_problem1_reference.py [--points-csv FILE] [--output-dir DIR]
        [--problem-dir ".../land2015-mechbench/problem 1"]
"""

from __future__ import annotations

import argparse
import hashlib
import math
import re
import statistics
from pathlib import Path

TARGET_MM = (10.0, 0.5, 1.0)
BEAM_EXTENT_MM = (10.0, 1.0, 1.0)
NODE_TOLERANCE_MM = 1.0e-6


def read_points(path: Path) -> list[tuple[float, float, float]]:
    with path.open() as handle:
        for line in handle:
            if line.startswith("POINTS"):
                count = int(line.split()[1])
                values: list[str] = []
                while len(values) < 3 * count:
                    values += handle.readline().split()
                coords = [float(value) for value in values[: 3 * count]]
                return [tuple(coords[3 * i : 3 * i + 3]) for i in range(count)]
    raise ValueError(f"no POINTS section in {path}")


def cells_digest(path: Path) -> str:
    digest = hashlib.sha256()
    in_cells = False
    with path.open() as handle:
        for line in handle:
            if line.startswith("CELLS"):
                in_cells = True
            elif line.startswith(("CELL_TYPES", "POINT_DATA", "CELL_DATA")):
                break
            if in_cells:
                digest.update(" ".join(line.split()).encode() + b"\n")
    return digest.hexdigest()


def read_cells(path: Path) -> list[list[int]]:
    with path.open() as handle:
        for line in handle:
            if line.startswith("CELLS"):
                count = int(line.split()[1])
                cells: list[list[int]] = []
                while len(cells) < count:
                    fields = [int(value) for value in handle.readline().split()]
                    while fields:
                        size = fields[0]
                        cells.append(fields[1 : 1 + size])
                        fields = fields[1 + size :]
                return cells
    raise ValueError(f"no CELLS section in {path}")


def point_correspondence(undeformed: Path, deformed: Path, count: int) -> tuple[list[int], str]:
    """Map undeformed point indices to deformed point indices."""
    if cells_digest(undeformed) == cells_digest(deformed):
        return list(range(count)), "identical point numbering"
    # Some files renumber points between the two meshes; match them through
    # the cell list, which has the same order and vertex ordering in both.
    mapping: dict[int, int] = {}
    for cell_u, cell_d in zip(read_cells(undeformed), read_cells(deformed)):
        for a, b in zip(cell_u, cell_d):
            if mapping.setdefault(a, b) != b:
                raise ValueError(f"inconsistent cell-wise point mapping in {deformed.parent}")
    if len(mapping) != count or len(set(mapping.values())) != count:
        raise ValueError(f"cell-wise point mapping is not one-to-one in {deformed.parent}")
    return [mapping[i] for i in range(count)], "points renumbered; matched through cell connectivity"


def length_scale_to_mm(points: list[tuple[float, float, float]]) -> tuple[float, str]:
    extent = tuple(max(p[i] for p in points) - min(p[i] for p in points) for i in range(3))
    for scale, unit in ((1.0, "mm"), (1.0e3, "m")):
        if all(math.isclose(e * scale, ref, rel_tol=1e-6) for e, ref in zip(extent, BEAM_EXTENT_MM)):
            return scale, unit
    raise ValueError(f"undeformed extent {extent} does not match the 10 x 1 x 1 mm beam")


def tip_z(undeformed: Path, deformed: Path) -> dict[str, object]:
    pu = read_points(undeformed)
    pd = read_points(deformed)
    if len(pu) != len(pd):
        raise ValueError(f"point counts differ in {deformed.parent}")
    scale, unit = length_scale_to_mm(pu)
    pu = [tuple(scale * c for c in p) for p in pu]
    pd = [tuple(scale * c for c in p) for p in pd]
    index, numbering = point_correspondence(undeformed, deformed, len(pu))

    fixed = [k for k, p in enumerate(pu) if abs(p[0]) < NODE_TOLERANCE_MM]
    fixed_motion = max(math.dist(pu[k], pd[index[k]]) for k in fixed)
    if fixed_motion > 1.0e-6:
        raise ValueError(f"fixed face moves by {fixed_motion} mm in {deformed.parent}")

    exact = [k for k, p in enumerate(pu) if math.dist(p, TARGET_MM) < NODE_TOLERANCE_MM]
    if exact:
        z = pd[index[exact[0]]][2]
        location = "node at (10, 0.5, 1)"
    else:
        # Interpolate linearly in Y along the tip edge X = 10, Z = 1 between
        # the two nodes that bracket Y = 0.5.
        edge = sorted(
            (p[1], pd[index[k]][2])
            for k, p in enumerate(pu)
            if abs(p[0] - TARGET_MM[0]) < NODE_TOLERANCE_MM and abs(p[2] - TARGET_MM[2]) < NODE_TOLERANCE_MM
        )
        below = max((e for e in edge if e[0] < TARGET_MM[1]), key=lambda e: e[0])
        above = min((e for e in edge if e[0] > TARGET_MM[1]), key=lambda e: e[0])
        weight = (TARGET_MM[1] - below[0]) / (above[0] - below[0])
        z = below[1] + weight * (above[1] - below[1])
        location = (
            f"no node at (10, 0.5, 1); linear in Y between tip-edge nodes "
            f"Y = {below[0]:.7g} and {above[0]:.7g} mm"
        )
    return {
        "unit": unit,
        "raw_z": z / scale,
        "z_mm": z,
        "conversion": "deformed position read directly" + ("" if scale == 1.0 else "; m -> mm (x 1000)"),
        "location": location,
        "numbering": numbering,
    }


def refinement_key(name: str) -> tuple[int, ...]:
    """Order solutions within one submission: the DOF count, or cell counts."""
    if name.isdigit():
        return (int(name),)
    # glasgowHeart-IBFE: "40x4x4(structure)_120x42x90(fluid)"
    return tuple(math.prod(int(n) for n in grid.split("x")) for grid in re.findall(r"\d+x\d+x\d+", name))


def read_point_set(path: Path) -> list[float]:
    values: list[float] = []
    with path.open() as handle:
        for line in handle:
            fields = [field.strip() for field in line.split(",")]
            if len(fields) < 2 or not fields[1]:
                continue
            value = float(fields[1])
            if not math.isfinite(value):
                raise ValueError(f"non-finite value in {path}: {line.strip()}")
            values.append(value)
    if not values:
        raise ValueError(f"no values in {path}")
    return values


def write_submission_table(problem_dir: Path, table: Path) -> None:
    columns = ["submission", "solution", "source", "unit", "raw_z", "conversion", "z_mm", "location", "numbering"]
    with table.open("w") as handle:
        handle.write("# Land et al. (2015) problem 1 VTK submissions: deformed z of material point (10, 0.5, 1) mm.\n")
        handle.write(f"# Source: {problem_dir}\n")
        handle.write("# solution = submission folder name (number of degrees of freedom, or grid sizes for glasgowHeart-IBFE).\n")
        handle.write("# Cross-check only: these values do not enter the plotted statistics.\n")
        handle.write("\t".join(columns) + "\n")
        for code_dir in sorted(p for p in problem_dir.iterdir() if p.is_dir()):
            solutions = sorted(
                (p for p in code_dir.iterdir() if (p / "deformed.vtk").is_file()),
                key=lambda p: refinement_key(p.name),
            )
            for solution in solutions:
                row = {
                    "submission": code_dir.name,
                    "solution": solution.name,
                    "source": f"{code_dir.name}/{solution.name}/deformed.vtk",
                    **tip_z(solution / "undeformed.vtk", solution / "deformed.vtk"),
                }
                row["raw_z"] = f"{row['raw_z']:.9g}"
                row["z_mm"] = f"{row['z_mm']:.6f}"
                handle.write("\t".join(str(row[c]) for c in columns) + "\n")


def main() -> None:
    script_path = Path(__file__).resolve()
    data_dir = script_path.parents[1] / "referenceData"
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--points-csv", type=Path, default=data_dir / "land1Data.csv")
    parser.add_argument("--output-dir", type=Path, default=data_dir)
    parser.add_argument("--problem-dir", type=Path)
    args = parser.parse_args()
    args.output_dir.mkdir(parents=True, exist_ok=True)

    values = sorted(read_point_set(args.points_csv))
    z_min, z_median, z_max = values[0], statistics.median(values), values[-1]

    stats = args.output_dir / "land_problem1_reference_stats.gp"
    stats.write_text(
        "# Generated by plotScripts/extract_land_problem1_reference.py: minimum, median and\n"
        f"# maximum of all {len(values)} second-column values of {args.points_csv.name}\n"
        "# (deformed tip z-coordinate, mm). No points were filtered.\n"
        f"landN = {len(values)}\n"
        f"landMin = {z_min!r}\n"
        f"landMedian = {z_median!r}\n"
        f"landMax = {z_max!r}\n"
    )
    print(f"{len(values)} points: min {z_min!r}, median {z_median!r}, max {z_max!r} mm")
    print(f"Wrote {stats}")

    if args.problem_dir is not None:
        table = args.output_dir / "land_problem1_submissions.tsv"
        write_submission_table(args.problem_dir, table)
        print(f"Wrote {table}")


if __name__ == "__main__":
    main()
