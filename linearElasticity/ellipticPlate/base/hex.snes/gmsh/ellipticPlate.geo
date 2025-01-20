// Mesh spacing parameters
Include "meshSpacing.geo";

// Parameters for the ellipses
a_inner = 2;
b_inner = 1;
a_outer = 3.25;
b_outer = 2.75;
extrude_length = 0.6;

// Points for the inner quarter-ellipse (hole)
Point(1) = {0, 0, 0, 1.0}; // Center point
Point(2) = {a_inner, 0, 0, 1.0};
Point(3) = {0, b_inner, 0, 1.0};

// Points for the outer quarter-ellipse (plate boundary)
Point(4) = {a_outer, 0, 0, 1.0};
Point(5) = {0, b_outer, 0, 1.0};

// Curves for the inner quarter-ellipse
Ellipse(1) = {2, 1, 3};  // Inner quarter-ellipse

// Curves for the outer quarter-ellipse
Ellipse(2) = {4, 1, 5};  // Outer quarter-ellipse

// Lines along X and Y axes to close the quarter surfaces
Line(3) = {2, 4}; // Line connecting outer and inner along X-axis
Line(4) = {3, 5}; // Line connecting outer and inner along Y-axis

// Line loop for the quarter surface
Line Loop(5) = {1, 4, -2, -3};

// Plane surface for the quarter
Plane Surface(6) = {5};

// Extrude the quarter surface to create the volume
Extrude {0, 0, extrude_length} {
  Surface{6};
  Layers {nLayers}; // Set the number of layers in the extrusion direction
  Recombine;
}

// Set the transfinite lines for structured mesh
Transfinite Curve {1, 2} = nEllipse Using Progression 1.02;  // For the ellipses
Transfinite Curve {3, 4} = nRadial Using Progression 1;  // For the X and Y axes

// Set the transfinite surface and volume for structured mesh
Transfinite Surface {6};
Recombine Surface {6};
Transfinite Volume {1};
Recombine Volume {1};

// Define physical groups for boundary conditions
Physical Surface("bottom") = {6}; // The inner quarter-ellipse
Physical Surface("inside") = {15};
Physical Surface("symmx") = {19};
Physical Surface("outside") = {23};
Physical Surface("top") = {28};
Physical Surface("symmy") = {27};

// Define physical volume for the 3D region
Physical Volume("volume") = {1};

// Mesh generation
Mesh 3;
