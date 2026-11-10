#!/usr/bin/env python3
"""Compare the plotting sources of this directory with a copy of the paperData package.

The styled plotting scripts exist in two places: here, where they plot the
results of new runs, and in the paperData package, where they regenerate the
published figures from archived data.  ``plotStyle/paperData_sources.tsv``
records, for every file that was copied from paperData, its source path and
the md5 checksum the source had when it was copied.

Usage:
    scripts/checkPlotSync.py /path/to/paperData

For every recorded file the script reports
  * whether the paperData source still has the recorded checksum (if not, the
    source changed after the copy and the change may have to be brought over);
  * whether the file here is identical to the current source or differs from
    it (files that were adapted for new-run input differ on purpose; the
    adaptations are listed in plotStyle/README.md).

Nothing is modified.  The exit status is 1 when a source changed since the copy
or is missing, otherwise 0.
"""

from __future__ import annotations

import difflib
import hashlib
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "plotStyle" / "paperData_sources.tsv"


def md5(path: Path) -> str:
    return hashlib.md5(path.read_bytes()).hexdigest()


def changed_lines(a: Path, b: Path) -> int:
    try:
        left = a.read_text().splitlines()
        right = b.read_text().splitlines()
    except UnicodeDecodeError:
        return -1
    return sum(1 for line in difflib.unified_diff(left, right, lineterm="", n=0)
               if line[:1] in "+-" and line[:3] not in ("+++", "---"))


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__)
        return 2
    package = Path(sys.argv[1]).expanduser().resolve()
    if not package.is_dir():
        print(f"ERROR: not a directory: {package}", file=sys.stderr)
        return 2

    stale = 0
    print(f"{'repository file':78s} {'paperData source':22s} this copy")
    for line in MANIFEST.read_text().splitlines():
        if not line.strip() or line.startswith("#"):
            continue
        local_rel, source_rel, recorded = line.split("\t")
        local, source = ROOT / local_rel, package / source_rel
        if not local.is_file():
            print(f"{local_rel:78s} {'-':22s} MISSING HERE")
            stale += 1
            continue
        if not source.is_file():
            print(f"{local_rel:78s} {'MISSING IN PACKAGE':22s} -")
            stale += 1
            continue
        if md5(source) == recorded:
            source_state = "unchanged since copy"
        else:
            source_state = "CHANGED SINCE COPY"
            stale += 1
        if md5(local) == md5(source):
            local_state = "identical to the source"
        else:
            n = changed_lines(source, local)
            local_state = "differs (binary)" if n < 0 else f"adapted: {n} changed lines"
        print(f"{local_rel:78s} {source_state:22s} {local_state}")

    if stale:
        print(f"\n{stale} file(s) need attention: compare them with the package and update "
              "plotStyle/paperData_sources.tsv when a change has been brought over.")
        return 1
    print("\nEvery paperData source still has the checksum recorded when it was copied.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
