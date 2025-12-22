// Gmsh .geo file to create a mesh of a beam

// Mesh spacing parameters
Include "meshSpacing/meshSpacing.geo";

// Geometry parameters
R_inner = 7.0;       // Inner radius
R_outer = 18.625;    // Outer radius (R_inner + thickness)
d       = 1;       // Depth (out of plane extrusion distance)

N_radial = Ceil((R_outer - R_inner) / dx);
N_circumferential = Ceil(R_inner * Pi / 2 / dx);

//-----------------------------------------------------------------------------
// 2D Geometry Definition
//-----------------------------------------------------------------------------

// Center point for the arcs
Point(1) = {0, 0, 0, dx};

// Points for the geometry
Point(2) = {R_inner, 0, 0, dx};
Point(3) = {R_outer, 0, 0, dx};
Point(4) = {0, R_inner, 0, dx};
Point(5) = {0, R_outer, 0, dx};

// Boundary curves
Line(1)   = {2, 3};
Circle(2) = {3, 1, 5};
Line(3)   = {5, 4};
Circle(4) = {4, 1, 2};

//-- FIXED: Re-added the essential commands to create the surface --
// First, create a contiguous loop from the boundary curves
Line Loop(5) = {1, 2, 3, 4};
// Then, create a plane surface from that loop
Plane Surface(6) = {5};

//-----------------------------------------------------------------------------
// Structured Meshing Commands
//-----------------------------------------------------------------------------

// Define the number of nodes on the boundary curves
Transfinite Line {1, 3} = N_radial + 1;
Transfinite Line {2, 4} = N_circumferential + 1;

// Define the surface as transfinite to create a mapped grid
Transfinite Surface {6};

// Force the mesher to create quadrilaterals
Recombine Surface {6};

//-----------------------------------------------------------------------------
// 3D Extrusion and Physical Group Definition
//-----------------------------------------------------------------------------

ov[] = Extrude {0, 0, d} {
  Surface{6};
  Layers{1};
  Recombine;
};

// Assign physical groups using the custom names
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
Mesh.Algorithm = 8; // Frontal-Delaunay for Quads
