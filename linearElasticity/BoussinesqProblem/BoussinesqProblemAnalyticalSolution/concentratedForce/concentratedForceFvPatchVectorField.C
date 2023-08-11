/*---------------------------------------------------------------------------*\
  =========                 |
  \\      /  F ield         | foam-extend: Open Source CFD
   \\    /   O peration     | Version:     3.2
    \\  /    A nd           | Web:         http://www.foam-extend.org
     \\/     M anipulation  | For copyright notice see file Copyright
-------------------------------------------------------------------------------
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

#include "concentratedForceFvPatchVectorField.H"
#include "addToRunTimeSelectionTable.H"
#include "volFields.H"

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //

namespace Foam
{

// * * * * * * * * * * * * * * * * Constructors  * * * * * * * * * * * * * * //

concentratedForceFvPatchVectorField::
concentratedForceFvPatchVectorField
(
    const fvPatch& p,
    const DimensionedField<vector, volMesh>& iF
)
:
    solidTractionFvPatchVectorField(p, iF),
    force_(vector::zero),
    forceLocation_(vector::zero),
    faceID_(-1),
    forceSeries_()
{
    fvPatchVectorField::operator=(patchInternalField());
    gradient() = vector::zero;
}


concentratedForceFvPatchVectorField::
concentratedForceFvPatchVectorField
(
    const fvPatch& p,
    const DimensionedField<vector, volMesh>& iF,
    const dictionary& dict
)
:
    solidTractionFvPatchVectorField(p, iF),
    force_(vector::zero),
    forceLocation_(dict.lookup("forceLocation")),
    faceID_(-1),
    forceSeries_()
{
    fvPatchVectorField::operator=(patchInternalField());
    gradient() = vector::zero;
    
    // Check if force is time-varying
    if (dict.found("forceSeries") && dict.found("force"))
    {
        FatalErrorIn
        (
            "concentratedForceFvPatchVectorField::"
            "concentratedForceFvPatchVectorField"
        )   << "forceSeries or force can be specified, "
            << "not both!" << abort(FatalError);
    }
    else if (dict.found("forceSeries"))
    {
        Info<< type() << ": " << patch().name()
            << " force is time-varying" << endl;
        forceSeries_ =
            interpolationTable<vector>(dict.subDict("forceSeries"));
    }
    else
    {
        force_ = dict.lookup("force");
    }   
    
    // Search for the closest face to forceLocation
    // During simulation, force is always acting on the same face! 
    scalar minDist = GREAT;
    
    forAll(patch().Cf(), faceI)
    {
        scalar distance = mag(patch().Cf()[faceI] - forceLocation_);

        if(distance < minDist)
        {
            minDist = distance;
            faceID_ = faceI;
        }
    }

}


concentratedForceFvPatchVectorField::
concentratedForceFvPatchVectorField
(
    const concentratedForceFvPatchVectorField& tdpvf,
    const fvPatch& p,
    const DimensionedField<vector, volMesh>& iF,
    const fvPatchFieldMapper& mapper
)
:
    solidTractionFvPatchVectorField(tdpvf, p, iF, mapper),
    force_(tdpvf.force_),
    forceLocation_(tdpvf.forceLocation_),
    faceID_(tdpvf.faceID_),
    forceSeries_(tdpvf.forceSeries_)
{}

#ifndef OPENFOAMFOUNDATION
concentratedForceFvPatchVectorField::
concentratedForceFvPatchVectorField
(
    const concentratedForceFvPatchVectorField& tdpvf
)
:
    solidTractionFvPatchVectorField(tdpvf),
    force_(tdpvf.force_),
    forceLocation_(tdpvf.forceLocation_),
    faceID_(tdpvf.faceID_),
    forceSeries_(tdpvf.forceSeries_)
{}
#endif

concentratedForceFvPatchVectorField::
concentratedForceFvPatchVectorField
(
    const concentratedForceFvPatchVectorField& tdpvf,
    const DimensionedField<vector, volMesh>& iF
)
:
    solidTractionFvPatchVectorField(tdpvf, iF),
    force_(tdpvf.force_),
    forceLocation_(tdpvf.forceLocation_),
    faceID_(tdpvf.faceID_),
    forceSeries_(tdpvf.forceSeries_)
{}


// * * * * * * * * * * * * * * * Member Functions  * * * * * * * * * * * * * //

void concentratedForceFvPatchVectorField::autoMap
(
    const fvPatchFieldMapper& m
)
{
    solidTractionFvPatchVectorField::autoMap(m);
}


// Reverse-map the given fvPatchField onto this fvPatchField
void concentratedForceFvPatchVectorField::rmap
(
    const fvPatchVectorField& ptf,
    const labelList& addr
)
{
    solidTractionFvPatchVectorField::rmap(ptf, addr);

//    const concentratedForceFvPatchVectorField& dmptf =
//         refCast<const concentratedForceFvPatchVectorField>(ptf);
}


// Update the coefficients associated with the patch field
void concentratedForceFvPatchVectorField::updateCoeffs()
{
    if (updated())
    {
        return;
    }

    // Get current force
    vector curForce = force_;
    
    if (forceSeries_.size())
    {
        curForce = forceSeries_(db().time().timeOutputValue());
    }

    traction()[faceID_] = curForce/patch().magSf()[faceID_];

    // Apply the traction
    solidTractionFvPatchVectorField::updateCoeffs();
}


// Write
void concentratedForceFvPatchVectorField::write(Ostream& os) const
{
    solidTractionFvPatchVectorField::write(os);
    
    if (forceSeries_.size())
    {
        os.writeKeyword("forceSeries") << nl;
        os << token::BEGIN_BLOCK << nl;
        forceSeries_.write(os);
        os << token::END_BLOCK << nl;
    }
    else
    {
#ifdef OPENFOAMFOUNDATION
        writeEntry(os, "force", force_);
#else
        os.writeKeyword("force") 
            << force_ 
            << token::END_STATEMENT << nl;;
#endif
    }
    
#ifdef OPENFOAMFOUNDATION
        writeEntry(os, "forceLocation", forceLocation_);
#else
        os.writeKeyword("forceLocation")
            << forceLocation_ 
            << token::END_STATEMENT << nl;;
#endif
}


// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //

makePatchTypeField(fvPatchVectorField, concentratedForceFvPatchVectorField);

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //

} // End namespace Foam

// ************************************************************************* //
