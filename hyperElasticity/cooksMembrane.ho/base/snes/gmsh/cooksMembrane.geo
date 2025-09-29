// Gmsh .geo file to create a mesh of a Cook's membrane

// Mesh spacing parameters
Include "meshSpacing/meshSpacing.geo";

// Define parameters
L = 0.048;
W = 0.044;
T = 0.060;

// Depth (out of plane)
d = 1;

// Points
Point(1) = {0, 0, 0, dx};
Point(2) = {L, W, 0, dx};
Point(3) = {L, T, 0, dx};
Point(4) = {0, W, 0, dx};

// Lines
Line(1) = {1, 2};
Line(2) = {2, 3};
Line(3) = {3, 4};
Line(4) = {4, 1};

// Surface
Line Loop(6) = {4, 1, 2, 3};
Plane Surface(6) = {6};

// Force mapped meshing (triangles)
Transfinite Surface {6};
// Uncomment this for unstructured mesh
//Mesh.Algorithm = 6;

// Optional: combine triangles into quadrilaterals
//Recombine Surface {6};

// Create volume by extrusion
Physical Volume("internal") = {1};
Extrude {0, 0, d} {
 Surface{6};
 Layers{1};
 Recombine;
}

// Boundary patches
Physical Surface("frontAndBack") = {28, 6};
Physical Surface("topAndBottom") = {27, 19};
Physical Surface("left") = {15};
Physical Surface("right") = {23};
