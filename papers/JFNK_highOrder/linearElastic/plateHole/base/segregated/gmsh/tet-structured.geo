Include "meshSpacing/meshSpacing.geo";

// Plate size
L1 = 2;

//Plate width
L2 = 2;

// Hole radius
r = 0.5;

// Out of plane depth
d = 0.1;

//Radius of hole boundary layer
rb = 1.25;

//Cell number across each curve
n  = Ceil(1.0/dx) + 1;

// Points
Point(1) = {r, 0, 0, dx};
Point(2) = {L1, 0, 0, dx};
Point(3) = {L1, L2, 0, dx};
Point(4) = {0, L2, 0, dx};
Point(5) = {0, r, 0, dx};
Point(6) = {0, 0, 0, dx};
Point(7) = {rb, 0, 0, dx};
Point(8) = {0, rb, 0, dx};
Point(9) = {rb*Cos(45*Pi/180), rb*Sin(45*Pi/180), 0, dx};
Point(10) = {rb*Cos(45*Pi/180), L2, 0, dx};
Point(11) = {L1, rb*Sin(45*Pi/180), 0, dx};
Point(12) = {r*Cos(45*Pi/180), r*Sin(45*Pi/180), 0, dx};

// Lines

Circle(13) = {8, 6, 9};
Circle(14) = {9, 6, 7};
Line(15) = {1, 7};
Line(16) = {7, 2};
Line(17) = {2, 11};
Line(18) = {11, 3};
Line(19) = {3, 10};
Line(20) = {10, 4};
Line(21) = {4, 8};
Line(22) = {8, 5};
Line(23) = {9, 11};
Line(24) = {9, 10};
Circle(25) = {5, 6, 12};
Circle(26) = {12, 6, 1};
Line(27) = {12, 9};

// Surface
Curve Loop(1) = {27, -13, 22, 25};
Plane Surface(1) = {1};
Curve Loop(2) = {26, 15, -14, -27};
Plane Surface(2) = {2};
Curve Loop(3) = {14, 16, 17, -23};
Plane Surface(3) = {3};
Curve Loop(4) = {23, 18, 19, -24};
Plane Surface(4) = {4};
Curve Loop(5) = {13, 24, 20, 21};
Plane Surface(5) = {5};

//Force mapped meshing (triangles)
Transfinite Surface {1} = {5, 12, 9, 8};
Transfinite Surface {2} = {12, 1, 7, 9};
Transfinite Surface {3} = {7, 2, 11, 9};
Transfinite Surface {4};
Transfinite Surface {5} = {8, 9, 10, 4};
Transfinite Curve {13,14,25,26,15,16,17,18,19,20,21,22,23,24,27} = n Using Progression 1;

// Create volume by extrusion
Extrude {0, 0, d} {
  Surface{1}; Surface{2}; Surface{3}; Surface{4}; Surface{5};
  Layers{1};
  Recombine;
}

Physical Volume("internal",138) = {5, 4, 1, 2, 3};
Physical Surface("left") = {44, 136};
Physical Surface("down") = {62, 84};
Physical Surface("right") = {88, 106};
Physical Surface("up") = {110, 132};
Physical Surface("hole") = {48, 58};
Physical Surface("front") = {71, 49, 137, 115, 93};
Physical Surface("back") = {2, 3, 1, 5, 4};