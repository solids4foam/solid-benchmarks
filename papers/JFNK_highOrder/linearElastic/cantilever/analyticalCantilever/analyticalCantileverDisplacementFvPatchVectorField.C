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

#include "analyticalCantileverDisplacementFvPatchVectorField.H"
#include "addToRunTimeSelectionTable.H"

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //

namespace Foam
{

// * * * * * * * * * * * * * * * * Constructors  * * * * * * * * * * * * * * //

analyticalCantileverDisplacementFvPatchVectorField::
analyticalCantileverDisplacementFvPatchVectorField
(
    const fvPatch& p,
    const DimensionedField<vector, volMesh>& iF
)
:
    fixedDisplacementFvPatchVectorField(p, iF),
    dict_()
{}


analyticalCantileverDisplacementFvPatchVectorField::
analyticalCantileverDisplacementFvPatchVectorField
(
    const analyticalCantileverDisplacementFvPatchVectorField& ptf,
    const fvPatch& p,
    const DimensionedField<vector, volMesh>& iF,
    const fvPatchFieldMapper& mapper
)
:
    fixedDisplacementFvPatchVectorField(ptf, p, iF, mapper),
    dict_(ptf.dict_)
{}


analyticalCantileverDisplacementFvPatchVectorField::
analyticalCantileverDisplacementFvPatchVectorField
(
    const fvPatch& p,
    const DimensionedField<vector, volMesh>& iF,
    const dictionary& dict
)
:
    fixedDisplacementFvPatchVectorField(p, iF, dict),
    dict_(dict)
{}

#ifndef OPENFOAM_ORG
analyticalCantileverDisplacementFvPatchVectorField::
analyticalCantileverDisplacementFvPatchVectorField
(
    const analyticalCantileverDisplacementFvPatchVectorField& pivpvf
)
:
    fixedDisplacementFvPatchVectorField(pivpvf),
    dict_(pivpvf.dict_)
{}
#endif

analyticalCantileverDisplacementFvPatchVectorField::
analyticalCantileverDisplacementFvPatchVectorField
(
    const analyticalCantileverDisplacementFvPatchVectorField& pivpvf,
    const DimensionedField<vector, volMesh>& iF
)
:
    fixedDisplacementFvPatchVectorField(pivpvf, iF),
    dict_(pivpvf.dict_)
{}


// * * * * * * * * * * * * * * * Member Functions  * * * * * * * * * * * * * //


void analyticalCantileverDisplacementFvPatchVectorField::updateCoeffs()
{
    if (this->updated())
    {
        return;
    }

    // Set the displacement at each patch face
    vectorField& disp = totalDisp();
    const vectorField& Cf = patch().Cf();

    const scalar P(readScalar(dict_.lookup("P")));
    const scalar E(readScalar(dict_.lookup("E")));
    const scalar nu(readScalar(dict_.lookup("nu")));
    const scalar L(readScalar(dict_.lookup("L")));
    const scalar D(readScalar(dict_.lookup("D")));
    const scalar I(Foam::pow(D, 3.0)/12.0);

    forAll(disp, faceI)
    {
        disp[faceI] =
            cantileverDisplacement
            (
                Cf[faceI], P, E, nu, L, D, I
            );
    }

    fixedDisplacementFvPatchVectorField::updateCoeffs();
}


autoPtr<CompactListList<vector>>
analyticalCantileverDisplacementFvPatchVectorField::evaluateQuadrature
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
                cantileverDisplacement
                (
                    quadPoint, P, E, nu, L, D, I
                );
        }
    }

    return tQuadPointsValue;
}


void analyticalCantileverDisplacementFvPatchVectorField::write(Ostream& os) const
{
    fixedDisplacementFvPatchVectorField::write(os);

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
    analyticalCantileverDisplacementFvPatchVectorField
);

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //

} // End namespace Foam

// ************************************************************************* //
