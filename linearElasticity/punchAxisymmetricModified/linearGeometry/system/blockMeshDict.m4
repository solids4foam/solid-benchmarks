/*--------------------------------*- C++ -*----------------------------------*\
| =========                 |                                                 |
| \\      /  F ield         | OpenFOAM Extend Project: Open Source CFD        |
|  \\    /   O peration     | Version:  1.6-ext                               |
|   \\  /    A nd           | Web:      www.extend-project.de                 |
|    \\/     M anipulation  |                                                 |
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
m4_define(angle, 0.5)   // Half of the angle of axisymmetry geometry 

m4_define(b, 10)         // Punch contact flat part
m4_define(Rb, 50)        // Punch overall radius

m4_define(h, 15)         // Punch refirement height
m4_define(Hb, 100)       // Punch height
m4_define(fillet, 100)   // Punch fillet

m4_define(Rf, 100)       // Cylinder radius
m4_define(Hf, 200)       // Cylinder Height


// MESH - Cylinder
m4_define(CylinderX,  30)   // Cylinder refirement zone (nb. of cells in x dir.) 
m4_define(CylinderZ,  20)   // Cylinder refirement zone (nb. of cells in z dir.)
m4_define(CylinderZ_, 20)   // Cylinder coarse zone (nb. of cells in z dir.) 
m4_define(CylinderX_, 15)   // Cylinder coarse zone (nb. of cells in x dir.) 

// MESH - block
m4_define(punchX, 20)           // Punch refirement zone (nb. of cells in x dir.)
m4_define(punchXR, 30)          // Punch fillet zone (nb. of cells in x dir.)
m4_define(punchZ, 25)           // Punch refirement zone (nb. of cells in z dir.)
m4_define(punchZ_, 20)          // Punch coarse zone (nb. of cells in z dir.)
m4_define(punchXgradingR, 12)   // Punch x grading of fillet
m4_define(punchXgrading, 0.35)  // Punch x grading of flat part
m4_define(punchZgrading, 30)    // Punch z grading of corase zone

// MESH - Cylinder gradings
m4_define(fXgrading, 20)       // Cylinder coarse zone x grading (to the right of the r.z)
m4_define(fZgrading, 0.0125)   // Cylinder coarse zone z grading (lower part of the mesh)

// PRELIMINARIES
m4_define(grading, 1 1 1)
m4_define(Hfr, calc(Rb*0.2))                 // Cylinder height refirement
m4_define(Rfr, calc(Rb*0.35))                // Cylinder radius refirement
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


// Punch (positive and negative angle are mixed)


    (0                                  0      Hf)                                          vlabel(C0)
    (calc(cosAngle*b)     calc(sinAngle*b)     Hf)                                          vlabel(C1)
    (calc(cosAngle*b)     calc(-sinAngle*b)    Hf)                                          vlabel(D1)
    (calc(cosAngle*b)     calc(sinAngle*b)     calc(Hf+h))                                  vlabel(C44)
    (calc(cosAngle*b)     calc(-sinAngle*b)    calc(Hf+h))                                  vlabel(D44)
    (0                    0                    calc(Hf+h))                                  vlabel(C03)
    (calc(cosAngle*Rb)    calc(sinAngle*Rb)    calc(Hf+fillet-(fillet**2-(Rb-b)**2)**0.5))  vlabel(C2)
    (calc(cosAngle*Rb)    calc(-sinAngle*Rb)   calc(Hf+fillet-(fillet**2-(Rb-b)**2)**0.5))  vlabel(D2)
    (calc(cosAngle*Rb)    calc(sinAngle*Rb)    calc(Hf+h))                                  vlabel(C55)
    (calc(cosAngle*Rb)    calc(-sinAngle*Rb)   calc(Hf+h))                                  vlabel(D55)
    (0                    0                    calc(Hf+Hb))                                 vlabel(C04)
    (calc(cosAngle*b)     calc(sinAngle*b)     calc(Hf+Hb))                                 vlabel(C66)
    (calc(cosAngle*b)     calc(-sinAngle*b)    calc(Hf+Hb))                                 vlabel(D66)
    (calc(cosAngle*Rb)    calc(sinAngle*Rb)    calc(Hf+Hb))                                 vlabel(C77)
    (calc(cosAngle*Rb)    calc(-sinAngle*Rb)   calc(Hf+Hb))                                 vlabel(D77)




);

blocks
(
    hex ( A0 A1 A4 A3 A0 B1 B4 A3 ) Cylinder (CylinderX  CylinderZ_ 1) simpleGrading  (1 fZgrading 1)
    hex ( A3 A4 A7 A6 A3 B4 B7 A6 ) Cylinder (CylinderX  CylinderZ  1) simpleGrading  (1 1 1)
    hex ( A1 A2 A5 A4 B1 B2 B5 B4 ) Cylinder (CylinderX_ CylinderZ_ 1) simpleGrading  (fXgrading fZgrading 1)
    hex ( A4 A5 A8 A7 B4 B5 B8 B7 ) Cylinder (CylinderX_ CylinderZ  1) simpleGrading  (fXgrading 1 1)

    hex ( C0 C1 C44 C03 C0 D1 D44 C03 ) punch (punchX punchZ 1) simpleGrading (punchXgrading 1 1) 
    hex ( C03 C44  C66 C04 C03 D44 D66 C04 ) punch (punchX punchZ_ 1) simpleGrading (punchXgrading punchZgrading 1)
    hex ( C1 C2 C55 C44 D1 D2 D55 D44 ) punch (punchXR punchZ 1) simpleGrading (punchXgradingR 1 1)
    hex ( C44 C55 C77 C66 D44 D55 D77 D66 ) punch (punchXR punchZ_ 1) simpleGrading (punchXgradingR punchZgrading 1)
);

edges
(
    // Plane A
    arc  C1 C2 (calc(cosAngle*(0.5*(b+Rb)))    calc(sinAngle*(0.5*(b+Rb)))     calc(Hf+fillet-(fillet**2-(0.5*(Rb-b))**2)**0.5))

    // Plane B
    arc  D1 D2 (calc(cosAngle*(0.5*(b+Rb)))    calc(-sinAngle*(0.5*(b+Rb)))     calc(Hf+fillet-(fillet**2-(0.5*(Rb-b))**2)**0.5))
);

boundary
(

    front
    {
        type wedge;
        faces
        (
            (C0 C1 C44 C03)
            (C1 C2 C55 C44)
            (C03 C44 C66 C04)
            (C44 C55 C77 C66)
            (A0 A1 A4 A3)
            (A1 A2 A5 A4)
            (A3 A4 A7 A6)
            (A4 A5 A8 A7)
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
            (C03 C04 D66 D44)
            (D44 D66 D77 D55)
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
            (D66 C66 C04 C04)
            (D66 D77 C77 C66)
        );
    }

    tractionFree
    {
        type patch;
        faces
        (
            (A2 B2 B5 A5)
            (A5 B5 B8 A8)
            (C2 D2 D55 C55)
            (D55 D77 C77 C55)
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
        );
    }

);

mergePatchPairs
(
);

// ************************************************************************* //
