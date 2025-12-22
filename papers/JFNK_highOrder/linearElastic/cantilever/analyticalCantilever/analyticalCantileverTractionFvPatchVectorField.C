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

#include "analyticalCantileverTractionFvPatchVectorField.H"
#include "addToRunTimeSelectionTable.H"
#include "volFields.H"
#include "cantileverStressDisplacement.H"

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //

namespace Foam
{

// * * * * * * * * * * * * * * * * Constructors  * * * * * * * * * * * * * * //

analyticalCantileverTractionFvPatchVectorField::
analyticalCantileverTractionFvPatchVectorField
(
    const fvPatch& p,
    const DimensionedField<vector, volMesh>& iF
)
:
    solidTractionFvPatchVectorField(p, iF),
    dict_()
{}


analyticalCantileverTractionFvPatchVectorField::
analyticalCantileverTractionFvPatchVectorField
(
    const fvPatch& p,
    const DimensionedField<vector, volMesh>& iF,
    const dictionary& dict
)
:
    solidTractionFvPatchVectorField(p, iF),
    dict_(dict)
{}


analyticalCantileverTractionFvPatchVectorField::
analyticalCantileverTractionFvPatchVectorField
(
    const analyticalCantileverTractionFvPatchVectorField& stpvf,
    const fvPatch& p,
    const DimensionedField<vector, volMesh>& iF,
    const fvPatchFieldMapper& mapper
)
:
    solidTractionFvPatchVectorField(stpvf, p, iF, mapper),
    dict_(stpvf.dict_)
{}

#ifndef OPENFOAM_ORG
analyticalCantileverTractionFvPatchVectorField::
analyticalCantileverTractionFvPatchVectorField
(
    const analyticalCantileverTractionFvPatchVectorField& stpvf
)
:
    solidTractionFvPatchVectorField(stpvf),
    dict_(stpvf.dict_)
{}
#endif

analyticalCantileverTractionFvPatchVectorField::
analyticalCantileverTractionFvPatchVectorField
(
    const analyticalCantileverTractionFvPatchVectorField& stpvf,
    const DimensionedField<vector, volMesh>& iF
)
:
    solidTractionFvPatchVectorField(stpvf, iF),
    dict_(stpvf.dict_)
{}


// * * * * * * * * * * * * * * * Member Functions  * * * * * * * * * * * * * //

void analyticalCantileverTractionFvPatchVectorField::autoMap
(
    const fvPatchFieldMapper& m
)
{
    solidTractionFvPatchVectorField::autoMap(m);
}


// Reverse-map the given fvPatchField onto this fvPatchField
void analyticalCantileverTractionFvPatchVectorField::rmap
(
    const fvPatchVectorField& ptf,
    const labelList& addr
)
{
    solidTractionFvPatchVectorField::rmap(ptf, addr);
}


// Update the coefficients associated with the patch field
void analyticalCantileverTractionFvPatchVectorField::updateCoeffs()
{
    if (updated())
    {
        return;
    }

    // Patch unit normals
    vectorField n(patch().nf());

    // Patch face centres
    const vectorField& Cf = patch().Cf();
    const scalar P(readScalar(dict_.lookup("P")));
    const scalar E(readScalar(dict_.lookup("E")));
    const scalar nu(readScalar(dict_.lookup("nu")));
    const scalar L(readScalar(dict_.lookup("L")));
    const scalar D(readScalar(dict_.lookup("D")));
    const scalar I(Foam::pow(D, 3.0)/12.0);

    // Set the patch traction
    vectorField& trac = traction();

    forAll(traction(), faceI)
    {
        trac[faceI] =
            (
                n[faceI] & cantileverStress(Cf[faceI], P, E, nu, L, D, I)
            );
       }

    solidTractionFvPatchVectorField::updateCoeffs();
}


autoPtr<CompactListList<vector>>
analyticalCantileverTractionFvPatchVectorField::evaluateQuadrature
(
    const CompactListList<point>& faceQuadPoints
) const
{
     // faceQuadPoints is list for whole mesh.
    labelList nQpPerFace(this->size(), 0);
    const label start = this->patch().start();
    forAll(nQpPerFace, faceI)
    {
        const label globalFaceID = faceI + start;
        nQpPerFace[faceI]=faceQuadPoints[globalFaceID].size();
    }

    autoPtr<CompactListList<vector>> tQuadPointsValue
    (
        new CompactListList<vector>(nQpPerFace)
    );

    // Get a reference to the actual data for easier access
    CompactListList<vector>& quadPointsValue = tQuadPointsValue();

    const scalar P(readScalar(dict_.lookup("P")));
    const scalar E(readScalar(dict_.lookup("E")));
    const scalar nu(readScalar(dict_.lookup("nu")));
    const scalar L(readScalar(dict_.lookup("L")));
    const scalar D(readScalar(dict_.lookup("D")));
    const scalar I(Foam::pow(D, 3.0)/12.0);

    // Patch unit normals
    vectorField n(patch().nf());

    // Loop over faces
    forAll(*this, faceI)
    {
        const label globalFaceID = faceI + start;

        // Get the number of quadrature points for this face
        const label nPoints = faceQuadPoints[globalFaceID].size();

        // Assign the values to face quadrature points
        for (label pointI = 0; pointI < nPoints; ++pointI)
        {
            const point quadPoint = faceQuadPoints[globalFaceID][pointI];
            quadPointsValue[faceI][pointI] =
                n[faceI] & cantileverStress(quadPoint, P, E, nu, L, D, I);
        }
    }

    return tQuadPointsValue;
}


// Write
void analyticalCantileverTractionFvPatchVectorField::write(Ostream& os) const
{
    solidTractionFvPatchVectorField::write(os);

    os.writeKeyword("P")
        << dict_.lookup("P") << token::END_STATEMENT << nl;

    os.writeKeyword("E")
        << dict_.lookup("E") << token::END_STATEMENT << nl;

    os.writeKeyword("nu")
        << dict_.lookup("nu") << token::END_STATEMENT << nl;

    os.writeKeyword("L")
        << dict_.lookup("L") << token::END_STATEMENT << nl;

    os.writeKeyword("D")
        << dict_.lookup("D") << token::END_STATEMENT << nl;
}


// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //

makePatchTypeField
(
    fvPatchVectorField,
    analyticalCantileverTractionFvPatchVectorField
);

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //

} // End namespace Foam

// ************************************************************************* //
