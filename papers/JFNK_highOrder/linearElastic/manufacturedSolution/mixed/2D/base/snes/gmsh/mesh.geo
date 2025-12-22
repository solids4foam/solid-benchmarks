// Gmsh .geo file to create a mesh of a cube LxLxd

// Mesh spacing parameters
Include "meshSpacing/meshSpacing.geo";

// Cube edge lenght
L = 1;

// Depth (out of plane)
d = 0.1;

// Points
Point(1) = {0, 0, 0, 1};
Point(2) = {L, 0, 0, 1};
Point(3) = {L, L, 0, 1};
Point(4) = {0, L, 0, 1};

// Lines
Line(1) = {1, 2};
Line(2) = {2, 3};
Line(3) = {3, 4};
Line(4) = {4, 1};

// Surface
Line Loop(6) = {4, 1, 2, 3};
Plane Surface(6) = {6};

// Force structured meshing
Transfinite Line{1, 3} = L/dx + 1;
Transfinite Line{2, 4} = L/dx + 1;
Transfinite Surface {6};

// Combine triangles into quadrilaterals
// Recombine Surface {6};

// Create volume by extrusion
Physical Volume("internal") = {1};
Extrude {0, 0, d} {
 Surface{6};
 Layers{1};
 Recombine;
}

// Boundary patches
Physical Surface("front") = {6};
Physical Surface("back") = {28};
Physical Surface("sides1") = {27};
Physical Surface("sides2") = {19};
Physical Surface("sides3") = {15};
Physical Surface("sides4") = {23};
