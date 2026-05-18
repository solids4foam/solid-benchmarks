/*---------------------------------------------------------------------------*\
License
    This file is part of solids4foam.

    solids4foam is free software: you can redistribute it and/or modify it
    under the terms of the GNU General Public License as published by the
    Free Software Foundation, either version 3 of the License, or (at your
    option) any later version.

    solids4foam is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
    or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
    for more details.

    You should have received a copy of the GNU General Public License
    along with solids4foam.  If not, see <http://www.gnu.org/licenses/>.

\*---------------------------------------------------------------------------*/

#include "membraneRoofVelocity2dFvPatchVectorField.H"
#include "addToRunTimeSelectionTable.H"

// * * * * * * * * * * * * * * * * Constructors  * * * * * * * * * * * * * * //

namespace Foam
{

membraneRoofVelocity2dFvPatchVectorField::
membraneRoofVelocity2dFvPatchVectorField
(
    const fvPatch& p,
    const DimensionedField<vector, volMesh>& iF
)
:
    fixedValueFvPatchVectorField(p, iF)
{}


membraneRoofVelocity2dFvPatchVectorField::
membraneRoofVelocity2dFvPatchVectorField
(
    const membraneRoofVelocity2dFvPatchVectorField& pvf,
    const fvPatch& p,
    const DimensionedField<vector, volMesh>& iF,
    const fvPatchFieldMapper& mapper
)
:
    fixedValueFvPatchVectorField(pvf, p, iF, mapper)
{}


membraneRoofVelocity2dFvPatchVectorField::
membraneRoofVelocity2dFvPatchVectorField
(
    const fvPatch& p,
    const DimensionedField<vector, volMesh>& iF,
    const dictionary& dict
)
:
    fixedValueFvPatchVectorField(p, iF, dict)
{
    Info<< "Creating " << type() << " boundary condition" << endl;
}


#ifndef OPENFOAM_ORG
membraneRoofVelocity2dFvPatchVectorField::
membraneRoofVelocity2dFvPatchVectorField
(
    const membraneRoofVelocity2dFvPatchVectorField& pvf
)
:
    fixedValueFvPatchVectorField(pvf)
{}
#endif


membraneRoofVelocity2dFvPatchVectorField::
membraneRoofVelocity2dFvPatchVectorField
(
    const membraneRoofVelocity2dFvPatchVectorField& pvf,
    const DimensionedField<vector, volMesh>& iF
)
:
    fixedValueFvPatchVectorField(pvf, iF)
{}


membraneRoofVelocity2dFvPatchVectorField::
~membraneRoofVelocity2dFvPatchVectorField()
{}


void membraneRoofVelocity2dFvPatchVectorField::autoMap
(
    const fvPatchFieldMapper& m
)
{
    fixedValueFvPatchVectorField::autoMap(m);
}


void membraneRoofVelocity2dFvPatchVectorField::rmap
(
    const fvPatchField<vector>& pvf,
    const labelList& addr
)
{
    fixedValueFvPatchVectorField::rmap(pvf, addr);
}


void membraneRoofVelocity2dFvPatchVectorField::updateCoeffs()
{
    if (this->updated())
    {
        return;
    }

    const scalar uMax = 0.6;
    const scalar yTop = 1.0;
    const scalar rampEndTime = 2.0;

    const scalarField y(patch().Cf().component(vector::Y));
    scalarField eta(y/yTop);
    forAll(eta, faceI)
    {
        eta[faceI] = max(min(eta[faceI], 1.0), 0.0);
    }
    const scalarField uy(2.0*eta - sqr(eta));

    const scalar t = db().time().value();
    scalar ut = 1.0;
    if (t < rampEndTime)
    {
        ut = t/rampEndTime;
    }

    operator==(uMax*ut*uy*vector(1, 0, 0));

    fixedValueFvPatchVectorField::updateCoeffs();
}


makePatchTypeField
(
    fvPatchVectorField,
    membraneRoofVelocity2dFvPatchVectorField
);

} // End namespace Foam

// ************************************************************************* //
