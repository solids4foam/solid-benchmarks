/*---------------------------------------------------------------------------*\
  =========                 |
  \\      /  F ield         | OpenFOAM: The Open Source CFD Toolbox
   \\    /   O peration     |
    \\  /    A nd           | Copyright held by original author
     \\/     M anipulation  |
-------------------------------------------------------------------------------
License
    This file is part of OpenFOAM.

    OpenFOAM is free software; you can redistribute it and/or modify it
    under the terms of the GNU General Public License as published by the
    Free Software Foundation; either version 2 of the License, or (at your
    option) any later version.

    OpenFOAM is distributed in the hope that it will be useful, but WITHOUT
    ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
    FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
    for more details.

    You should have received a copy of the GNU General Public License
    along with OpenFOAM; if not, write to the Free Software Foundation,
    Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA

Description
    Project points of the specified patch onto the surface of a sphere.
    The sphere is specified by an origin and radius.

Author
    Philip Cardiff, UCD.

\*---------------------------------------------------------------------------*/

#include "fvCFD.H"
#include "argList.H"
#include "fvMesh.H"
#include "pointMesh.H"
#include "pointFields.H"

using namespace Foam;

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //

int main(int argc, char *argv[])
{
    #include "addOverwriteOption.H"
    argList::noParallel();

    argList::addArgument("patch");
    argList::addArgument("origin");
    argList::addArgument("radius");
    
#   include "setRootCase.H"
    #include "createTime.H"
    #include "createNamedMesh.H"

    // Read arguments
    const word patchName = args.get<word>(1);
    const vector origin = args.get<vector>(2);
    const scalar radius = args.get<scalar>(3);
    const bool overwrite = args.found("overwrite");

    if (radius <= 0)
    {
        FatalErrorIn(args.executable())
            << "radius must be greater than zero"
            << abort(FatalError);
    }

    Info<< "Patch:" << patchName << nl
        << "Origin:" << origin << nl
        << "Radius:" << radius << endl;

    const word oldInstance = mesh.pointsInstance();

    // Get patch
    const label patchID = mesh.boundaryMesh().findPatchID(patchName);
    if (patchID == -1)
    {
        FatalError
            << "Cannot find patch " << patchName
            << abort(FatalError);
    }

    // Calculate the new points
    const vectorField localPoints = mesh.boundaryMesh()[patchID].localPoints();
    const labelList meshPoints = mesh.boundaryMesh()[patchID].meshPoints();
    vectorField newPoints = mesh.points();
    forAll(localPoints, pointi)
    {
        const vector r = localPoints[pointi] - origin;
        const vector rDir = r/mag(r);

        // point projected to the axis
        const vector c = origin + radius*rDir;

        // Set the new point
        newPoints[meshPoints[pointi]] = c;
    }

    // Point motion field for visualisation
    pointMesh pMesh(mesh);
    pointVectorField pointMotion
    (
        IOobject
        (
            "pointMotion",
            runTime.timeName(),
            mesh,
            IOobject::NO_READ,
            IOobject::NO_WRITE
        ),
        pMesh,
        dimensionedVector("zero", dimLength, vector::zero)
    );
    pointMotion.primitiveFieldRef() = newPoints - mesh.points();

    // write mesh to next time step
    if (overwrite)
    {
        mesh.setInstance(oldInstance);
    }
    else
    {
        runTime++;
    }
    mesh.movePoints(newPoints);

    // Increase the write precision
    IOstream::defaultPrecision(max(10u, IOstream::defaultPrecision()));

    // Write the mesh and pointMotion field
    Info<< "Writing mesh and pointMotion field to time "
        << runTime.value() << endl;
    mesh.write();
    pointMotion.write();
    mesh.moving(false);
    //mesh.changing(false);

    // meshPhi does not need to be written
    mesh.setPhi()->writeOpt() = IOobject::NO_WRITE;

    Info << "End\n" << endl;

    return 0;
}


// ************************************************************************* //
