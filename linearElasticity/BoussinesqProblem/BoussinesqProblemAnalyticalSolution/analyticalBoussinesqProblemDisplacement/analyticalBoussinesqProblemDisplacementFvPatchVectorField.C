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

\*---------------------------------------------------------------------------*/

#include "analyticalBoussinesqProblemDisplacementFvPatchVectorField.H"
#include "addToRunTimeSelectionTable.H"

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //

namespace Foam
{

// * * * * * * * * * * * * * * * * Constructors  * * * * * * * * * * * * * * //

analyticalBoussinesqProblemDisplacementFvPatchVectorField::analyticalBoussinesqProblemDisplacementFvPatchVectorField
(
    const fvPatch& p,
    const DimensionedField<vector, volMesh>& iF
)
:
    fixedDisplacementFvPatchVectorField(p, iF),
    E_(0.0),
    nu_(0.0),
    force_(vector::zero)
{}


analyticalBoussinesqProblemDisplacementFvPatchVectorField::analyticalBoussinesqProblemDisplacementFvPatchVectorField
(
    const analyticalBoussinesqProblemDisplacementFvPatchVectorField& ptf,
    const fvPatch& p,
    const DimensionedField<vector, volMesh>& iF,
    const fvPatchFieldMapper& mapper
)
:
    fixedDisplacementFvPatchVectorField(ptf, p, iF, mapper),
    E_(ptf.E_),
    nu_(ptf.nu_),
    force_(ptf.force_)
{}


analyticalBoussinesqProblemDisplacementFvPatchVectorField::analyticalBoussinesqProblemDisplacementFvPatchVectorField
(
    const fvPatch& p,
    const DimensionedField<vector, volMesh>& iF,
    const dictionary& dict
)
:
    fixedDisplacementFvPatchVectorField(p, iF, dict),
    E_(readScalar(dict.lookup("E"))),
    nu_(readScalar(dict.lookup("nu"))),
    force_(dict.lookup("force"))
{}

#ifndef OPENFOAMFOUNDATION
analyticalBoussinesqProblemDisplacementFvPatchVectorField::analyticalBoussinesqProblemDisplacementFvPatchVectorField
(
    const analyticalBoussinesqProblemDisplacementFvPatchVectorField& pivpvf
)
:
    fixedDisplacementFvPatchVectorField(pivpvf),
    E_(pivpvf.E_),
    nu_(pivpvf.nu_),
    force_(pivpvf.force_)
{}
#endif

analyticalBoussinesqProblemDisplacementFvPatchVectorField::analyticalBoussinesqProblemDisplacementFvPatchVectorField
(
    const analyticalBoussinesqProblemDisplacementFvPatchVectorField& pivpvf,
    const DimensionedField<vector, volMesh>& iF
)
:
    fixedDisplacementFvPatchVectorField(pivpvf, iF),
    E_(pivpvf.E_),
    nu_(pivpvf.nu_),
    force_(pivpvf.force_)
{}


// * * * * * * * * * * * * * * * Member Functions  * * * * * * * * * * * * * //


void analyticalBoussinesqProblemDisplacementFvPatchVectorField::updateCoeffs()
{
    if (this->updated())
    {
        return;
    }

    const scalar& E = E_;
    const scalar& nu = nu_;
    const scalar& normalForce = force_.z();

    const vectorField& Cf = patch().Cf();

    // Shear modulus
    const scalar G = E/(2.0*(1.0+nu));
    const scalar C = -normalForce/(mathematicalConstant::pi*4*G);

    vectorField& disp = totalDisp();
    forAll(disp, faceI)
    {
        const scalar& X = Cf[faceI].x();
        const scalar& Y = Cf[faceI].y();
        const scalar& Z = -Cf[faceI].z();
        const scalar R = Foam::sqrt(Foam::sqr(X) + Foam::sqr(Y) + Foam::sqr(Z));

        disp[faceI].x() = C * (X*Z/Foam::pow(R,3) - (1-2*nu)*(X/(R*(R+Z))));

        disp[faceI].y() = C * (Y*Z/Foam::pow(R,3) - (1-2*nu)*(Y/(R*(R+Z))));

        disp[faceI].z() = -C * (Foam::sqr(Z)/Foam::pow(R,3) + ((2*(1-nu))/R));
    }

    fixedDisplacementFvPatchVectorField::updateCoeffs();
}


void analyticalBoussinesqProblemDisplacementFvPatchVectorField::write(Ostream& os) const
{
    os.writeKeyword("nu")
        << nu_ << token::END_STATEMENT << nl;

    os.writeKeyword("E")
        << E_ << token::END_STATEMENT << nl;

    os.writeKeyword("force")
        << force_ << token::END_STATEMENT << nl;

    fixedDisplacementFvPatchVectorField::write(os);
}


// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //

makePatchTypeField
(
    fvPatchVectorField,
    analyticalBoussinesqProblemDisplacementFvPatchVectorField
);

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //

} // End namespace Foam

// ************************************************************************* //
