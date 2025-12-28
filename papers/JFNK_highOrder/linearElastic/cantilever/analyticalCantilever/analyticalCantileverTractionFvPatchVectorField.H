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
    analyticalCantileverTractionFvPatchVectorField

Description
    Traction boundary condition for a cantilever beam

Author
   Ivan Batistic, UCD.
   Philip Cardiff, UCD. All rights reserved.

SourceFiles
    analyticalCantileverTractionFvPatchVectorField.C

\*---------------------------------------------------------------------------*/

#ifndef analyticalCantileverTractionFvPatchVectorField_H
#define analyticalCantileverTractionFvPatchVectorField_H

#include "fvPatchFields.H"
#include "solidTractionFvPatchVectorField.H"

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //

namespace Foam
{

/*---------------------------------------------------------------------------*\
             Class analyticalCantileverTractionFvPatchVectorField Declaration
\*---------------------------------------------------------------------------*/

class analyticalCantileverTractionFvPatchVectorField
:
    public solidTractionFvPatchVectorField
{
private:

    // Private Data

        //- A copy of the constructor dict
        const dictionary dict_;


public:

    //- Runtime type information
    TypeName("analyticalCantileverTraction");


    // Constructors

        //- Construct from patch and internal field
        analyticalCantileverTractionFvPatchVectorField
        (
            const fvPatch&,
            const DimensionedField<vector, volMesh>&
        );

        //- Construct from patch, internal field and dictionary
        analyticalCantileverTractionFvPatchVectorField
        (
            const fvPatch&,
            const DimensionedField<vector, volMesh>&,
            const dictionary&
        );

        //- Construct by mapping given
        //  analyticalCantileverTractionFvPatchVectorField onto a new patch
        analyticalCantileverTractionFvPatchVectorField
        (
            const analyticalCantileverTractionFvPatchVectorField&,
            const fvPatch&,
            const DimensionedField<vector, volMesh>&,
            const fvPatchFieldMapper&
        );

        //- Construct as copy
        analyticalCantileverTractionFvPatchVectorField
        (
            const analyticalCantileverTractionFvPatchVectorField&
#ifdef OPENFOAM_ORG
        ) = delete;
#else
        );

        //- Construct and return a clone
        virtual tmp<fvPatchVectorField> clone() const
        {
            return tmp<fvPatchVectorField>
            (
                new analyticalCantileverTractionFvPatchVectorField(*this)
            );
        }
#endif

        //- Construct as copy setting internal field reference
        analyticalCantileverTractionFvPatchVectorField
        (
            const analyticalCantileverTractionFvPatchVectorField&,
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
                new analyticalCantileverTractionFvPatchVectorField(*this, iF)
            );
        }


    // Member functions

            //- Return face quadrature values.
            // Used for high order solvers, input is position of points
            virtual autoPtr<CompactListList<vector>> evaluateQuadrature
            (
                const CompactListList<point>& faceQuadPoints
            ) const;

        // Mapping functions

            //- Map (and resize as needed) from self given a mapping object
            virtual void autoMap
            (
                const fvPatchFieldMapper&
            );

            //- Reverse map the given fvPatchField onto this fvPatchField
            virtual void rmap
            (
                const fvPatchVectorField&,
                const labelList&
            );


        //- Update the coefficients associated with the patch field
        virtual void updateCoeffs();

        //- Write
        virtual void write(Ostream&) const;
};


// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //

} // End namespace Foam

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //

#endif

// ************************************************************************* //
