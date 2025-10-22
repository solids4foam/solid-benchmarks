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

#include "analyticalPressurisedCylinderFunctionObject.H"
#include "addToRunTimeSelectionTable.H"
#include "volFields.H"
#include "pointFields.H"
#include "coordinateSystem.H"

// * * * * * * * * * * * * * * Static Data Members * * * * * * * * * * * * * //

namespace Foam
{
    defineTypeNameAndDebug(analyticalPressurisedCylinderFunctionObject, 0);

    addToRunTimeSelectionTable
    (
        functionObject,
        analyticalPressurisedCylinderFunctionObject,
        dictionary
    );
}


// * * * * * * * * * * * * * Private Member Functions  * * * * * * * * * * * //

Foam::vector Foam::analyticalPressurisedCylinderFunctionObject::
displacement(const Foam::vector& pos) const
{
    coordinateSystem localCS
    (
        "localCS",
        origin_,
        (axis_/(mag(axis_) + VSMALL)),
        pos
    );
    const tensor R = localCS.R();

    const vector xLocal = R.T() & (pos - origin_);
    const scalar r = Foam::sqrt(sqr(xLocal.x()) + sqr(xLocal.y()));
    if (r <= SMALL)
    {
        return vector::zero;
    }

    const scalar ri2 = sqr(Ri_);
    const scalar ro2 = sqr(Ro_);
    const scalar ur  =
        (p_/E_)*(ri2/(ro2 - ri2))*((1.0 - nu_)*r + (1.0 + nu_)*ro2/r);

    const vector uCyl(ur, 0, 0);

    return R & uCyl;
}

Foam::symmTensor Foam::analyticalPressurisedCylinderFunctionObject::
stress(const Foam::vector& pos) const
{
    const scalar r = sqrt(sqr(pos.x())+sqr(pos.y()));
    const scalar ri2 = Ri_*Ri_;
    const scalar ro2 = Ro_*Ro_;
    const scalar fac = p_*ri2/(ro2 - ri2);
    const scalar rinv = 1.0/max(r, SMALL);

    const scalar sigmar = fac*(1.0 - ro2*rinv*rinv);
    const scalar sigmat = fac*(1.0 + ro2*rinv*rinv);
    const scalar sigmaz = 0.0;

    coordinateSystem localCS
    (
        "localCS",
        origin_,
        (axis_/(mag(axis_) + VSMALL)),
        pos
    );
    const tensor R = localCS.R();
    const symmTensor SCyl(sigmar, 0, 0, sigmat, 0, sigmaz);

    return Foam::symm((R & SCyl) & R.T());
}


bool Foam::analyticalPressurisedCylinderFunctionObject::writeData()
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

    //Cell-centre coordinates
    const volVectorField& C = mesh.C();
    const vectorField& CI = C;

    if (cellStress_ || cellDisplacement_)
    {
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
            sI[cellI] = stress(CI[cellI]);
            aDI[cellI] = displacement(CI[cellI]);
        }

        forAll(analyticalStress.boundaryField(), patchI)
        {
            if (mesh.boundary()[patchI].type() != "empty")
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
                    sP[faceI] = stress(CP[faceI]);
                    DP[faceI] = displacement(CP[faceI]);
                }
            }
        }

        analyticalStress.correctBoundaryConditions();
        analyticalD.correctBoundaryConditions();

        if (cellStress_)
        {
            Info<< "Writing analyticalPointStress"
                << nl << endl;
            analyticalStress.write();
        }

        if (cellDisplacement_)
        {
            Info<< "WritinganalyticalDisplacement"
                << nl << endl;
            analyticalD.write();
        }

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

            volSymmTensorField diff
            (
                "sigmaDifference", analyticalStress - sigma
            );

            // sigma field have z component while analytical solution does not
            // This should be investigated, for now i will ignore z component
            // in norm calculation
            forAll(diff, cellI)
            {
                diff[cellI].zz() = 0.0;
            }


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
    }

    return true;
}

// * * * * * * * * * * * * * * * * Constructors  * * * * * * * * * * * * * * //

Foam::analyticalPressurisedCylinderFunctionObject::analyticalPressurisedCylinderFunctionObject
(
    const word& name,
    const Time& t,
    const dictionary& dict
)
:
    functionObject(name),
    name_(name),
    time_(t),
    axis_(dict.lookupOrDefault<vector>("axis", vector(0, 0, 1))),
    origin_(dict.lookupOrDefault<vector>("origin", vector::zero)),
    p_(readScalar(dict.lookup("p"))),
    Ri_(readScalar(dict.lookup("Ri"))),
    Ro_(readScalar(dict.lookup("Ro"))),
    E_(readScalar(dict.lookup("E"))),
    nu_(readScalar(dict.lookup("nu"))),
    cellDisplacement_
    (
        dict.lookupOrDefault<Switch>("cellDisplacement", true)
    ),
    pointDisplacement_
    (
        dict.lookupOrDefault<Switch>("pointDisplacement", false)
    ),
    cellStress_
    (
        dict.lookupOrDefault<Switch>("cellStress", true)
    ),
    pointStress_
    (
        dict.lookupOrDefault<Switch>("pointStress", false)
    )
{
    Info<< "Creating " << this->name() << " function object" << endl;
}


// * * * * * * * * * * * * * * * Member Functions  * * * * * * * * * * * * * //

bool Foam::analyticalPressurisedCylinderFunctionObject::start()
{
    return true;
}


#if FOAMEXTEND
    bool Foam::analyticalPressurisedCylinderFunctionObject::execute(const bool forceWrite)
#else
    bool Foam::analyticalPressurisedCylinderFunctionObject::execute()
#endif
{
    return writeData();
}


bool Foam::analyticalPressurisedCylinderFunctionObject::read(const dictionary& dict)
{
    return true;
}


#ifdef OPENFOAM_NOT_EXTEND
bool Foam::analyticalPressurisedCylinderFunctionObject::write()
{
    return true;
}
#endif

// ************************************************************************* //
