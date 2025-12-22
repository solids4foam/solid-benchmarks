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

\*----------------------------------------------------------------------------*/

#include "manufacturedSolutionFunctionObject.H"
#include "addToRunTimeSelectionTable.H"
#include "volFields.H"
#include "pointFields.H"
#include "coordinateSystem.H"

// * * * * * * * * * * * * * * Static Data Members * * * * * * * * * * * * * //

namespace Foam
{
    defineTypeNameAndDebug(manufacturedSolutionFunctionObject, 0);

    addToRunTimeSelectionTable
    (
        functionObject,
        manufacturedSolutionFunctionObject,
        dictionary
    );
}


// * * * * * * * * * * * * * Private Member Functions  * * * * * * * * * * * //

bool Foam::manufacturedSolutionFunctionObject::writeData()
{
    // Lookup the solid mesh
    const fvMesh* meshPtr = NULL;
    if (time_.foundObject<fvMesh>("solid"))
    {
        meshPtr = &(time_.lookupObject<fvMesh>("solid"));
    }
    else
    {
        meshPtr = &(time_.lookupObject<fvMesh>("region0"));
    }
    const fvMesh& mesh = *meshPtr;

    // Create the MMS object, if needed
    if (!mmsPtr_.valid())
    {
        mmsPtr_.reset(new manufacturedSolution(mesh, dict_));
    }

    //Cell-centre coordinates
    const volVectorField& C = mesh.C();
    const vectorField& CI = C;

    volSymmTensorField analyticalStress
    (
        IOobject
        (
            "analyticalCellStress",
            time_.timeName(),
            mesh,
            IOobject::NO_READ,
            IOobject::AUTO_WRITE
        ),
        mesh,
        dimensionedSymmTensor("zero", dimPressure, symmTensor::zero),
        "calculated"
    );

    volVectorField analyticalD
    (
        IOobject
        (
            "analyticalD",
            time_.timeName(),
            mesh,
            IOobject::NO_READ,
            IOobject::AUTO_WRITE
        ),
        mesh,
        dimensionedVector("zero", dimLength, vector::zero)
    );

    symmTensorField& sI = analyticalStress;
    vectorField& aDI = analyticalD;

    forAll(sI, cellI)
    {
        sI[cellI] = mmsPtr_->calculateStress(CI[cellI]);
        aDI[cellI] = mmsPtr_->calculateDisplacement(CI[cellI]);
    }

    forAll(analyticalStress.boundaryField(), patchI)
    {
#ifdef OPENFOAM_NOT_EXTEND
	symmTensorField& sP = analyticalStress.boundaryFieldRef()[patchI];
        vectorField& DP = analyticalD.boundaryFieldRef()[patchI];
#else
        symmTensorField& sP = analyticalStress.boundaryField()[patchI];
        vectorField& DP = analyticalD.boundaryField()[patchI];
#endif
        const vectorField& CP = C.boundaryField()[patchI];

        forAll(sP, faceI)
        {
            sP[faceI] = mmsPtr_->calculateStress(CP[faceI]);
            DP[faceI] = mmsPtr_->calculateDisplacement(CP[faceI]);
        }
    }

    analyticalStress.correctBoundaryConditions();
    analyticalD.correctBoundaryConditions();


    Info<< "Writing analyticalStress" << nl << endl;
    analyticalStress.write();

    Info<< "Writing analyticalDisplacement" << nl << endl;
    analyticalD.write();

    if
    (
        cellDisplacement_
     && mesh.foundObject<volVectorField>("D")
    )
    {
        const volVectorField& D =
            mesh.lookupObject<volVectorField>("D");

        const volVectorField diff
        (
            "DDifference", analyticalD - D
        );
        Info<< "Writing DDifference field" << endl;
        diff.write();

        const vectorField& diffI = diff;
        Info<< "    Displacement error norms: mean L1, mean L2, LInf: " << nl
            << "    Magnitude: " << gAverage(mag(diffI))
            << " " << Foam::sqrt(gAverage(magSqr(diffI)))
            << " " << gMax(mag(diffI))
            << endl;
        for (int cmptI = 0; cmptI < 3; cmptI++)
        {
            Info<< "    " << cmptI << " "
                << gAverage(mag(diffI.component(cmptI)))
                << " " << Foam::sqrt(gAverage(magSqr(diffI.component(cmptI))))
                << " " << gMax(mag(diffI.component(cmptI)))
                << endl;
        }
    }

    if
    (
        cellStress_
     && mesh.foundObject<volSymmTensorField>("sigma")
    )
    {
        const volSymmTensorField& sigma =
            mesh.lookupObject<volSymmTensorField>("sigma");

        const volSymmTensorField diff
        (
            "sigmaDifference", analyticalStress - sigma
        );
        Info<< "Writing sigmaDifference field" << endl;
        diff.write();

        const symmTensorField& diffI = diff;
        Info<< "    Stress error norms: mean L1, mean L2, LInf: " << nl
            << "    Magnitude: " << gAverage(mag(diffI))
            << " " << Foam::sqrt(gAverage(magSqr(diffI)))
            << " " << gMax(mag(diffI))
            << endl;
        for (int cmptI = 0; cmptI < 6; cmptI++)
        {
            Info<< "    " << cmptI << " "
                << gAverage(mag(diffI.component(cmptI)))
                << " " << Foam::sqrt(gAverage(magSqr(diffI.component(cmptI))))
                << " " << gMax(mag(diffI.component(cmptI)))
                << endl;
        }
    }

    return true;
}

// * * * * * * * * * * * * * * * * Constructors  * * * * * * * * * * * * * * //

Foam::manufacturedSolutionFunctionObject::manufacturedSolutionFunctionObject
(
    const word& name,
    const Time& t,
    const dictionary& dict
)
:
    functionObject(name),
    name_(name),
    time_(t),
    mmsPtr_(),
    dict_(dict),
    cellDisplacement_
    (
        dict.lookupOrDefault<Switch>("cellDisplacement", true)
    ),
    cellStress_
    (
        dict.lookupOrDefault<Switch>("cellStress", true)
    )
{
    Info<< "Creating " << this->name() << " function object" << endl;
}


// * * * * * * * * * * * * * * * Member Functions  * * * * * * * * * * * * * //

bool Foam::manufacturedSolutionFunctionObject::start()
{
    return true;
}


#if FOAMEXTEND
    bool Foam::manufacturedSolutionFunctionObject::execute(const bool forceWrite)
#else
    bool Foam::manufacturedSolutionFunctionObject::execute()
#endif
{
    return writeData();
}


bool Foam::manufacturedSolutionFunctionObject::read(const dictionary& dict)
{
    return true;
}


#ifdef OPENFOAM_NOT_EXTEND
bool Foam::manufacturedSolutionFunctionObject::write()
{
    return true;
}
#endif

// ************************************************************************* //
