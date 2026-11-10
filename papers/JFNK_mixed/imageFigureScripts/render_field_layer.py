#!/usr/bin/env pvpython
"""Render one OpenFOAM field as a clean image layer (no scalar bar, no axes).

The scalar bar and all text are added afterwards with matplotlib
(compose_field_figure.py) so that the printed text is vector Helvetica at
the manuscript sizes.  Only the field colours are produced here.
"""
import argparse, json, sys
from paraview.simple import *  # noqa

ap = argparse.ArgumentParser()
ap.add_argument("--case", required=True, help="path to <case>/case.foam")
ap.add_argument("--time", type=float, required=True)
ap.add_argument("--array", required=True, help="e.g. sigmaEq, sigma:0 (component), D:mag")
ap.add_argument("--point-data", action="store_true", help="colour by the cell-to-point interpolated array")
ap.add_argument("--clean", action="store_true", help="merge coincident points (CleantoGrid) before interpolating; removes seams from duplicated block-junction points")
ap.add_argument("--c2p", action="store_true", help="use an explicit CellDatatoPointData filter (reader cell-to-point off); avoids NaN seams on clipped meshes")
ap.add_argument("--range", required=True, help="lo,hi (comma separated; negative values allowed)")
ap.add_argument("--levels", type=int, default=0, help="discrete colour levels (0 = continuous)")
ap.add_argument("--scale-factor", type=float, default=1.0, help="multiply the array (unit conversion) before colouring")
ap.add_argument("--warp", default=None, help="vector array to warp by (e.g. D)")
ap.add_argument("--warp-scale", type=float, default=1.0)
ap.add_argument("--clip", default=None, help="ox,oy,oz,nx,ny,nz")
ap.add_argument("--surface-from-patches", action="store_true", help="draw the boundary patches (clipped) plus the planar cut of the internal mesh instead of the clipped internal mesh surface; avoids rendering seams of the volume surface")
ap.add_argument("--nan-transparent", action="store_true", help="hide NaN-valued cells (off by default)")
ap.add_argument("--no-cut-face", action="store_true", help="with --surface-from-patches: do not draw the planar cut of the internal mesh")
ap.add_argument("--crinkle", action="store_true", help="crinkle clip (whole cells kept, no interpolated cut cells)")
ap.add_argument("--slice", default=None, help="ox,oy,oz,nx,ny,nz: colour a planar slice instead of the body")
ap.add_argument("--wireframe-opacity", type=float, default=0.0, help="also draw the whole (warped) body as a wireframe with this opacity")
ap.add_argument("--wire-width", type=float, default=0.8)
ap.add_argument("--edges", action="store_true")
ap.add_argument("--edge-color", type=float, nargs=3, default=(0.1, 0.1, 0.1))
ap.add_argument("--edge-width", type=float, default=1.0)
ap.add_argument("--camera", default=None, help="px,py,pz,fx,fy,fz,ux,uy,uz")
ap.add_argument("--parallel", action="store_true")
ap.add_argument("--parallel-scale", type=float, default=None)
ap.add_argument("--view-angle", type=float, default=30.0)
ap.add_argument("--zoom", type=float, default=1.0)
ap.add_argument("--size", type=int, nargs=2, default=(1600, 1200))
ap.add_argument("--lighting", default="default", choices=("default", "flat"))
ap.add_argument("--out", required=True)
ap.add_argument("--dump", default=None, help="write the camera and ranges used to this JSON file")
a = ap.parse_args()
a.range = [float(v) for v in a.range.split(",")]
a.clip = [float(v) for v in a.clip.split(",")] if a.clip else None
a.slice = [float(v) for v in a.slice.split(",")] if a.slice else None
a.camera = [float(v) for v in a.camera.split(",")] if a.camera else None

r = OpenFOAMReader(FileName=a.case)
if a.surface_from_patches:
    if a.clip is None:
        raise SystemExit("--surface-from-patches needs --clip")
    regions = list(r.GetProperty("MeshRegions").GetAvailable())
    r.MeshRegions = [n for n in regions if n != "internalMesh"]
    rint = OpenFOAMReader(FileName=a.case); rint.MeshRegions = ["internalMesh"]
else:
    r.MeshRegions = ["internalMesh"]
if a.c2p:
    try:
        r.Createcelltopointfiltereddata = 0
    except Exception:
        pass
r.UpdatePipelineInformation()
r.UpdatePipeline(a.time)
src = r
if a.surface_from_patches:
    src = MergeBlocks(Input=r)
if a.clean:
    src = CleantoGrid(Input=src)
if a.c2p:
    c2p = CellDatatoPointData(Input=src)
    c2p.ProcessAllArrays = 1
    c2p.PassCellData = 1
    src = c2p
cut_face = None
if a.surface_from_patches:
    rint.UpdatePipelineInformation(); rint.UpdatePipeline(a.time)
    cf = rint
    if a.warp is not None:
        cfw = WarpByVector(Input=cf); cfw.Vectors = ["POINTS", a.warp]; cfw.ScaleFactor = a.warp_scale; cf = cfw
    cut_face = Slice(Input=cf); cut_face.SliceType = "Plane"
    cut_face.SliceType.Origin = a.clip[:3]; cut_face.SliceType.Normal = a.clip[3:]
