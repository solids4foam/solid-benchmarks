// Average mesh spacing
dx = 0.1;

// Plate size
L = 2;

// Hole radius
r = 0.5;

// Out of plane depth
d = 0.1;

// Points
Point(1) = {r, 0, 0, dx};
Point(2) = {L, 0, 0, dx};
Point(3) = {L, L, 0, dx};
Point(4) = {0, L, 0, dx};
Point(5) = {0, r, 0, dx};
Point(6) = {0, 0, 0, dx};
//Point(6) = {r*Cos(60*Pi/180), r*Sin(60*Pi/180), 0, dx};
//Point(7) = {r*Cos(45*Pi/180), r*Sin(45*Pi/180), 0, dx};
//Point(8) = {r*Cos(30*Pi/180), r*Sin(30*Pi/180), 0, dx};

// Lines
Line(1) = {1, 2};
Line(2) = {2, 3};
Line(3) = {3, 4};
Line(4) = {4, 5};
Circle(5) = {5, 6, 1};
//Circle(6) = {1, 8, 7};
//Circle(5) = {0, 0, 0, r, 0, 2*Pi};

// Surface
Curve Loop(1) = {1, 2, 3, 4, 5};
Plane Surface(1) = {1};

// Create volume by extrusion
Physical Volume("internal") = {1};
newEntities[]=
    Extrude {0, 0, d} {
     Surface{1};
     Layers{1};
     Recombine;
    };

// Boundary patches
//Physical Surface("back") = {6};
Physical Surface("front") = {newEntities[0]};
Physical Surface("back") = {newEntities[1]};
Physical Surface("down") = {newEntities[2]};
Physical Surface("right") = {newEntities[3]};
Physical Surface("up") = {newEntities[4]};
Physical Surface("left") = {newEntities[5]};
Physical Surface("hole") = {newEntities[6]};
