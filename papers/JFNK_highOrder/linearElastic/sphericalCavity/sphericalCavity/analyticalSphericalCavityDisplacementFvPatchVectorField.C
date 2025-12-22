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

#include "analyticalSphericalCavityDisplacementFvPatchVectorField.H"
#include "addToRunTimeSelectionTable.H"
#include "sphericalCavityStressDisplacement.H"

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //

namespace Foam
{

// * * * * * * * * * * * * * * * * Constructors  * * * * * * * * * * * * * * //

analyticalSphericalCavityDisplacementFvPatchVectorField::
analyticalSphericalCavityDisplacementFvPatchVectorField
(
    const fvPatch& p,
    const DimensionedField<vector, volMesh>& iF
)
:
    fixedDisplacementFvPatchVectorField(p, iF),
    T0_(0.0),
    cavityR_(0.0),
    nu_(0.0),
    E_(0.0),
    dict_()
{}


analyticalSphericalCavityDisplacementFvPatchVectorField::
analyticalSphericalCavityDisplacementFvPatchVectorField
(
    const analyticalSphericalCavityDisplacementFvPatchVectorField& ptf,
    const fvPatch& p,
    const DimensionedField<vector, volMesh>& iF,
    const fvPatchFieldMapper& mapper
)
:
    fixedDisplacementFvPatchVectorField(ptf, p, iF, mapper),
    T0_(ptf.T0_),
    cavityR_(ptf.cavityR_),
    nu_(ptf.nu_),
    E_(ptf.E_),
    dict_(ptf.dict_)
{}


analyticalSphericalCavityDisplacementFvPatchVectorField::
analyticalSphericalCavityDisplacementFvPatchVectorField
(
    const fvPatch& p,
    const DimensionedField<vector, volMesh>& iF,
    const dictionary& dict
)
:
    fixedDisplacementFvPatchVectorField(p, iF, dict),
    T0_(readScalar(dict.lookup("farFieldTractionZ"))),
    cavityR_(readScalar(dict.lookup("cavityRadius"))),
    nu_(readScalar(dict.lookup("nu"))),
    E_(readScalar(dict.lookup("E"))),
    dict_(dict)
{}

#ifndef OPENFOAM_ORG
analyticalSphericalCavityDisplacementFvPatchVectorField::
analyticalSphericalCavityDisplacementFvPatchVectorField
(
    const analyticalSphericalCavityDisplacementFvPatchVectorField& pivpvf
)
:
    fixedDisplacementFvPatchVectorField(pivpvf),
    T0_(pivpvf.T0_),
    cavityR_(pivpvf.cavityR_),
    nu_(pivpvf.nu_),
    E_(pivpvf.E_),
    dict_(pivpvf.dict_)
{}
#endif

analyticalSphericalCavityDisplacementFvPatchVectorField::
analyticalSphericalCavityDisplacementFvPatchVectorField
(
    const analyticalSphericalCavityDisplacementFvPatchVectorField& pivpvf,
    const DimensionedField<vector, volMesh>& iF
)
:
    fixedDisplacementFvPatchVectorField(pivpvf, iF),
    T0_(pivpvf.T0_),
    cavityR_(pivpvf.cavityR_),
    nu_(pivpvf.nu_),
    E_(pivpvf.E_),
    dict_(pivpvf.dict_)
{}


// * * * * * * * * * * * * * * * Member Functions  * * * * * * * * * * * * * //


void analyticalSphericalCavityDisplacementFvPatchVectorField::updateCoeffs()
{
    if (this->updated())
    {
        return;
    }

    // Set the displacement at each patch face
    vectorField& disp = totalDisp();
    const vectorField& Cf = patch().Cf();
    forAll(disp, faceI)
    {
        disp[faceI] =
            sphericalCavityDisplacement
            (
                nu_,
                T0_,
                E_,
                cavityR_,
                Cf[faceI]
            );
    }

    fixedDisplacementFvPatchVectorField::updateCoeffs();
}


autoPtr<CompactListList<vector>>
analyticalSphericalCavityDisplacementFvPatchVectorField::evaluateQuadrature
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
                sphericalCavityDisplacement
                (
                    nu_,
                    T0_,
                    E_,
                    cavityR_,
                    quadPoint
                );
        }
    }

    return tQuadPointsValue;
}


void analyticalSphericalCavityDisplacementFvPatchVectorField::
write(Ostream& os) const
{
    fixedDisplacementFvPatchVectorField::write(os);
}


// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //

makePatchTypeField
(
    fvPatchVectorField,
    analyticalSphericalCavityDisplacementFvPatchVectorField
);

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //

} // End namespace Foam

// ************************************************************************* //
