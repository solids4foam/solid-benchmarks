#!/usr/bin/env python3
"""
Extract last-period statistics from HronTurekFsi3 probe and force time histories.

Outputs a single line of TSV scalars (12 numbers):
    UxMean UxAmp UxFreq UyMean UyAmp UyFreq FxMean FxAmp FxFreq FyMean FyAmp FyFreq

Missing/insufficient data -> NaN. The Turek-Hron benchmark reports
mean +/- amplitude [frequency] from the last full period before t = 20 s.

Usage:
    extractLastPeriod.py <caseDir> [--force-scale F] [--start-frac 0.5]
"""
from __future__ import annotations

import argparse
import math
import re
import sys
from pathlib import Path
from typing import List, Sequence, Tuple


NAN = float("nan")


def parseColumns(path: Path) -> List[List[float]]:
    """Read a whitespace/parenthesis-separated numeric file, ignoring # comments."""
    rows: List[List[float]] = []
    if not path.is_file():
        return rows
    with path.open() as f:
        for line in f:
            line = line.split("#", 1)[0].strip()
            if not line:
                continue
            tokens = re.sub(r"[()]", " ", line).split()
            try:
                rows.append([float(t) for t in tokens])
            except ValueError:
                continue
    return rows


def lastPeriodStats(t: Sequence[float], y: Sequence[float],
                    startFrac: float = 0.5) -> Tuple[float, float, float]:
    """Return (mean, half-amplitude, frequency) for the last full period.

    Period detected via downward zero-crossings of (y - mean_tail) on the
    trailing window t > startFrac * tEnd. Returns NaN for amp/freq if fewer
    than two suitable crossings are found.
    """
    if len(t) < 4:
        return (NAN, NAN, NAN)
    tEnd = t[-1]
    tStart = startFrac * tEnd
    idxTail = [i for i, ti in enumerate(t) if ti >= tStart]
    if len(idxTail) < 4:
        return (NAN, NAN, NAN)
    yTail = [y[i] for i in idxTail]
    tTail = [t[i] for i in idxTail]
    meanTail = sum(yTail) / len(yTail)

    # Downward zero crossings of (y - meanTail)
    crossings = []
    prev = yTail[0] - meanTail
    for k in range(1, len(yTail)):
        cur = yTail[k] - meanTail
        if prev > 0.0 and cur <= 0.0:
            # linear interpolation
            denom = (prev - cur)
            frac = prev / denom if denom != 0.0 else 0.0
            tc = tTail[k - 1] + frac * (tTail[k] - tTail[k - 1])
            crossings.append((tc, k))
        prev = cur
    if len(crossings) < 2:
        return (meanTail, NAN, NAN)
    tCrossLast = crossings[-1][0]
    tCrossPrev = crossings[-2][0]
    period = tCrossLast - tCrossPrev
    if period <= 0.0:
        return (meanTail, NAN, NAN)

    iA = crossings[-2][1]
    iB = crossings[-1][1]
    yLast = yTail[iA - 1:iB + 1]
    if len(yLast) < 2:
        return (meanTail, NAN, NAN)
    yMin = min(yLast)
    yMax = max(yLast)
    halfAmp = 0.5 * (yMax - yMin)
    mean = 0.5 * (yMax + yMin)
    return (mean, halfAmp, 1.0 / period)


def loadPointDisp(caseDir: Path) -> Tuple[List[float], List[float], List[float]]:
    """Find solidPointDisplacement_pointDisp.dat and return (t, ux, uy)."""
    candidates = sorted(caseDir.glob("postProcessing/*/solidPointDisplacement_pointDisp.dat"))
    if not candidates:
        candidates = sorted(caseDir.glob("postProcessing/**/solidPointDisplacement_*.dat"))
    if not candidates:
        return ([], [], [])
    rows = parseColumns(candidates[-1])
    t, ux, uy = [], [], []
    for r in rows:
        if len(r) >= 3:
            t.append(r[0])
            ux.append(r[1])
            uy.append(r[2])
    return (t, ux, uy)


def loadForces(caseDir: Path, scale: float = 1.0
               ) -> Tuple[List[float], List[float], List[float]]:
    """Find forces force.dat and return (t, Fx, Fy) summed over pressure+viscous."""
    candidates = sorted(caseDir.glob("postProcessing/forces/0/force.dat"))
    if not candidates:
        candidates = sorted(caseDir.glob("postProcessing/**/force.dat"))
    if not candidates:
        return ([], [], [])
    rows = parseColumns(candidates[-1])
    t, fx, fy = [], [], []
    for r in rows:
        if len(r) >= 7:
            # Time, then triplets: (p_x p_y p_z) (v_x v_y v_z) [(po_x po_y po_z)]
            ti = r[0]
            px, py = r[1], r[2]
            vx, vy = r[4], r[5]
            t.append(ti)
            fx.append(scale * (px + vx))
            fy.append(scale * (py + vy))
    return (t, fx, fy)


def main(argv: List[str]) -> int:
    p = argparse.ArgumentParser()
    p.add_argument("caseDir")
    p.add_argument("--force-scale", type=float, default=1.0,
                   help="Multiply force components (e.g. 1/0.015 for 2D unit "
                        "thickness on a 15 mm extruded mesh).")
    p.add_argument("--start-frac", type=float, default=0.5,
                   help="Trailing window fraction for stats (default 0.5).")
    args = p.parse_args(argv)

    caseDir = Path(args.caseDir)
    t, ux, uy = loadPointDisp(caseDir)
    tF, fx, fy = loadForces(caseDir, scale=args.force_scale)

    if t:
        uxMean, uxAmp, uxFreq = lastPeriodStats(t, ux, args.start_frac)
        uyMean, uyAmp, uyFreq = lastPeriodStats(t, uy, args.start_frac)
    else:
        uxMean = uxAmp = uxFreq = uyMean = uyAmp = uyFreq = NAN

    if tF:
        fxMean, fxAmp, fxFreq = lastPeriodStats(tF, fx, args.start_frac)
        fyMean, fyAmp, fyFreq = lastPeriodStats(tF, fy, args.start_frac)
    else:
        fxMean = fxAmp = fxFreq = fyMean = fyAmp = fyFreq = NAN

    def fmt(v: float) -> str:
        return "NaN" if math.isnan(v) else f"{v:.6g}"

    print(" ".join(fmt(x) for x in (
        uxMean, uxAmp, uxFreq, uyMean, uyAmp, uyFreq,
        fxMean, fxAmp, fxFreq, fyMean, fyAmp, fyFreq,
    )))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
