// Gmsh .geo file to create a mesh of a cube LxLxd

// Mesh spacing parameters
Include "meshSpacing/meshSpacing.geo";

// Define parameters
L  = 1;

// Depth (out of plane)
hz = 0.1;

// Points
Point(1) = {0, 0, 0, dx};
Point(2) = {L, 0, 0, dx};
Point(3) = {L, L, 0, dx};
Point(4) = {0, L, 0, dx};

// Lines
Line(1) = {1, 2};
Line(2) = {2, 3};
Line(3) = {3, 4};
Line(4) = {4, 1};

// Surface
Line Loop(10) = {1, 2, 3, 4};
Plane Surface(11) = {10};

// Create volume by extrusion
out[] = Extrude {0, 0, hz} {
 Surface{11};
 Layers{1};
 Recombine;
};

// Boundary patches
Physical Surface("frontAndBack") = {out[0], 11};
Physical Surface("sides") = {out[2],out[3],out[4],out[5]};
Physical Volume("internal") = {out[1]};