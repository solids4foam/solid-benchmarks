#!/usr/bin/env python3
"""Regression checks for raw, normalised, equivalence and rejection results."""
import csv
import math
import sys
from pathlib import Path

MODELS = {"laplacian", "JST", "gen0", "gen1", "gen2", "diffStencil", "RhieChow"}

# Raw coefficients: units of s for lap/gen0 and s/h^2 for the other models.
# These literal values retain the original check independently of
# fourierSymbols.H.
RAW_GOLDEN = {
    (0.0, 0.0): (0, 0, 0, 0),
    (0.5, 0.0): (-2, -4, -8, -1),
    (1.0, 0.0): (-4, -16, -64, -4),
    (0.5, 0.5): (-4, -16, -64, -2),
    (1.0, 0.5): (-6, -36, -216, -5),
    (0.5, 1.0): (-6, -36, -216, -5),
    (1.0, 1.0): (-8, -64, -512, -8),
}
FAMILY = {
    "laplacian": 0,
    "gen0": 0,
    "JST": 1,
    "gen1": 1,
    "gen2": 2,
    "diffStencil": 3,
    "RhieChow": 3,
}
PAPER_ORDER = {
    "laplacian": "1",
    "gen0": "1",
    "JST": "2",
    "gen1": "2",
    "gen2": "3",
    "diffStencil": "",
    "RhieChow": "",
}
NEGATIVE_CONTROL = {
    (1.0, 0.0): (-0.5, -0.25, -0.125, -0.5),
    (0.5, 0.5): (-0.5, -0.25, -0.125, -0.25),
}


def read(path):
    with path.open() as stream:
        rows = list(csv.DictReader(line for line in stream if not line.startswith("#")))
    if not rows:
        raise ValueError(f"Empty CSV: {path}")
    if any(row["pass"] != "1" for row in rows):
        raise ValueError(f"Failed row: {path}")
    return rows


def close(value, expected, tolerance=1e-9):
    return math.isfinite(value) and abs(value - expected) <= tolerance * max(
        abs(expected), 1.0
    )


def normalised_coefficient(model, mode, r_star=2):
    q = [math.sin(math.pi * component / 2) ** 2 for component in mode]
    if FAMILY[model] == 3:
        return -sum(value**2 for value in q) / r_star
    order = (1, 2, 3)[FAMILY[model]]
    return -(sum(q) / r_star) ** order


def expected_relation(model, normalise):
    if FAMILY[model] == 3:
        return "splitM2Shape"
    if not normalise and model in {"laplacian", "gen0"}:
        return "legacyM1"
    return "coupledRepeatedLaplacian"


