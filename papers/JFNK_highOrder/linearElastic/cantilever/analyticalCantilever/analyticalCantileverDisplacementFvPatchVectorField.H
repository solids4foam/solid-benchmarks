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

Class
    analyticalCantileverDisplacementFvPatchVectorField

Description
    Applies a displacement field from a analyticalCantilever analytical solution
    as a fixed value condition.

SourceFiles
    analyticalCantileverDisplacementFvPatchVectorField.C

Author
    Philip Cardiff, UCD.
    Ivan Batistic, UCD. All rights reserved.

\*---------------------------------------------------------------------------*/

#ifndef analyticalCantileverDisplacementFvPatchVectorField_H
#define analyticalCantileverDisplacementFvPatchVectorField_H

#include "fixedDisplacementFvPatchVectorField.H"
#include "cantileverStressDisplacement.H"

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //

namespace Foam
{

/*---------------------------------------------------------------------------*\
                 Class analyticalCantileverDisplacementFvPatch Declaration
\*---------------------------------------------------------------------------*/

class analyticalCantileverDisplacementFvPatchVectorField
:
    public fixedDisplacementFvPatchVectorField
{
    // Private Data

        //- A copy of the constructor dict
        const dictionary dict_;

public:

    //- Runtime type information
    TypeName("analyticalCantileverDisplacement");


    // Constructors

        //- Construct from patch and internal field
        analyticalCantileverDisplacementFvPatchVectorField
        (
            const fvPatch&,
            const DimensionedField<vector, volMesh>&
        );

        //- Construct from patch, internal field and dictionary
        analyticalCantileverDisplacementFvPatchVectorField
        (
            const fvPatch&,
            const DimensionedField<vector, volMesh>&,
            const dictionary&
        );

        //- Construct by mapping given analyticalCantileverDisplacementFvPatchVectorField
        //  onto a new patch
        analyticalCantileverDisplacementFvPatchVectorField
        (
            const analyticalCantileverDisplacementFvPatchVectorField&,
            const fvPatch&,
            const DimensionedField<vector, volMesh>&,
            const fvPatchFieldMapper&
        );

        //- Construct as copy
        analyticalCantileverDisplacementFvPatchVectorField
        (
            const analyticalCantileverDisplacementFvPatchVectorField&
#ifdef OPENFOAM_ORG
        ) = delete;
#else
        );

        //- Construct and return a clone
        virtual tmp<fvPatchVectorField> clone() const
        {
            return tmp<fvPatchVectorField>
            (
                new analyticalCantileverDisplacementFvPatchVectorField(*this)
            );
        }
#endif

        //- Construct as copy setting internal field reference
        analyticalCantileverDisplacementFvPatchVectorField
        (
            const analyticalCantileverDisplacementFvPatchVectorField&,
            const DimensionedField<vector, volMesh>&
        );

        //- Construct and return a clone setting internal field reference
        virtual tmp<fvPatchVectorField> clone
        (
            const DimensionedField<vector, volMesh>& iF
        ) const
        {
            return tmp<fvPatchVectorField>
            (
                new analyticalCantileverDisplacementFvPatchVectorField(*this, iF)
            );
        }


    // Member functions

        // Evaluation functions

            //- Update the coefficients associated with the patch field
            virtual void updateCoeffs();

            //- Return face quadrature values.
            // Used for high order solvers, input is position of points
            virtual autoPtr<CompactListList<vector>> evaluateQuadrature
            (
                const CompactListList<point>& faceQuadPoints
            ) const;

        //- Write
        virtual void write(Ostream&) const;

};


// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //

} // End namespace Foam

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //

#endif

// ************************************************************************* //
