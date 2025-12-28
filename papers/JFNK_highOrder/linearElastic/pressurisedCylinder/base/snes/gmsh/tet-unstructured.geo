// Gmsh .geo file to create a mesh of a beam

// Mesh spacing parameters
Include "meshSpacing/meshSpacing.geo";

// Geometry parameters
R_inner = 7.0;       // Inner radius
R_outer = 18.625;    // Outer radius (R_inner + thickness)
d       = 0.1;       // Depth (out of plane extrusion distance)

//-----------------------------------------------------------------------------
// 2D Geometry Definition
//-----------------------------------------------------------------------------

// Center point for the arcs
Point(1) = {0, 0, 0, dx};

// Points defining the start of the bend (at 0 degrees on the X-axis)
Point(2) = {R_inner, 0, 0, dx};
Point(3) = {R_outer, 0, 0, dx};

// Points defining the end of the bend (at 90 degrees on the Y-axis)
Point(4) = {0, R_inner, 0, dx};
Point(5) = {0, R_outer, 0, dx};

// Lines and Arcs that form the boundary of the 2D shape.
Line(1)   = {2, 3};
Circle(2) = {3, 1, 5};
Line(3)   = {5, 4};
Circle(4) = {4, 1, 2};

// Surface definition from the lines and arcs.
Line Loop(5) = {1, 2, 3, 4};
Plane Surface(6) = {5};

//-----------------------------------------------------------------------------
// 3D Extrusion and Physical Group Definition
//-----------------------------------------------------------------------------

ov[] = Extrude {0, 0, d} {
  Surface{6};
  Layers{1};
  Recombine;
};

// Assign physical groups for boundary conditions and volume
Physical Volume("internal") = {ov[1]};
Physical Surface("front") = {ov[0]};
Physical Surface("back") = {6};
Physical Surface("symmetry-y") = {ov[2]};
Physical Surface("outer") = {ov[3]};
Physical Surface("symmetry-x") = {ov[4]};
Physical Surface("inner") = {ov[5]};

//-----------------------------------------------------------------------------
// Meshing Algorithm
//-----------------------------------------------------------------------------

// Use the Frontal-Delaunay algorithm for unstructured meshes
Mesh.Algorithm = 5;
