#!/usr/bin/env python3
"""Put a re-rendered data layer back into the Keynote overlay figures.

``land_problem2_m3_combined_overlay.pdf`` and
``land_problem3_m3_combined_overlay.pdf`` (manuscript Figs 15, 16) are Keynote
exports in which P. Cardiff placed faint JPEG crops of the Land et al. (2015)
result figures (Form XObjects /Fm1-/Fm3 drawn with alpha ~0.2) and pasted the
vector data layer on top, once per panel (Fig 15: three copies with slightly
different transforms, each clipped to its panel region) or once (Fig 16).

This tool rebuilds the page content:
  * keeps every original content group that draws a faint layer (``Do``) or
    the white background, unchanged;
  * removes the pasted vector data groups (identified by their ``cm``
    matrices, which are listed below and were read from the originals);
  * appends the new data layer as a Form XObject, drawn under exactly the
    same clip rectangles and transformation matrices as the removed copies.
Because the new layer keeps the original panel geometry, the alignment with
the faint reference layers is preserved.  The Keynote-added tick labels
"-8.75"/"-8.25" of Fig 16 panel (c) are removed because the new layer draws
those ticks itself.

Usage:
  composite_land_overlay.py --problem 2 --overlay <overlay pdf>
                            --layer <new layer pdf> --output <pdf>
  composite_land_overlay.py --problem 2 --overlay <original Keynote pdf>
                            --write-reference <reference-layers pdf>

``--overlay`` is either an original Keynote export or a reference-layers file
written by ``--write-reference``.  A reference-layers file holds the white
background and the faint published layers only: every pasted data group of the
Keynote export has been removed and nothing was added.  It is recognised by
its document-information entry ``/JFNKReferenceLayers``.  In both cases the
composite can only show the data layer given with ``--layer``: an overlay
whose pasted data groups cannot all be identified is rejected.
"""

from __future__ import annotations

import argparse
from pathlib import Path

from pypdf import PdfReader, PdfWriter
from pypdf.generic import (ArrayObject, ContentStream, DictionaryObject, FloatObject,
                           NameObject, StreamObject)

# (clip rectangle x y w h, matrix a b c d e f) of each pasted data copy
PLACEMENTS = {
    2: [
        ((194.915, 256.6357, 378.9659, 268.6548), (0.877236, 0, 0, 0.877236, 194.915, 70.53152)),
        ((199.5775, 79.2078, 182.4218, 178.5669), (0.876243, 0, 0, 0.876243, 194.8726, 70.3641)),
        ((389.438, 77.6899, 181.6047, 179.7183), (0.871905, 0, 0, 0.871905, 196.9999, 70.97111)),
    ],
    3: [
        ((263.2329, 63.0092, 384.4167, 461.3), (0.889853, 0, 0, 0.889853, 263.2329, 63.00916)),
    ],
}
# matrices of the data copies to remove (matched on the scale factor)
DATA_SCALES = {2: (0.877236, 0.876243, 0.871905), 3: (0.889853,)}
# Fig 16 only: the group that draws /Fm3 also contains hand-typed tick labels
STRIP_TEXT_IN_GROUPS_WITH_DO = {3: ("/Fm3",)}


def _op_name(op) -> str:
    return op.decode() if isinstance(op, bytes) else str(op)


def top_level_groups(ops):
    """Yield (start, end) index pairs of the top-level q ... Q groups."""
    depth = 0
    start = None
    for i, (_, op) in enumerate(ops):
        name = _op_name(op)
        if name == "q":
            depth += 1
            if depth == 1:
                start = i
        elif name == "Q":
            depth -= 1
            if depth == 0:
                yield start, i
                start = None
    if depth != 0:
        raise ValueError("unbalanced q/Q in overlay content stream")


def group_info(ops, start, end):
    cm = None
    dos = []
    for operands, op in ops[start:end + 1]:
        name = _op_name(op)
        if name == "cm" and cm is None:
            cm = [float(v) for v in operands]
        if name == "Do":
            dos.append(str(operands[0]))
    return cm, dos


