/*---------------------------------------------------------------------------*\
  =========                 |
  \\      /  F ield         | OpenFOAM: The Open Source CFD Toolbox
   \\    /   O peration     |
    \\  /    A nd           | www.openfoam.com
     \\/     M anipulation  |
-------------------------------------------------------------------------------
    Copyright (C) 2015-2017 OpenFOAM Foundation
    Copyright (C) 2018-2021 OpenCFD Ltd.
-------------------------------------------------------------------------------
License
    This file is part of OpenFOAM.

    OpenFOAM is free software: you can redistribute it and/or modify it
    under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    OpenFOAM is distributed in the hope that it will be useful, but WITHOUT
    ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
    FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
    for more details.

    You should have received a copy of the GNU General Public License
    along with OpenFOAM.  If not, see <http://www.gnu.org/licenses/>.

\*---------------------------------------------------------------------------*/

#include "manufacturedSolutionSource.H"
#include "fvMatrices.H"
#include "addToRunTimeSelectionTable.H"

// * * * * * * * * * * * * * Static Member Functions * * * * * * * * * * * * //

namespace Foam
{
namespace fv
{
    defineTypeNameAndDebug(manufacturedSolutionSource, 0);
    addToRunTimeSelectionTable(option, manufacturedSolutionSource, dictionary);
}
}


// * * * * * * * * * * * * * * * * Constructors  * * * * * * * * * * * * * * //

Foam::fv::manufacturedSolutionSource::manufacturedSolutionSource
(
    const word& sourceName,
    const word& modelType,
    const dictionary& dict,
    const fvMesh& mesh
)
:
    fv::option(sourceName, modelType, dict, mesh),
    mu_(0),
    lambda_(0),
    ax_(readScalar(dict.lookup("ax"))),
    ay_(readScalar(dict.lookup("ay"))),
    az_(readScalar(dict.lookup("az"))),
    bodyForces_
    (
        IOobject
        (
            "bodyForces",
            mesh.time().timeName(),
            mesh,
            IOobject::NO_READ,
            IOobject::NO_WRITE
        ),
        mesh,
        dimensionedVector("zero", dimForce/dimVolume, vector::zero)
    )
{
    coeffs_.readEntry("fields", fieldNames_);

    if (fieldNames_.size() != 1)
    {
        FatalErrorInFunction
            << "settings are:" << fieldNames_ << exit(FatalError);
    }

    fv::option::resetApplied();

    // Set Lame parameters
    const scalar E(readScalar(dict.lookup("E")));
    const scalar nu(readScalar(dict.lookup("nu")));
    mu_ = E/(2.0*(1.0 + nu));
    lambda_ = (E*nu)/((1.0 + nu)*(1.0 - 2.0*nu));

    // Set the body force term
    const vectorField& C = mesh.C();
    const scalar pi = constant::mathematical::pi;
    vectorField& bodyForcesI = bodyForces_;
    forAll(bodyForcesI, cellI)
    {
        const scalar x = C[cellI].x();
        const scalar y = C[cellI].y();
        const scalar z = C[cellI].z();

        bodyForcesI[cellI][vector::X] =
            lambda_
           *(
                8*ay_*pi*pi*Foam::cos(4*pi*x)*Foam::cos(2*pi*y)*Foam::sin(pi*z)
              + 4*az_*pi*pi*Foam::cos(4*pi*x)*Foam::cos(pi*z)*Foam::sin(2*pi*y)
              - 16*ax_*pi*pi*Foam::sin(4*pi*x)*Foam::sin(2*pi*y)*Foam::sin(pi*z)
            )
          + mu_
           *(
                8*ay_*pi*pi*Foam::cos(4*pi*x)*Foam::cos(2*pi*y)*Foam::sin(pi*z)
              + 4*az_*pi*pi*Foam::cos(4*pi*x)*Foam::cos(pi*z)*Foam::sin(2*pi*y)
              - 5*ax_*pi*pi*Foam::sin(4*pi*x)*Foam::sin(2*pi*y)*Foam::sin(pi*z)
            )
          - 32*ax_*mu_*pi*pi*Foam::sin(4*pi*x)*Foam::sin(2*pi*y)*Foam::sin(pi*z);

        bodyForcesI[cellI][vector::Y] =
            lambda_
           *(
                8*ax_*pi*pi*Foam::cos(4*pi*x)*Foam::cos(2*pi*y)*Foam::sin(pi*z)
              + 2*az_*pi*pi*Foam::cos(2*pi*y)*Foam::cos(pi*z)*Foam::sin(4*pi*x)
              - 4*ay_*pi*pi*Foam::sin(4*pi*x)*Foam::sin(2*pi*y)*Foam::sin(pi*z)
            )
          + mu_
           *(
                8*ax_*pi*pi*Foam::cos(4*pi*x)*Foam::cos(2*pi*y)*Foam::sin(pi*z)
              + 2*az_*pi*pi*Foam::cos(2*pi*y)*Foam::cos(pi*z)*Foam::sin(4*pi*x)
              - 17*ay_*pi*pi*Foam::sin(4*pi*x)*Foam::sin(2*pi*y)*Foam::sin(pi*z)
           )
          - 8*ay_*mu_*pi*pi*Foam::sin(4*pi*x)*Foam::sin(2*pi*y)*Foam::sin(pi*z);

        bodyForcesI[cellI][vector::Z] =
            lambda_
           *(
               4*ax_*pi*pi*Foam::cos(4*pi*x)*Foam::cos(pi*z)*Foam::sin(2*pi*y)
              + 2*ay_*pi*pi*Foam::cos(2*pi*y)*Foam::cos(pi*z)*Foam::sin(4*pi*x)
              - az_*pi*pi*Foam::sin(4*pi*x)*Foam::sin(2*pi*y)*Foam::sin(pi*z)
            )
          + mu_
           *(
               4*ax_*pi*pi*Foam::cos(4*pi*x)*Foam::cos(pi*z)*Foam::sin(2*pi*y)
              + 2*ay_*pi*pi*Foam::cos(2*pi*y)*Foam::cos(pi*z)*Foam::sin(4*pi*x)
              - 20*az_*pi*pi*Foam::sin(4*pi*x)*Foam::sin(2*pi*y)*Foam::sin(pi*z)
            )
          - 2*az_*mu_*pi*pi*Foam::sin(4*pi*x)*Foam::sin(2*pi*y)*Foam::sin(pi*z);
    }
}


// * * * * * * * * * * * * * * * Member Functions  * * * * * * * * * * * * * //

void Foam::fv::manufacturedSolutionSource::addSup
(
    const volScalarField&,
    fvMatrix<vector>& eqn,
    const label fieldi
)
{
    eqn -= bodyForces_;
}


bool Foam::fv::manufacturedSolutionSource::read(const dictionary& dict)
{
    NotImplemented;

    return false;
}


// ************************************************************************* //
