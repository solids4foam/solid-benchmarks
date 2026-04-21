import os
import numpy as np
import pandas as pd

# ============================================================
# INPUTS
# ============================================================

# Set to True if you want pairwise orders
print_pairwise_orders = False

# Optional: restrict fit to a subset of rows, e.g. slice(-10, None) for last 10
# Use None to fit all rows
fit_subset = None

# Directory containing the txt files
script_dir = os.path.dirname(os.path.abspath(__file__))

# Domain size (area in 2D, volume in 3D)
domain_measure = 1

# List of cases
cases = [
    {
        "input_file": "hex.struct.ho.N1.summary.txt",
        "mesh_type": "struct-hex2d",
    },
    {
        "input_file": "hex.struct.ho.N2.summary.txt",
        "mesh_type": "struct-hex2d",
    },
    {
        "input_file": "hex.struct.ho.N3.summary.txt",
        "mesh_type": "struct-hex2d",
    },
    {
        "input_file": "tet.struct.ho.N1.summary.txt",
        "mesh_type": "struct-tri2d",
    },
    {
        "input_file": "tet.struct.ho.N2.summary.txt",
        "mesh_type": "struct-tri2d",
    },
    {
        "input_file": "tet.struct.ho.N3.summary.txt",
        "mesh_type": "struct-tri2d",
    },
    {
        "input_file": "tet.unstruct_v2.ho.N1.summary.txt",
        "mesh_type": "unstruct-tri2d",
    },
    {
        "input_file": "tet.unstruct_v2.ho.N2.summary.txt",
        "mesh_type": "unstruct-tri2d",
    },
    {
        "input_file": "tet.unstruct_v2.ho.N3.summary.txt",
        "mesh_type": "unstruct-tri2d",
    },
    {
        "input_file": "poly.struct.ho.N1.summary.txt",
        "mesh_type": "struct-poly2d",
    },
    {
        "input_file": "poly.struct.ho.N2.summary.txt",
        "mesh_type": "struct-poly2d",
    },
    {
        "input_file": "poly.struct.ho.N3.summary.txt",
        "mesh_type": "struct-poly2d",
    },
]

error_columns = ["D_L2", "D_Linf", "S_L2", "S_Linf"]

# ============================================================
# FUNCTIONS
# ============================================================

def compute_characteristic_h(cells_number, mesh_type):
    """
    Compute characteristic mesh size h from total area/volume and number of cells.

    Definitions used:

    2D:
      struct-hex2D   : h = sqrt(A / N)
      struct-tri2D   : h = sqrt(4 * (A / N) / sqrt(3))
      unstruct-tri2D : h = sqrt(4 * (A / N) / sqrt(3))
      struct-poly2D  : h = sqrt(4 * (A / N) / pi)

    3D:
      struct-hex     : h = (V / N)^(1/3)
      struct-poly    : h = (6 * (V / N) / pi)^(1/3)
      struct-tet     : h = (8.48528 * (V / N))^(1/3)
      unstruct-tet   : h = (8.48528 * (V / N))^(1/3)
    """
    mesh_type = mesh_type.lower()
    avg_measure = domain_measure / cells_number

    if mesh_type == "struct-hex2d":
        return avg_measure ** 0.5

    elif mesh_type in ["struct-tri2d", "unstruct-tri2d"]:
        return (4.0 * avg_measure / np.sqrt(3.0)) ** 0.5

    elif mesh_type == "struct-poly2d":
        return (4.0 * avg_measure / np.pi) ** 0.5

    elif mesh_type == "struct-hex":
        return avg_measure ** (1.0 / 3.0)

    elif mesh_type == "struct-poly":
        return (6.0 * avg_measure / np.pi) ** (1.0 / 3.0)

    elif mesh_type in ["struct-tet", "unstruct-tet"]:
        return (8.48528 * avg_measure) ** (1.0 / 3.0)

    else:
        raise ValueError(f"Unsupported mesh type: {mesh_type}")