def strip_text(ops_slice):
    """Remove BT ... ET blocks from a list of operations."""
    out = []
    in_text = False
    for operands, op in ops_slice:
        name = _op_name(op)
        if name == "BT":
            in_text = True
            continue
        if name == "ET":
            in_text = False
            continue
        if not in_text:
            out.append((operands, op))
    return out


REFERENCE_KEY = "/JFNKReferenceLayers"


def _without_data_groups(problem: int, ops, expected: int):
    """Return the page operations without the pasted data groups.

    ``expected`` is the number of data groups that must be found: 13 per
    placement in an original Keynote export, none in a reference-layers file.
    Any other number is an error, so that an unrecognised overlay can never
    carry old curves into a composite.
    """
    kept = []
    removed = 0
    scales = DATA_SCALES[problem]
    for start, end in top_level_groups(ops):
        cm, dos = group_info(ops, start, end)
        is_data_copy = (not dos) and cm is not None and any(abs(cm[0] - s) < 1e-5 for s in scales)
        if is_data_copy:
            removed += 1
            continue
        block = ops[start:end + 1]
        if dos and any(d in STRIP_TEXT_IN_GROUPS_WITH_DO.get(problem, ()) for d in dos):
            block = strip_text(block)
        else:
            # every remaining group must be the white background or draw a faint layer
            painted = sum(1 for _, op in block if _op_name(op) in ("S", "s", "B", "B*", "b", "b*", "BT"))
            if not dos and painted:
                raise RuntimeError("overlay has an unrecognised vector group besides the published layers")
        kept.extend(block)
    if removed != expected:
        raise RuntimeError(f"expected {expected} pasted data groups in the overlay, found {removed}")
    return kept, removed


def _is_reference(reader, problem: int | None = None) -> bool:
    """True for a file written by write_reference (for ``problem`` when given)."""
    info = reader.metadata or {}
    if REFERENCE_KEY not in info:
        return False
    if problem is not None and not str(info[REFERENCE_KEY]).startswith(f"problem {problem};"):
        raise RuntimeError(f"the reference-layers file is for another problem: {info[REFERENCE_KEY]}")
    return True


def write_reference(problem: int, overlay: Path, output: Path) -> None:
    """Write the published layers of an original Keynote export without its pasted data groups."""
    import io

    reader = PdfReader(str(overlay))
    if _is_reference(reader):
        raise RuntimeError(f"{overlay} is already a reference-layers file")
    writer = PdfWriter()
    writer.append(reader)
    page = writer.pages[0]
    content = ContentStream(page.get_contents(), writer)
    kept, removed = _without_data_groups(problem, content.operations, 13 * len(PLACEMENTS[problem]))
    content.operations = kept
    page.replace_contents(content)
    resources = page["/Resources"]
    fonts = resources.get("/Font")
    if fonts is not None:      # fonts of the removed data layer and of the removed tick labels
        used = {str(operands[0]) for operands, op in kept if _op_name(op) == "Tf"}
        fonts = fonts.get_object()
        for key in [k for k in fonts.keys() if str(k) not in used]:
            del fonts[key]
    buffer = io.BytesIO()
    writer.write(buffer)
    buffer.seek(0)
    # second pass: copy the page into a new document so that only objects that
    # the page still uses are written (the old content stream is dropped)
    clean = PdfWriter()
    clean.add_page(PdfReader(buffer).pages[0])
    clean.add_metadata({
        "/Title": f"Land et al. (2015) problem {problem}: published results, reference layers only",
        "/Author": "Layers: Land et al. (2015), Proc. R. Soc. A 471:20150641, CC BY 4.0; arrangement: P. Cardiff",
        "/Subject": "Faint crops of the published result figures; contains no data of the present work",
        REFERENCE_KEY: f"problem {problem}; {removed} pasted data groups removed",
    })
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open("wb") as handle:
        clean.write(handle)
    print(f"Wrote {output} (removed {removed} pasted data groups; nothing added)")