def check(directory):
    measured = {}
    worst = (-1.0, None)
    operator_count = 0
    pair_count = 0
    gamma_count = 0

    for n in (16, 32, 64):
        tag = f"{n}x{n}x1"
        rows = read(directory / f"results_{tag}.csv")
        cross = read(directory / f"crossChecks_{tag}.csv")
        gamma = read(directory / f"gammaChecks_{tag}.csv")
        if len(rows) != 112 or len(cross) != 48 or len(gamma) != 112:
            raise ValueError(f"Missing or extra checks at N={n}")

        keys = set()
        for row in rows:
            normalise = row["normalise"] == "1"
            model = row["model"]
            mode = (
                float(row["thetaX_over_pi"]),
                float(row["thetaY_over_pi"]),
            )
            key = (normalise, model, mode)
            if model not in MODELS or key in keys:
                raise ValueError(f"Unknown/duplicate result: {key}")
            keys.add(key)
            if (int(row["Nx"]), int(row["Ny"]), int(row["Nz"])) != (n, n, 1):
                raise ValueError("Wrong resolution")
            if row["referenceNyquistDirections"] != ("2" if normalise else ""):
                raise ValueError(f"Wrong rStar metadata: {key}")
            if row["paperOrder"] != PAPER_ORDER[model]:
                raise ValueError(f"Wrong paper-order metadata: {key}")
            if row["spectralRelation"] != expected_relation(model, normalise):
                raise ValueError(f"Wrong spectral relation: {key}")

            scale, h = float(row["scaleFactor"]), float(row["hx"])
            if not close(scale, 0.37) or not close(h, 1.0 / n):
                raise ValueError("Wrong golden-test scale or spacing")
            num, exact = float(row["lambda_num"]), float(row["lambda_exact"])
            for field in (
                "rayleighErr",
                "eigenmodeErrRef",
                "relativeEigenvalueError",
                "eigenmodeErr",
            ):
                if row[field]:
                    error = float(row[field])
                    if not math.isfinite(error) or error > 1e-9:
                        raise ValueError(f"Invalid {field}: {key}")
                    if field == "relativeEigenvalueError" and error > worst[0]:
                        worst = (error, (n, key))

            if normalise:
                expected = normalised_coefficient(model, mode) * scale * n * n
                if not close(num, expected) or not close(exact, expected):
                    raise ValueError(f"Normalised value mismatch: {key}, N={n}")
                if mode in NEGATIVE_CONTROL:
                    literal = NEGATIVE_CONTROL[mode][FAMILY[model]] * scale * n * n
                    if not close(num, literal) or not close(exact, literal):
                        raise ValueError(f"Negative-control mismatch: {key}, N={n}")
                reference = mode == (1.0, 1.0)
                if (row["referenceMode"] == "1") != reference:
                    raise ValueError(f"Wrong reference-mode flag: {key}")
                if reference and (
                    not close(num, -scale * n * n)
                    or not close(exact, -scale * n * n)
                ):
                    raise ValueError(f"Reference response mismatch: {key}, N={n}")
            elif mode in RAW_GOLDEN:
                family = FAMILY[model]
                expected = RAW_GOLDEN[mode][family] * scale
                if family != 0:
                    expected *= n * n
                if not close(num, expected) or not close(exact, expected):
                    raise ValueError(f"Raw golden value mismatch: {key}, N={n}")
            measured[n, key] = num

        modes = (*RAW_GOLDEN, (0.125, 0.0))
        expected_keys = {
            (normalise, model, mode)
            for normalise in (False, True)
            for model in MODELS
            for mode in modes
        }
        if keys != expected_keys:
            raise ValueError(f"Incomplete model/mode coverage: N={n}")

        pair_keys = {
            (
                row["normalise"] == "1",
                row["modelA"],
                row["modelB"],
                int(row["modeIndex"]),
            )
            for row in cross
        }
        expected_pairs = {
            (normalise, a, b, mode)
            for normalise in (False, True)
            for a, b in (
                ("laplacian", "gen0"),
                ("JST", "gen1"),
                ("diffStencil", "RhieChow"),
            )
            for mode in range(8)
        }
        if pair_keys != expected_pairs:
            raise ValueError("Incomplete pair-check coverage")
        for row in cross:
            if not close(float(row["maxAbsDiffOverRef"]), 0, 1e-12):
                raise ValueError("Pair mismatch")
            if (
                (row["modelA"], row["modelB"])
                in {
                    ("laplacian", "gen0"),
                    ("diffStencil", "RhieChow"),
                }
                and row["bitwiseEqual"] != "1"
            ):
                raise ValueError("Expected bitwise pair equality")

        gamma_keys = {
            (row["normalise"] == "1", row["model"], int(row["modeIndex"]))
            for row in gamma
        }
        expected_gamma = {
            (normalise, model, mode)
            for normalise in (False, True)
            for model in MODELS
            for mode in range(8)
        }
        if gamma_keys != expected_gamma:
            raise ValueError("Incomplete gamma-check coverage")
        for row in gamma:
            if (
                not close(float(row["maxAbsDiffOverRef"]), 0, 1e-14)
                or row["nullGammaBitwiseEqual"] != "1"
                or not close(float(row["gamma"]), 0.37)
            ):
                raise ValueError("Gamma mismatch")
        operator_count += len(rows)
        pair_count += len(cross)
        gamma_count += len(gamma)

    for key in keys:
        if key[2] == (0.0, 0.0):
            continue
        for coarse, fine in ((16, 32), (32, 64)):
            ratio = measured[fine, key] / measured[coarse, key]
            expected = 4 if key[0] or FAMILY[key[1]] != 0 else 1
            if not close(ratio, expected):
                raise ValueError(
                    f"h-scaling mismatch: {key}, {coarse}->{fine}: {ratio}"
                )

    rejections = read(directory / "rejectionChecks.csv")
    if len(rejections) != 9:
        raise ValueError("Missing or extra rejection checks")
    if any(int(row["exitCode"]) == 0 for row in rejections):
        raise ValueError("A rejection check exited successfully")

    representative_n = 32
    print("Normalised representative results at N=32 (lambda_num / (-s/h^2)):")
    for mode_name, mode in (
        ("reference (pi,pi)", (1.0, 1.0)),
        ("negative (pi,0)", (1.0, 0.0)),
        ("negative (pi/2,pi/2)", (0.5, 0.5)),
    ):
        values = []
        for model in ("laplacian", "JST", "gen2", "diffStencil", "RhieChow"):
            value = measured[representative_n, (True, model, mode)]
            values.append(f"{model}={value / (-0.37 * representative_n**2):.15g}")
        print(f"  {mode_name}: " + ", ".join(values))

    total = operator_count + pair_count + gamma_count + len(rejections)
    print(
        "PASS: "
        f"{operator_count // 2} raw + {operator_count // 2} normalised "
        f"operator/mode results; {pair_count} pair checks; "
        f"{gamma_count} gamma checks; {len(rejections)} rejection checks; "
        f"{total} total, 0 failed"
    )
    print(
        "Worst relative eigenvalue error: "
        f"{worst[0]:.17g} at N={worst[1][0]}, {worst[1][1]}"
    )


if __name__ == "__main__":
    try:
        check(
            Path(
                sys.argv[1]
                if len(sys.argv) > 1
                else "postProcessing/stabilisationFourierCheck"
            )
        )
    except (OSError, ValueError, KeyError, ZeroDivisionError) as error:
        print(f"FAIL: {error}", file=sys.stderr)
        sys.exit(1)
