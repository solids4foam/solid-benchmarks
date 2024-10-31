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
    extractNarrowTmemberResults

Description
    Extract results for the narrowTmember case, defined in Cardiff, et al.
    2016, A Block-Coupled Finite Volume Methodology for Linear Elasticity and
    Unstructured Meshes, Computers & Structures,
    10.1016/j.compstruc.2016.07.004.

Author
    Philip Cardiff, UCD.

\*---------------------------------------------------------------------------*/

#include "fvCFD.H"
#include "argList.H"
#include "pointFields.H"
#include "meshSearch.H"
#include "volPointInterpolation.H"

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
    //mesh.readUpdate();

    // Read the equivalent (von Mises) stress field
    const volScalarField sigmaEq
    (
        IOobject
        (
            "sigmaEq",
            runTime.timeName(),
            mesh,
            IOobject::MUST_READ,
            IOobject::NO_WRITE
        ),
        mesh
    );

    // Define points on the line r = 1.5R, z = 0.3 m
    // We will uniformly sample the angle (theta) from -pi/2 (x = 0, y < 0) to
    // pi (y = 0, x < 0) in the anti-clockwise direction
    const label NUM_SAMPLES = 30;
    scalarField theta(NUM_SAMPLES, 0);
    const scalar thetaMax = constant::mathematical::pi;
    const scalar thetaMin = -0.5*constant::mathematical::pi;
    const scalar thetaStep = (thetaMax - thetaMin)/(theta.size() - 1);
    for(int i = 0; i < theta.size(); ++i)
    {
        theta[i] = thetaMin + i*thetaStep;
    }
    // Perturb the end points away from the boundary so the mesh search suceeds
    theta[0] += SMALL;
    theta[theta.size() - 1] -= SMALL;
    Info<< nl << "theta = " << theta << endl;

    // Calculate the Cartesian coordinates of the points
    // We set the z coordinate to SMALL to perturb it away from the boundary
    vectorField sampleLine(theta.size(), vector::zero);
    const scalar R = 0.005;
    const scalar r = 1.5*R;
    forAll(sampleLine, pI)
    {
        sampleLine[pI] =
            vector(r*Foam::cos(theta[pI]), r*Foam::sin(theta[pI]), SMALL);
    }
    Info<< nl << "sampleLine = " << sampleLine << endl; 

    // Find the cells containing the sampleLine points
    meshSearch searchEngine(mesh);
    labelList sampleLineCellIDs(sampleLine.size(), -1);
    label seedCellID = -1;
    forAll(sampleLineCellIDs, I)
    {
        sampleLineCellIDs[I] = searchEngine.findCell(sampleLine[I], seedCellID);
        if (sampleLineCellIDs[I] == -1)
        {
            // Global search, in case the local one fails
            sampleLineCellIDs[I] = searchEngine.findCell(sampleLine[I]);
        }
        seedCellID = sampleLineCellIDs[I];
    }
    // Info<< "sampleLineCellIDs = " << sampleLineCellIDs << endl;
    if (min(sampleLineCellIDs) == -1)
    {
        FatalError
            << "Could not find cells on the sample line. sampleLineCellIDs = "
            << sampleLineCellIDs << abort(FatalError);
    }

    bool approach1 = true;
    scalarField sampleLineSigmaEq(sampleLineCellIDs.size(), 0.0);
    if (approach1)
    {
        // Determine sigmaEq of the sampleLine points
        // We have many options for this interpolation: let's extrapolate from the
        // cell centre using the sigmaEq gradient and see if it's good enough.
        const volVectorField gradSigmaEq(fvc::grad(sigmaEq));
        const scalarField& sigmaEqI = sigmaEq;
        const vectorField& CI = mesh.C();
        const vectorField& gradSigmaEqI = gradSigmaEq;
        forAll(sampleLineCellIDs, cI)
        {
            const label cellID = sampleLineCellIDs[cI];
            const vector d = sampleLine[cI] - CI[cellID];
            sampleLineSigmaEq[cI] = sigmaEqI[cellID] + (d & gradSigmaEqI[cellID]);
        }
        // Info<< "sampleLineSigmaEq = " << sampleLineSigmaEq << endl;
    }
    else
    {
        // Interpolate gradSigmaEq to the points
        // Then extrapolate from the points in each cell and take a
        // distance-weighted average
        volPointInterpolation interp(mesh);
        const volVectorField gradSigmaEq(fvc::grad(sigmaEq));
        const pointVectorField pGradSigmaEq(interp.interpolate(gradSigmaEq));
        const pointScalarField pSigmaEq(interp.interpolate(sigmaEq));
        // const vectorField& pGradSigmaEqI = pGradSigmaEq;
        const vectorField& gradSigmaEqI = gradSigmaEq;
        const scalarField& pSigmaEqI = pSigmaEq;
        const pointField& points = mesh.points();
        const labelListList& cellPoints = mesh.cellPoints();
        forAll(sampleLineCellIDs, cI)
        {
            const label cellID = sampleLineCellIDs[cI];
            const labelList& curCellPoints = cellPoints[cellID];
            scalar sumW = 0;
            forAll(curCellPoints, cpI)
            {
                const label pointID = curCellPoints[cpI];
                const vector d = sampleLine[cI] - points[pointID];
                //const scalar w = 1;
                const scalar w = 1/mag(d);
                //const scalar w = 1/magSqr(d);
                sumW += w;
                sampleLineSigmaEq[cI] =
                    // w*(pSigmaEqI[pointID] + (d & pGradSigmaEqI[pointID]));
                    w*(pSigmaEqI[pointID] + (d & gradSigmaEqI[cellID]));
            }
            sampleLineSigmaEq[cI] /= sumW;
        }
    }

    // Write the sampleLine to a file
    OFstream outFile("sampleLineSigmaEq.txt");
    Info<< nl
        << "Writing the sigmaEq values along the sample line "
        << "(r = 1.5R, z = 0 m) to sampleLineSigmaEq.txt"
        << endl;
    outFile
        << "# theta x y z sigmaEq" << endl;
    forAll(sampleLine, cI)
    {
        outFile
            << theta[cI] << " "
            << sampleLine[cI].x() << " "
            << sampleLine[cI].y() << " "
            << sampleLine[cI].z() << " "
            << sampleLineSigmaEq[cI] << endl;
    }

    Info<< nl << "End" << nl << endl;

    return(0);
}


// ************************************************************************* //