def composite(problem: int, overlay: Path, layer: Path, output: Path) -> None:
    reader = PdfReader(str(overlay))
    expected_data_groups = 0 if _is_reference(reader, problem) else 13 * len(PLACEMENTS[problem])
    writer = PdfWriter()
    writer.append(reader)
    page = writer.pages[0]

    # --- new data layer as a Form XObject -------------------------------
    layer_reader = PdfReader(str(layer))
    layer_page = layer_reader.pages[0]
    writer.add_page(layer_page)                     # imports fonts/resources
    imported = writer.pages[-1]
    form = StreamObject()
    form[NameObject("/Type")] = NameObject("/XObject")
    form[NameObject("/Subtype")] = NameObject("/Form")
    form[NameObject("/FormType")] = FloatObject(1)
    form[NameObject("/BBox")] = ArrayObject([FloatObject(float(v)) for v in layer_page.mediabox])
    form[NameObject("/Resources")] = imported["/Resources"]
    form.set_data(imported.get_contents().get_data())
    form_ref = writer._add_object(form)
    writer.remove_page(len(writer.pages) - 1)

    resources = page["/Resources"]
    xobjects = resources.get("/XObject")
    if xobjects is None:
        xobjects = DictionaryObject()
        resources[NameObject("/XObject")] = xobjects
    xobjects = xobjects.get_object()
    layer_name = "/FmDataLayer2026"
    xobjects[NameObject(layer_name)] = form_ref

    # --- rebuild the content stream ------------------------------------
    content = ContentStream(page.get_contents(), writer)
    kept, removed = _without_data_groups(problem, content.operations, expected_data_groups)

    def f(v):
        return FloatObject(round(float(v), 6))

    for (x, y, w, h), (a, b, c, d, e, g) in PLACEMENTS[problem]:
        kept.append(([], b"q"))
        kept.append(([f(x), f(y), f(w), f(h)], b"re"))
        kept.append(([], b"W"))
        kept.append(([], b"n"))
        kept.append(([f(a), f(b), f(c), f(d), f(e), f(g)], b"cm"))
        kept.append(([NameObject(layer_name)], b"Do"))
        kept.append(([], b"Q"))
    content.operations = kept
    page.replace_contents(content)

    # prune font resources that are no longer referenced (old pasted layer
    # fonts on the page; ReportLab's default base-14 entry in the new layer)
    def used_fonts(operations):
        return {str(operands[0]) for operands, op in operations if _op_name(op) == "Tf"}

    def prune(resource_dict, keep):
        fonts = resource_dict.get("/Font")
        if fonts is None:
            return
        fonts = fonts.get_object()
        for key in [k for k in fonts.keys() if str(k) not in keep]:
            del fonts[key]

    prune(resources, used_fonts(kept))
    layer_ops = ContentStream(form, writer).operations
    prune(form["/Resources"].get_object(), used_fonts(layer_ops))

    output.parent.mkdir(parents=True, exist_ok=True)
    writer.add_metadata({"/Title": f"Land problem {problem}: mid-wall deformation with Land et al. (2015) overlay",
                         "/Subject": "Published layers: Land et al. (2015), Proc. R. Soc. A 471:20150641, CC BY 4.0; "
                                     "arrangement by P. Cardiff; data layer of the present work added"})
    with output.open("wb") as handle:
        writer.write(handle)
    print(f"Wrote {output} (removed {removed} pasted data groups, added {len(PLACEMENTS[problem])} layer placements)")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--problem", type=int, choices=(2, 3), required=True)
    parser.add_argument("--overlay", type=Path, required=True,
                        help="reference-layers PDF, or an original Keynote overlay PDF")
    parser.add_argument("--layer", type=Path, help="data layer PDF of the present work")
    parser.add_argument("--output", type=Path)
    parser.add_argument("--write-reference", type=Path,
                        help="instead of compositing: write the published layers of an original Keynote "
                             "overlay without its pasted data groups to this file")
    args = parser.parse_args()
    try:
        if args.write_reference is not None:
            if args.layer is not None or args.output is not None:
                parser.error("--write-reference cannot be combined with --layer or --output")
            write_reference(args.problem, args.overlay, args.write_reference)
        else:
            if args.layer is None or args.output is None:
                parser.error("--layer and --output are required")
            composite(args.problem, args.overlay, args.layer, args.output)
    except (OSError, RuntimeError, ValueError) as error:
        raise SystemExit(f"ERROR: {error}") from error


if __name__ == "__main__":
    main()
