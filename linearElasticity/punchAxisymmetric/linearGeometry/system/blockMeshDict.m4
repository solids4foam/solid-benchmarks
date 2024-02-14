/*--------------------------------*- C++ -*----------------------------------*\
| solids4foam: solid mechanics and fluid-solid interaction simulations        |
| Version:     v2.0                                                           |
| Web:         https://solids4foam.github.io                                  |
| Disclaimer:  This offering is not approved or endorsed by OpenCFD Limited,  |
|              producer and distributor of the OpenFOAM software via          |
|              www.openfoam.com, and owner of the OPENFOAM® and OpenCFD®      |
|              trade marks.                                                   |
\*---------------------------------------------------------------------------*/
FoamFile
{
    version     2.0;
    format      ascii;
    class       dictionary;
    location    "constant/polyMesh";
    object      blockMeshDict;
}
// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //

// M4
m4_changecom(//)m4_changequote([,])
m4_define(calc, [m4_esyscmd(perl -e 'printf ($1)')])
m4_define(pi, 3.14159265358979323844)
m4_define(rad, [calc($1*pi/180.0)])
m4_define(VCOUNT, 0)
m4_define(vlabel, [[// ]Vertex $1 = VCOUNT m4_define($1, VCOUNT)m4_define([VCOUNT], m4_incr(VCOUNT))])

// GEOMETRY
// "Advanced Finite Element Contact Benchmarks"
// "SSNA122 – Benchmark NAFEMS de validation du contact 2: punch (rounded edges)"

m4_define(angle, 0.5)   // Half of the angle of axisymmetry geometry 
m4_define(Rf, 100)      // Cylinder (cylinder) radius
m4_define(Rb, 50)       // Block (punch) radius
m4_define(Hf, 200)      // Cylinder (cylinder) Height
m4_define(Hb, 100)      // Block (punch) height
m4_define(rb, 10)       // Block (punch) fillet radius

// MESH - Cylinder (cylinder)
m4_define(CylinderX, 30)   // Cylinder refirement zone (nb. of cells in x dir.)
m4_define(CylinderZ, 30)   // Cylinder refirement zone (nb. of cells in z dir.)
m4_define(CylinderZ_, 26)  // Cylinder coarse zone (nb. of cells in z dir.)
m4_define(CylinderX_, 20)  // Cylinder coarse zone (nb. of cells in x dir.) 

// MESH - block (punch)
m4_define(blockX, 20)     // Block refirement zone (nb. of cells in x dir.)
m4_define(blockZ, 12)     // Block refirement zone (nb. of cells in z dir.)
m4_define(blockZ_, 16)    // Block coarse zone (nb. of cells in z dir.)

// MESH - Cylinder (cylinder) gradings
m4_define(fXgrading, 1.5)   // Cylinder coarse zone x grading (to the right of the r.z)
m4_define(fZgrading, 0.15)  // Cylinder coarse zone z grading (lower part of the mesh)

// MESH - block (punch) gradings
m4_define(bZgrading, 3)   // Block veritcal grading of coarse part

// PRELIMINARIES
m4_define(grading, 1 1 1)
m4_define(Hfr, calc(Rb*0.975))          // Cylinder height refirement
m4_define(Rfr, calc(Rb*0.975))          // Cylinder radius refirement
m4_define(sinAngle, calc(sin(rad(angle))))
m4_define(cosAngle, calc(cos(rad(angle))))
m4_define(sin45, calc(sin(rad(45))))
m4_define(sin25, calc(sin(rad(25))))
m4_define(sin65, calc(sin(rad(65))))
m4_define(cos25, calc(cos(rad(25))))
m4_define(cos65, calc(cos(rad(65))))

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //

convertToMeters 0.001;

vertices
(

// Cylinder

    //Plane A (positive angle):
    (0                    0                       0)            vlabel(A0)
    (calc(cosAngle*Rfr)   calc(sinAngle*Rfr)      0)            vlabel(A1)
    (calc(cosAngle*Rf)    calc(sinAngle*Rf)       0)            vlabel(A2)
    (0                    0                       calc(Hf-Hfr)) vlabel(A3)
    (calc(cosAngle*Rfr)   calc(sinAngle*Rfr)      calc(Hf-Hfr)) vlabel(A4)
    (calc(cosAngle*Rf)    calc(sinAngle*Rf)       calc(Hf-Hfr)) vlabel(A5)
    (0                    0                       Hf)           vlabel(A6)
    (calc(cosAngle*Rfr)   calc(sinAngle*Rfr)      Hf)           vlabel(A7)
    (calc(cosAngle*Rf)    calc(sinAngle*Rf)       Hf)           vlabel(A8)

    //Plane B (negative angle):
    (calc(cosAngle*Rfr)   calc(-sinAngle*Rfr)     0)            vlabel(B1)
    (calc(cosAngle*Rf)    calc(-sinAngle*Rf)      0)            vlabel(B2)
    (calc(cosAngle*Rfr)   calc(-sinAngle*Rfr)     calc(Hf-Hfr)) vlabel(B4)
    (calc(cosAngle*Rf)    calc(-sinAngle*Rf)      calc(Hf-Hfr)) vlabel(B5)
    (calc(cosAngle*Rfr)   calc(-sinAngle*Rfr)     Hf)           vlabel(B7)
    (calc(cosAngle*Rf)    calc(-sinAngle*Rf)      Hf)           vlabel(B8)


// Block

    //Plane C = Plane A:
    (0                                  0                                   Hf)                   vlabel(C0)
    (0                                  0                                   calc(Hf+rb/2))        vlabel(C03)
    (calc(cosAngle*(Rb-rb))             calc(sinAngle*(Rb-rb))              Hf)                   vlabel(C1)
    (calc(cosAngle*(Rb-rb+sin45*rb))    calc(sinAngle*(Rb-rb+sin45*rb))     calc(Hf+rb-sin45*rb)) vlabel(C2)
    (0                                  0                                   calc(Hf+rb))          vlabel(C3)
    (calc(cosAngle*(Rb-rb))             calc(sinAngle*(Rb-rb))              calc(Hf+rb))          vlabel(C4)
    (calc(cosAngle*(Rb-rb))             calc(sinAngle*(Rb-rb))              calc(Hf+rb*0.5))      vlabel(C44)
    (calc(cosAngle*(Rb-rb*0.5))         calc(sinAngle*(Rb-rb*0.5))          calc(Hf+rb))          vlabel(C5)
    (calc(cosAngle*(Rb-rb*0.54))         calc(sinAngle*(Rb-rb*0.54))          calc(Hf+rb*0.54))   vlabel(C55)
    (calc(cosAngle*Rb)                  calc(sinAngle*Rb)                   calc(Hf+rb))          vlabel(C6)
    (0                                  0                                   calc(Hf+Hb))          vlabel(C7)
    (calc(cosAngle*(Rb-rb))             calc(sinAngle*(Rb-rb))              calc(Hf+Hb))          vlabel(C8)
    (calc(cosAngle*(Rb-rb+rb*0.5))      calc(sinAngle*(Rb-rb+rb*0.5))       calc(Hf+Hb))          vlabel(C89)
    (calc(cosAngle*Rb)                  calc(sinAngle*Rb)                   calc(Hf+Hb))          vlabel(C9)

    //Plane D = plane B:
    (calc(cosAngle*(Rb-rb))             calc(-sinAngle*(Rb-rb))             Hf)                   vlabel(D1)
    (calc(cosAngle*(Rb-rb+sin45*rb))    calc(-sinAngle*(Rb-rb+sin45*rb))    calc(Hf+rb-sin45*rb)) vlabel(D2)
    (calc(cosAngle*(Rb-rb))             calc(-sinAngle*(Rb-rb))             calc(Hf+rb))          vlabel(D4)
    (calc(cosAngle*(Rb-rb))             calc(-sinAngle*(Rb-rb))             calc(Hf+rb*0.5))      vlabel(D44)
    (calc(cosAngle*(Rb-rb*0.5))         calc(-sinAngle*(Rb-rb*0.5))         calc(Hf+rb))          vlabel(D5)
    (calc(cosAngle*(Rb-rb*0.54))         calc(-sinAngle*(Rb-rb*0.54))         calc(Hf+rb*0.54))   vlabel(D55)
    (calc(cosAngle*Rb)                  calc(-sinAngle*Rb)                  calc(Hf+rb))          vlabel(D6)
    (calc(cosAngle*(Rb-rb))             calc(-sinAngle*(Rb-rb))             calc(Hf+Hb))          vlabel(D8)
    (calc(cosAngle*(Rb-rb+rb*0.5))      calc(-sinAngle*(Rb-rb+rb*0.5))      calc(Hf+Hb))          vlabel(D89)
    (calc(cosAngle*Rb)                  calc(-sinAngle*Rb)                  calc(Hf+Hb))          vlabel(D9)
);

blocks
(
    hex ( A0 A1 A4 A3 A0 B1 B4 A3 ) punch_bottom (CylinderX  CylinderZ_ 1) simpleGrading  (1 fZgrading 1)
    hex ( A3 A4 A7 A6 A3 B4 B7 A6 ) punch_bottom (CylinderX  CylinderZ  1) simpleGrading  (1 1 1)
    hex ( A1 A2 A5 A4 B1 B2 B5 B4 ) punch_bottom (CylinderX_ CylinderZ_ 1) simpleGrading  (fXgrading fZgrading 1)
    hex ( A4 A5 A8 A7 B4 B5 B8 B7 ) punch_bottom (CylinderX_ CylinderZ  1) simpleGrading  (fXgrading 1 1)

    hex ( C0 C1 C44 C03 C0 D1 D44 C03 ) punch_top (blockX calc(blockZ/2) 1)         simpleGrading (grading)
    hex ( C03 C44 C4 C3 C03 D44 D4 C3 ) punch_top (blockX calc(blockZ/2) 1)         simpleGrading (grading)
    hex ( C3 C4 C8 C7 C3 D4 D8 C7 )     punch_top (blockX blockZ_ 1)                simpleGrading (1 bZgrading 1)
    hex ( C4 C5 C89 C8 D4 D5 D89 D8 )   punch_top (calc(blockZ/2) blockZ_ 1 )       simpleGrading (1 bZgrading 1)
    hex ( C5 C6 C9 C89 D5 D6 D9 D89 )   punch_top (calc(blockZ/2) blockZ_ 1 )       simpleGrading (1 bZgrading 1)
    hex ( C44 C55 C5 C4 D44 D55 D5 D4 ) punch_top (calc(blockZ/2) calc(blockZ/2) 1) simpleGrading (grading)
    hex ( C2 C6 C5 C55 D2 D6 D5 D55 )   punch_top (calc(blockZ/2) calc(blockZ/2) 1) simpleGrading (grading)
    hex ( C1 C2 C55 C44 D1 D2 D55 D44 ) punch_top (calc(blockZ/2) calc(blockZ/2) 1) simpleGrading (grading)

);

edges
(
    // Plane A
    arc  C1 C2 (calc(cosAngle*(Rb-rb+sin25*rb))    calc(sinAngle*(Rb-rb+sin25*rb))     calc(Hf-cos25*rb+rb))
    arc  C2 C6 (calc(cosAngle*(Rb-rb+sin65*rb))    calc(sinAngle*(Rb-rb+sin65*rb))     calc(Hf-cos65*rb+rb))

    // Plane B
    arc  D1 D2 (calc(cosAngle*(Rb-rb+sin25*rb))    calc(-sinAngle*(Rb-rb+sin25*rb))     calc(Hf-cos25*rb+rb))
    arc  D2 D6 (calc(cosAngle*(Rb-rb+sin65*rb))    calc(-sinAngle*(Rb-rb+sin65*rb))     calc(Hf-cos65*rb+rb))
);

boundary
(
    front
    {
        type wedge;
        faces
        (
            (A0 A1 A4 A3)
            (A1 A2 A5 A4)
            (A3 A4 A7 A6)
            (A4 A5 A8 A7)
            (C0 C1 C44 C03)
            (C03 C44 C4 C3)
            (C3 C4 C8 C7)
            (C4 C5 C89 C8)
            (C5 C6 C9 C89)
            (C44 C55 C5 C4)
            (C2 C6 C5 C55)
            (C1 C2 C55 C44)
        );
    }

    back
    {
        type wedge;
        faces
        (
            (A0 A3 B4 B1)
            (B1 B4 B5 B2)
            (A3 A6 B7 B4)
            (B7 B8 B5 B4)
            (C0 C03 D44 D1)
            (C03 C3 D4 D44)
            (C3 C7 D8 D4)
            (D4 D8 D89 D5)
            (D5 D89 D9 D6)
            (D44 D4 D5 D55)
            (D55 D5 D6 D2)
            (D1 D44 D55 D2)
        );
    }

    cylinderFixed
    {
        type patch;
        faces
        (
            (A0 B1 A1 A0)
            (A1 B1 B2 A2)
        );
    }

    punchLoading
    {
        type patch;
        faces
        (
            (C7 C8 D8 C7)
            (C8 C89 D89 D8)
            (C89 C9 D9 D89)
        );
    }

    tractionFree
    {
        type patch;
        faces
        (
            (A2 B2 B5 A5)
            (A5 B5 B8 A8)
            (C6 D6 D9 C9)
        );
    }

    cylinderContact
    {
        type patch;
        faces
        (
            (A6 A7 B7 A6)
            (A7 A8 B8 B7)
        );
    }

    punchContact
    {
        type patch;
        faces
        (
            (C0 D1 C1 C0)
            (C1 D1 D2 C2)
            (C2 D2 D6 C6)
        );
    }
);

mergePatchPairs
(
);

// ************************************************************************* //