def fit_loglog_slope(h, error):
    """
    Fit log(error) = p*log(h) + c

    Returns:
      p   -> observed order of convergence
      c   -> intercept
      r2  -> coefficient of determination
    """
    logh = np.log(h)
    loge = np.log(error)

    p, c = np.polyfit(logh, loge, 1)

    fitted = p * logh + c
    ss_res = np.sum((loge - fitted) ** 2)
    ss_tot = np.sum((loge - np.mean(loge)) ** 2)
    r2 = 1.0 - ss_res / ss_tot if ss_tot > 0.0 else np.nan

    return p, c, r2


def pairwise_orders(h, error):
    """
    Compute pairwise observed orders:
      p_i = log(e_i/e_{i-1}) / log(h_i/h_{i-1})
    """
    pvals = []
    for i in range(1, len(error)):
        if error[i] <= 0.0 or error[i - 1] <= 0.0:
            pvals.append(np.nan)
        else:
            pvals.append(np.log(error[i] / error[i - 1]) / np.log(h[i] / h[i - 1]))
    return np.array(pvals)


def read_summary_file(file_path):
    data = pd.read_csv(
        file_path,
        sep=r"\s+",
        comment="#",
        header=None,
        names=["Mesh", "Time", "Mem", "CellsNumber", "D_L2", "D_Linf", "S_L2", "S_Linf"],
        engine="python"
    )

    # Convert everything to numeric where possible
    for col in ["Mesh", "Time", "Mem", "CellsNumber", "D_L2", "D_Linf", "S_L2", "S_Linf"]:
        data[col] = pd.to_numeric(data[col], errors="coerce")

    # Remove rows with missing mandatory values
    data = data.dropna(subset=["Mesh", "CellsNumber", "D_L2", "D_Linf", "S_L2", "S_Linf"])

    return data


def process_case(case, fit_subset=None, print_pairwise_orders=False):
    input_file = case["input_file"]
    mesh_type = case["mesh_type"]

    file_path = os.path.join(script_dir, input_file)

    if not os.path.isfile(file_path):
        print(f"\nSkipping case: file not found -> {file_path}")
        return

    data = read_summary_file(file_path)

    data["h"] = compute_characteristic_h(
        data["CellsNumber"].to_numpy(dtype=float),
        mesh_type
    )

    fit_data = data if fit_subset is None else data.iloc[fit_subset].copy()

    print("\n\n\n\n" + "=" * 72)
    print(f"File       : {input_file}")
    print(f"Mesh type  : {mesh_type}")
    print(f"Measure    : {domain_measure}")
    print("=" * 72)

    print("\nObserved orders of convergence from log-log fit:")
    for col in error_columns:
        errors = fit_data[col].to_numpy(dtype=float)
        hvals = fit_data["h"].to_numpy(dtype=float)

        if np.any(errors <= 0.0):
            print(f"{col:8s}: skipped (contains non-positive values)")
            continue

        p, c, r2 = fit_loglog_slope(hvals, errors)
        print(f"{col:8s}: p = {p:10.6f},   R^2 = {r2:10.6f}")

    if print_pairwise_orders:
        print("\nPairwise orders:")
        for col in error_columns:
            errors = fit_data[col].to_numpy(dtype=float)
            hvals = fit_data["h"].to_numpy(dtype=float)

            pvals = pairwise_orders(hvals, errors)
            print(f"\n{col}:")
            for i, p in enumerate(pvals, start=1):
                m1 = fit_data["Mesh"].iloc[i - 1]
                m2 = fit_data["Mesh"].iloc[i]
                print(f"  between Mesh {m1} and {m2}: p = {p:10.6f}")


# ============================================================
# MAIN
# ============================================================

for case in cases:
    process_case(
        case,
        fit_subset=fit_subset,
        print_pairwise_orders=print_pairwise_orders
    )
