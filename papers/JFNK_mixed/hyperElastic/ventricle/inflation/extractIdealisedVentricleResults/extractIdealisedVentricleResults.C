/*---------------------------------------------------------------------------*\
License
    This file is part of solids4foam.

    solids4foam is free software: you can redistribute it and/or modify it
    under the terms of the GNU General Public License as published by the
    Free Software Foundation, either version 3 of the License, or (at your
    option) any later version.

    solids4foam is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with solids4foam.  If not, see <http://www.gnu.org/licenses/>.

Application
    extractIdealisedVentricleResults

Description
    Extrac results for the idealised ventricle case, defined as problem 2 in
    Land et al., 2015, Verification of cardiac mechanics software: benchmark
    problems and solutions for testing active and passive material behaviour,
    Proc. R. Soc. A.47120150641, http://doi.org/10.1098/rspa.2015.0641.

Author
    Philip Cardiff, UCD.

\*---------------------------------------------------------------------------*/

#include "fvCFD.H"
#include "argList.H"
#include "pointFields.H"
#include "meshSearch.H"
#include "interpolationCellPoint.H"

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //

using namespace Foam;

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //

int main(int argc, char *argv[])
{
#   include "setRootCase.H"
#   include "createTime.H"
#   include "createMesh.H"

    argList::noParallel();

    // Get times list
    const instantList Times = runTime.times();

    // Go to the latest time step
    runTime.setTime(Times[Times.size() - 1], Times.size() - 1);
    Info<< "Time = " << runTime.timeName() << nl << endl;

    // Re-read the mesh, if needed
    // Assume total Lagrangian approach so the mesh does not move
    //mesh.readUpdate();

    // Read the displacement field
    const volVectorField D
    (
        IOobject
        (
            "D",
            runTime.timeName(),
            mesh,
            IOobject::MUST_READ,
            IOobject::NO_WRITE
        ),
        mesh
    );

    // Read the point displacement field
    pointMesh pMesh(mesh);
    const pointVectorField pointD
    (
        IOobject
        (
            "pointD",
            runTime.timeName(),
            mesh,
            IOobject::MUST_READ,
            IOobject::NO_WRITE
        ),
        pMesh
    );

    // Calculate the deformed mesh points
    const pointField deformedPoints(mesh.points() + pointD);

    // Find the apex position (most negative z) on the endocardial (inside) and
    // epicardial (outside) surfaces
    const label insidePatchID = mesh.boundaryMesh().findPatchID("inside");
    if (insidePatchID == -1)
    {
        FatalError
            << "Cannot find the 'inside' patch" << abort(FatalError);
    }
    const label outsidePatchID = mesh.boundaryMesh().findPatchID("outside");
    if (outsidePatchID == -1)
    {
        FatalError
            << "Cannot find the 'outside' patch" << abort(FatalError);
    }

    // Inside surface apex
    scalar insideApexZ = GREAT;
    const labelList& insideMeshPoints =
        mesh.boundaryMesh()[insidePatchID].meshPoints();
    forAll(insideMeshPoints, pI)
    {
        const label pointID = insideMeshPoints[pI];
        insideApexZ = min(insideApexZ, deformedPoints[pointID].z());
    }

    // Outside surface apex
    scalar outsideApexZ = GREAT;
    const labelList& outsideMeshPoints =
        mesh.boundaryMesh()[outsidePatchID].meshPoints();
    forAll(outsideMeshPoints, pI)
    {
        const label pointID = outsideMeshPoints[pI];
        outsideApexZ = min(outsideApexZ, deformedPoints[pointID].z());
    }

    Info<< nl
        << "Apex:" << nl
        << "    inside = " << insideApexZ << nl
        << "    outside = " << outsideApexZ << endl;

    // Define the middle-wall dimensions from Land et al. benchmark problem 2
    const scalar rs = 0.5*(0.007 + 0.010);
    const scalar rl = 0.5*(0.017 + 0.020);
    const scalar zBase = 0.005;
    const scalar zBaseOverRl = zBase/rl;
    if (!(zBaseOverRl > -1.0 && zBaseOverRl < 1.0))
    {
        FatalError
            << "Invalid middle-wall base ratio zBase/rl = "
            << zBaseOverRl << nl
            << "The ratio must be greater than -1 and less than 1 before "
            << "calling acos(). zBase = " << zBase << ", rl = " << rl
            << abort(FatalError);
    }

    // Define uniformly-sampled u field
    const label NUM_SAMPLES = 100;
    scalarField u(NUM_SAMPLES, 0);
    const scalar uMin = -constant::mathematical::pi;
    const scalar uMax = -Foam::acos(zBaseOverRl);
    const scalar uStep = (uMax - uMin)/(u.size() - 1);
    forAll(u, i)
    {
        u[i] = uMin + i*uStep;
    }
    // Info<< nl << "u = " << u << endl;

    // Define undeformed coordinates along the mid-line (t = 0.5)
    vectorField midLine(u.size(), vector::zero);
    forAll(midLine, pI)
    {
        midLine[pI] = vector(rs*Foam::sin(u[pI]), 0, rl*Foam::cos(u[pI]));
    }
    // Info<< nl << "midLine (undeformed) = " << midLine << endl;

    const label fixedPatchID = mesh.boundaryMesh().findPatchID("fixed");
    if (fixedPatchID == -1)
    {
        FatalError
            << "Cannot find the fixed base patch named 'fixed'"
            << abort(FatalError);
    }

    const fvPatchVectorField& fixedBaseD = D.boundaryField()[fixedPatchID];
    scalar maxFixedBaseDisp = 0.0;
    forAll(fixedBaseD, faceI)
    {
        maxFixedBaseDisp = max(maxFixedBaseDisp, mag(fixedBaseD[faceI]));
    }

    if (!fixedBaseD.fixesValue() || maxFixedBaseDisp > SMALL)
    {
        FatalError
            << "The exact base endpoint can only be assigned zero "
            << "displacement after confirming a fixed zero displacement "
            << "condition on the 'fixed' patch." << nl
            << "Patch type = " << fixedBaseD.type()
            << ", fixesValue = " << fixedBaseD.fixesValue()
            << ", max(|D|) = " << maxFixedBaseDisp
            << abort(FatalError);
    }

    // Find the cells containing the midLine points
    meshSearch searchEngine(mesh);
    labelList midLineCellIDs(midLine.size(), -1);
    label seedCellID = -1;
    label failedFindCellCalls = 0;
    label interiorFailedFindCellCalls = 0;
    bool baseEndpointSpecialHandling = false;
    scalar baseEndpointSearchInset = 0.0;

    const label basePointI = midLineCellIDs.size() - 1;
    for(label I = 0; I < basePointI; ++I)
    {
        midLineCellIDs[I] = searchEngine.findCell(midLine[I], seedCellID);
        //midLineCellIDs[I] = searchEngine.findNearestCell(midLine[I]);
        //midLineCellIDs[I] =
        //    searchEngine.findNearestCell(midLine[I], seedCellID);

        if (midLineCellIDs[I] == -1)
        {
            ++failedFindCellCalls;
            ++interiorFailedFindCellCalls;
        }
        else
        {
            seedCellID = midLineCellIDs[I];
        }
    }

    if (interiorFailedFindCellCalls)
    {
        FatalError
            << "Could not find containing cells for "
            << interiorFailedFindCellCalls
            << " non-base midline sample(s)" << abort(FatalError);
    }

    // The exact final middle-wall point lies on the fixed base boundary.  Some
    // mesh-search implementations report no containing cell for such boundary
    // points, so try the exact point first, then search at an extremely small
    // inward z-offset only to obtain an interpolation cell.  The physical
    // deformed endpoint is still written exactly at the fixed base with zero
    // displacement, after the fixed zero displacement condition is checked
    // above.
    midLineCellIDs[basePointI] =
        searchEngine.findCell(midLine[basePointI], seedCellID);
    if (midLineCellIDs[basePointI] == -1)
    {
        ++failedFindCellCalls;
        baseEndpointSpecialHandling = true;

        scalar baseInset = 1e-10*rl;
        for(label attempt = 0; attempt < 4; ++attempt)
        {
            const vector baseSearchPoint =
                midLine[basePointI] - vector(0, 0, baseInset);

            midLineCellIDs[basePointI] =
                searchEngine.findCell(baseSearchPoint, seedCellID);

            if (midLineCellIDs[basePointI] != -1)
            {
                baseEndpointSearchInset = baseInset;
                break;
            }

            ++failedFindCellCalls;
            baseInset *= 10.0;
        }
    }

    if (midLineCellIDs[basePointI] == -1)
    {
        FatalError
            << "Could not find an interpolation cell for the exact fixed "
            << "base endpoint or for a small inward z-offset"
            << abort(FatalError);
    }
    seedCellID = midLineCellIDs[basePointI];
    // Info<< "midLineCellIDs = " << midLineCellIDs << endl;

    // Determine the displacement of the midLine points with the continuous
    // cell-point interpolator.  Also preserve the original one-cell Taylor
    // reconstruction for comparison.
    interpolationCellPoint<vector> interpD(D);
    const volTensorField gradD(fvc::grad(D));
    const vectorField& DI = D;
    const vectorField& CI = mesh.C();
    const tensorField& gradDI = gradD;
    vectorField midLineDispCellPoint(midLineCellIDs.size(), vector::zero);
    vectorField midLineCoordCellPoint(midLineCellIDs.size(), vector::zero);
    vectorField midLineDispTaylor(midLineCellIDs.size(), vector::zero);
    vectorField midLineCoordTaylor(midLineCellIDs.size(), vector::zero);
    scalarField displacementDifference(midLineCellIDs.size(), 0.0);
    scalarField coordinateDifference(midLineCellIDs.size(), 0.0);

    forAll(midLineCellIDs, cI)
    {
        const label cellID = midLineCellIDs[cI];

        if (cI == basePointI)
        {
            midLineDispCellPoint[cI] = vector::zero;
            midLineDispTaylor[cI] = vector::zero;
        }
        else
        {
            midLineDispCellPoint[cI] =
                interpD.interpolate(midLine[cI], cellID);

            const vector d = midLine[cI] - CI[cellID];
            midLineDispTaylor[cI] = DI[cellID] + (d & gradDI[cellID]);
        }

        midLineCoordCellPoint[cI] =
            midLine[cI] + midLineDispCellPoint[cI];
        midLineCoordTaylor[cI] =
            midLine[cI] + midLineDispTaylor[cI];

        displacementDifference[cI] =
            mag(midLineDispCellPoint[cI] - midLineDispTaylor[cI]);
        coordinateDifference[cI] =
            mag(midLineCoordCellPoint[cI] - midLineCoordTaylor[cI]);
    }
    // Info<< "midLineDispCellPoint = " << midLineDispCellPoint << endl;
    // Info<< "midLineCoordCellPoint = " << midLineCoordCellPoint << endl;
    // Info<< "midLineDispTaylor = " << midLineDispTaylor << endl;
    // Info<< "midLineCoordTaylor = " << midLineCoordTaylor << endl;

    scalar minInterpDiff = GREAT;
    scalar maxInterpDiff = -GREAT;
    scalar meanInterpDiff = 0.0;
    label maxInterpDiffI = -1;
    forAll(displacementDifference, I)
    {
        const scalar diff = displacementDifference[I];
        if (diff < minInterpDiff)
        {
            minInterpDiff = diff;
        }

        if (diff > maxInterpDiff)
        {
            maxInterpDiff = diff;
            maxInterpDiffI = I;
        }

        meanInterpDiff += diff;
    }
    meanInterpDiff /= displacementDifference.size();

    // Write the primary cell-point interpolated midLine to a file
    OFstream outFile("midLineDeformed.txt");
    outFile.precision(16);
    Info<< nl
        << "Writing the cell-point deformed midline coordinates to "
        << "midLineDeformed.txt"
        << endl;
    outFile
        << "# x y z" << endl;
    forAll(midLineCoordCellPoint, cI)
    {
        outFile
            << midLineCoordCellPoint[cI].x() << " "
            << midLineCoordCellPoint[cI].y() << " "
            << midLineCoordCellPoint[cI].z() << endl;
    }

    OFstream taylorOutFile("midLineDeformedTaylor.txt");
    taylorOutFile.precision(16);
    Info<< "Writing the Taylor reconstructed midline coordinates to "
        << "midLineDeformedTaylor.txt"
        << endl;
    taylorOutFile
        << "# x y z" << endl;
    forAll(midLineCoordTaylor, cI)
    {
        taylorOutFile
            << midLineCoordTaylor[cI].x() << " "
            << midLineCoordTaylor[cI].y() << " "
            << midLineCoordTaylor[cI].z() << endl;
    }

    OFstream comparisonOutFile("midLineInterpolationComparison.txt");
    comparisonOutFile.precision(16);
    Info<< "Writing interpolation comparison diagnostics to "
        << "midLineInterpolationComparison.txt"
        << endl;
    comparisonOutFile
        << "# index u cellID Xx Xy Xz "
        << "Dx_cellPoint Dy_cellPoint Dz_cellPoint "
        << "Dx_Taylor Dy_Taylor Dz_Taylor "
        << "x_cellPoint y_cellPoint z_cellPoint "
        << "x_Taylor y_Taylor z_Taylor "
        << "displacementDifference coordinateDifference" << endl;
    forAll(midLine, cI)
    {
        comparisonOutFile
            << cI << " "
            << u[cI] << " "
            << midLineCellIDs[cI] << " "
            << midLine[cI].x() << " "
            << midLine[cI].y() << " "
            << midLine[cI].z() << " "
            << midLineDispCellPoint[cI].x() << " "
            << midLineDispCellPoint[cI].y() << " "
            << midLineDispCellPoint[cI].z() << " "
            << midLineDispTaylor[cI].x() << " "
            << midLineDispTaylor[cI].y() << " "
            << midLineDispTaylor[cI].z() << " "
            << midLineCoordCellPoint[cI].x() << " "
            << midLineCoordCellPoint[cI].y() << " "
            << midLineCoordCellPoint[cI].z() << " "
            << midLineCoordTaylor[cI].x() << " "
            << midLineCoordTaylor[cI].y() << " "
            << midLineCoordTaylor[cI].z() << " "
            << displacementDifference[cI] << " "
            << coordinateDifference[cI] << endl;
    }

    Info<< nl
        << "Midline extraction diagnostics:" << nl
        << "    samples = " << midLine.size() << nl
        << "    rs = " << rs << " m" << nl
        << "    rl = " << rl << " m" << nl
        << "    zBase = " << zBase << " m" << nl
        << "    uMin = " << uMin << nl
        << "    uMax = " << uMax << nl
        << "    first reference coordinate = " << midLine.first() << nl
        << "    final reference coordinate = " << midLine.last() << nl
        << "    final reference z = " << midLine.last().z() << nl
        << "    min interpolation difference = " << minInterpDiff << nl
        << "    max interpolation difference = " << maxInterpDiff << nl
        << "    mean interpolation difference = " << meanInterpDiff << nl
        << "    max difference index = " << maxInterpDiffI << nl
        << "    max difference reference coordinate = "
        << midLine[maxInterpDiffI] << nl
        << "    failed findCell() calls = " << failedFindCellCalls << nl
        << "    fixed base special handling required = "
        << baseEndpointSpecialHandling << nl
        << "    fixed base patch type = " << fixedBaseD.type() << nl
        << "    fixed base max(|D|) = " << maxFixedBaseDisp << nl
        << "    fixed base search inset = " << baseEndpointSearchInset
        << endl;

    Info<< nl << "End" << nl << endl;

    return(0);
}


// ************************************************************************* //
