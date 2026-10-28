// Gmsh script: tetrahedral mesh of the drone frame (quarter model)
// Run:  gmsh -3 droneFrame.geo -o droneFrame.msh
SetFactory("OpenCASCADE");
Merge "droneFrame.stp";          // geometry in millimetres

Mesh.CharacteristicLengthMin = 0.4;
Mesh.CharacteristicLengthMax = 1.0;
Mesh.CharacteristicLengthFromCurvature = 1;
Mesh.MinimumElementsPerTwoPi = 12;
Mesh.Algorithm   = 6;             // Frontal-Delaunay (2D)
Mesh.Algorithm3D = 10;            // HXT (3D)
Mesh.Optimize    = 1;
Mesh.OptimizeNetgen = 1;

// --- output ---
Mesh.ScalingFactor  = 0.001;      // mm -> m
Mesh.MshFileVersion = 2.2;        // format read by gmshToFoam

// --- boundary patches (CAD face tags from the STEP file) ---
symX()        = {9, 10, 43, 44};  // cut plane x = 0
symZ()        = {7, 8, 42};       // cut plane z = 0
plateTop()    = {35};             // top face of upper plate (y = 28.1)
plateBottom() = {179};            // bottom face of lower plate (y = 0)
motorPad()    = {203};            // top face of the motor pad (motor seat)
free() = Surface{:};
free() -= symX(); free() -= symZ(); free() -= plateTop();
free() -= plateBottom(); free() -= motorPad();

Physical Surface("symX")        = symX();
Physical Surface("symZ")        = symZ();
Physical Surface("plateTop")    = plateTop();
Physical Surface("plateBottom") = plateBottom();
Physical Surface("motorPad")    = motorPad();
Physical Surface("free")        = free();
Physical Volume("frame")        = Volume{:};
