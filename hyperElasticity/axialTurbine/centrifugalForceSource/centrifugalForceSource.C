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

#include "centrifugalForceSource.H"
#include "fvMatrices.H"
#include "addToRunTimeSelectionTable.H"

// * * * * * * * * * * * * * Static Member Functions * * * * * * * * * * * * //

namespace Foam
{
namespace fv
{
    defineTypeNameAndDebug(centrifugalForceSource, 0);
    addToRunTimeSelectionTable(option, centrifugalForceSource, dictionary);
}
}


// * * * * * * * * * * * * * * * * Constructors  * * * * * * * * * * * * * * //

Foam::fv::centrifugalForceSource::centrifugalForceSource
(
    const word& sourceName,
    const word& modelType,
    const dictionary& dict,
    const fvMesh& mesh
)
:
    fv::option(sourceName, modelType, dict, mesh),
    rho_("rho", dict.lookup("rho")),
    rpm_(readScalar(dict.lookup("rpm"))),
    omega_("omega", dimless/dimTime, 2.0*constant::mathematical::pi*rpm_/60.0),
    origin_(dict.lookup("origin")),
    axis_(dict.lookup("axis")),
    r_
    (
        IOobject
        (
            "centrifugalForceSourceRadius",
            mesh.time().timeName(),
            mesh,
            IOobject::NO_READ,
            IOobject::NO_WRITE
        ),
        mesh,
        dimensionedVector("0", dimLength, vector::zero)
    )
{
    // Normalise the axis
    const scalar magAxis = mag(axis_);
    if (magAxis < SMALL)
    {
        FatalErrorInFunction
            << "The axis has a zero magnitude!" << exit(FatalError);
    }
    axis_ /= magAxis;

    // Vector from the origin to each cell
    r_.primitiveFieldRef() = mesh.C().primitiveField() - origin_;

    // Remove the component in the axis direction to leave the radial vector
    r_ = ((I - sqr(axis_)) & r_);

    coeffs_.readEntry("fields", fieldNames_);

    if (fieldNames_.size() != 1)
    {
        FatalErrorInFunction
            << "settings are:" << fieldNames_ << exit(FatalError);
    }

    fv::option::resetApplied();
}


// * * * * * * * * * * * * * * * Member Functions  * * * * * * * * * * * * * //

void Foam::fv::centrifugalForceSource::addSup
(
    const volScalarField&,
    fvMatrix<vector>& eqn,
    const label fieldi
)
{
    eqn -= rho_*sqr(omega_)*r_;
}


bool Foam::fv::centrifugalForceSource::read(const dictionary& dict)
{
    NotImplemented;

    return false;
}


// ************************************************************************* //
