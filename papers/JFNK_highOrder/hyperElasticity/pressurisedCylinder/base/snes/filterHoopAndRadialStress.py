#!/usr/bin/env python3
import math
import argparse

def filter_points(input_file, output_file, tol):
    """
    Read data rows x y z ... and keep only those points close to the line
    starting at (4,4,0.5) with direction (1,1,0) -- i.e., x ≈ y and z ≈ 0.5.
    Then sort the kept points by radial coordinate r = sqrt(x^2 + y^2)
    before writing them out.
    tol = tolerance for distance to the line.
    """

    n_in = 0
    kept = []          # list of (r, line) for accepted points
    comment_lines = [] # keep comments/headers to write at top

    with open(input_file, "r") as fin:
        for line in fin:
            stripped = line.strip()

            if not stripped:
                # skip empty lines
                continue

            # Keep commented/header lines in memory
            if stripped.startswith("#"):
                comment_lines.append(line)
                continue

            parts = stripped.split()
            if len(parts) < 3:
                # not enough columns, ignore
                continue

            try:
                x = float(parts[0])
                y = float(parts[1])
                z = float(parts[2])
            except ValueError:
                # non-numeric data row, treat as commented-out
                comment_lines.append("# " + line)
                continue

            n_in += 1

            # Distance to the 45° line in xy-plane: x ≈ y
            # perpendicular distance = |x - y| / sqrt(2)
            d_xy = abs(x - y) / math.sqrt(2.0)

            # z should be close to 0.5
            dz = abs(z - 0.5)

            if d_xy <= tol and dz <= tol:
                # radial coordinate
                r = math.sqrt(x*x + y*y)
                kept.append((r, line))

    # Sort by radial coordinate
    kept.sort(key=lambda item: item[0])
    n_out = len(kept)

    # Write output: comments first, then sorted data
    with open(output_file, "w") as fout:
        for c in comment_lines:
            fout.write(c if c.endswith("\n") else c + "\n")
        for _, line in kept:
            fout.write(line if line.endswith("\n") else line + "\n")

    print(f"Read {n_in} numeric data points, wrote {n_out} filtered points to {output_file}")
    print(f"Tolerance used: {tol}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Filter points close to a 45° line from (4,4,0.5) and sort them by radius."
    )
    parser.add_argument("input", help="Input data file")
    parser.add_argument("output", help="Output filtered file")

    parser.add_argument(
        "--tol",
        type=float,
        default=0.3,
        help="Distance tolerance to the line (default: 0.3)",
    )

    args = parser.parse_args()
    filter_points(args.input, args.output, args.tol)