if a.warp is not None:
    w = WarpByVector(Input=src); w.Vectors = ["POINTS", a.warp]; w.ScaleFactor = a.warp_scale
    src = w
body = src
if a.clip is not None:
    c = Clip(Input=src); c.ClipType = "Plane"
    c.ClipType.Origin = a.clip[:3]; c.ClipType.Normal = a.clip[3:]
    c.Invert = 0
    if a.crinkle:
        c.Crinkleclip = 1
    src = c
if a.slice is not None:
    sl = Slice(Input=src); sl.SliceType = "Plane"
    sl.SliceType.Origin = a.slice[:3]; sl.SliceType.Normal = a.slice[3:]
    src = sl
name, comp = (a.array.split(":") + [None])[:2]
assoc = "POINTS" if a.point_data or a.warp is not None else "CELLS"
if a.scale_factor != 1.0 and a.wireframe_opacity > 0:
    raise SystemExit("--scale-factor cannot be combined with --wireframe-opacity (use display units in the composer instead)")
if a.scale_factor != 1.0:
    calc = Calculator(Input=src)
    calc.AttributeType = "Point Data" if assoc == "POINTS" else "Cell Data"
    calc.ResultArrayName = "scaled"
    if comp == "mag":
        calc.Function = f"mag({name})*{a.scale_factor}"
    elif comp is not None:
        calc.Function = f"{name}_{['XX','XY','XZ','YY','YZ','ZZ'][int(comp)] if name=='sigma' else comp}*{a.scale_factor}"
    else:
        calc.Function = f"{name}*{a.scale_factor}"
    src = calc; name, comp = "scaled", None

view = GetActiveViewOrCreate("RenderView")
view.ViewSize = a.size
view.OrientationAxesVisibility = 0
view.Background = [1, 1, 1]
try:
    view.UseColorPaletteForBackground = 0
except Exception:
    pass
disp = Show(src, view)
disp.SetRepresentationType("Surface With Edges" if a.edges else "Surface")
if a.edges:
    disp.EdgeColor = list(a.edge_color); disp.LineWidth = a.edge_width
if a.lighting == "flat":
    disp.Ambient = 1.0; disp.Diffuse = 0.0; disp.Specular = 0.0
ColorBy(disp, (assoc, name) if comp is None else (assoc, name, {"mag": "Magnitude"}.get(comp, comp)))
lut = GetColorTransferFunction(name)
lut.ApplyPreset("Viridis (matplotlib)", True)
if a.nan_transparent:
    lut.NanOpacity = 0.0   # note: switches VTK to an alpha-blended mapping path that can expose coincident-face seams
if comp is not None and comp != "mag":
    lut.VectorMode = "Component"; lut.VectorComponent = int(comp)
elif comp == "mag":
    lut.VectorMode = "Magnitude"
lut.RescaleTransferFunction(a.range[0], a.range[1])
lut.AutomaticRescaleRangeMode = "Never"
# A discretised table is used in both cases: with 256 entries it is visually
# continuous, and the continuous (Discretize = 0) path of VTK draws a hairline
# at coincident-face rings of the LV mesh.
lut.Discretize = 1
lut.NumberOfTableValues = a.levels if a.levels > 0 else 256
disp.SetScalarBarVisibility(view, False)
if cut_face is not None and not a.no_cut_face:
    cfd = Show(cut_face, view); cfd.SetRepresentationType("Surface")
    ColorBy(cfd, (assoc, name) if comp is None else (assoc, name, {"mag": "Magnitude"}.get(comp, comp)))
    cfd.SetScalarBarVisibility(view, False)
if a.wireframe_opacity > 0:
    wd = Show(body, view)
    wd.SetRepresentationType("Wireframe")
    wd.LineWidth = a.wire_width
    wd.Opacity = a.wireframe_opacity
    ColorBy(wd, (assoc, name) if comp is None else (assoc, name, {"mag": "Magnitude"}.get(comp, comp)))
    wd.SetScalarBarVisibility(view, False)
cam = view.GetActiveCamera()
if a.camera is not None:
    cam.SetPosition(a.camera[0:3]); cam.SetFocalPoint(a.camera[3:6]); cam.SetViewUp(a.camera[6:9])
else:
    view.ResetCamera()
if a.parallel:
    cam.SetParallelProjection(1)
    if a.parallel_scale: cam.SetParallelScale(a.parallel_scale)
else:
    cam.SetParallelProjection(0); cam.SetViewAngle(a.view_angle)
if a.camera is None:
    view.ResetCamera()
cam.Zoom(a.zoom)
Render(view)
SaveScreenshot(a.out, view, ImageResolution=a.size, TransparentBackground=1)
info = {"camera": {"position": list(cam.GetPosition()), "focal": list(cam.GetFocalPoint()), "viewup": list(cam.GetViewUp()),
                   "parallel": bool(cam.GetParallelProjection()), "parallel_scale": cam.GetParallelScale(), "view_angle": cam.GetViewAngle()},
        "array": a.array, "range": a.range, "levels": a.levels, "scale_factor": a.scale_factor, "time": a.time, "case": a.case,
        "warp": a.warp, "clip": a.clip, "slice": a.slice, "wireframe_opacity": a.wireframe_opacity, "surface_from_patches": a.surface_from_patches}
print(json.dumps(info))
if a.dump:
    open(a.dump, "w").write(json.dumps(info, indent=1))
