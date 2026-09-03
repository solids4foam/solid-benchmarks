// Pablo Gmsh .geo file adapted for the Cook's membrane benchmark

// Mesh spacing parameters
Include "meshSpacing.geo";

lc = dx;
thickness = 1.0;
z0 = -0.5;

// Geometry
Point(1) = {0.0, 0.0, z0, lc};
Point(2) = {0.0, 44, z0, lc};
Point(3) = {48, 60, z0, lc};
Point(4) = {48, 44, z0, lc};

Line(1) = {1, 2};
Line(2) = {2, 3};
Line(3) = {3, 4};
Line(4) = {4, 1};

Curve Loop(1) = {1, 2, 3, 4};
Plane Surface(1) = {1};

// Use Pablo's Delaunay-style unstructured surface meshing
Mesh.Algorithm = 5;

// Let the background field define the target size everywhere
Mesh.MeshSizeFromPoints = 0;
Mesh.MeshSizeFromCurvature = 0;
Mesh.MeshSizeExtendFromBoundary = 0;

Field[1] = Box;
Field[1].VIn = dx;
Field[1].VOut = dx;
Field[1].XMin = 0;
Field[1].XMax = 48;
Field[1].YMin = 0;
Field[1].YMax = 60;
Field[1].Thickness = 1.0;

Background Field = 1;

out[] = Extrude {0, 0, thickness} {
    Surface{1};
    Layers{1};
    Recombine;
};

Physical Volume("internal") = {out[1]};

Physical Surface("frontAndBack") = {1, out[0]};
Physical Surface("left") = {out[2]};
Physical Surface("topAndBottom") = {out[3], out[5]};
Physical Surface("right") = {out[4]};

Mesh.MshFileVersion = 2.2;
