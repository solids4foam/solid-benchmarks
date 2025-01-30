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
    Foam::analyticalBoussinesqProblemDisplacementFvPatchVectorField

Description
    Displacement field for the problem of concetrated force on elastic
    half-space (Boussinesq problem).

    The solution is taken from
        Johnson, K., Contact Mechanics, Cambridge University, 1985.

    The analytical solution requires the following inputs:
        - force : Applied concetrated force
        - E : Young's modulus
        - nu : Poisson's ratio

SourceFiles
    analyticalBoussinesqProblemDisplacementFvPatchVectorField.C

Author
    Ivan Batistic & Philip Cardiff, UCD.

\*---------------------------------------------------------------------------*/

#ifndef analyticalBoussinesqProblemDisplacementFvPatchVectorField_H
#define analyticalBoussinesqProblemDisplacementFvPatchVectorField_H

#include "fixedDisplacementFvPatchVectorField.H"

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //

namespace Foam
{

/*---------------------------------------------------------------------------*\
                 Class linearDisplacementFvPatch Declaration
\*---------------------------------------------------------------------------*/

class analyticalBoussinesqProblemDisplacementFvPatchVectorField
:
    public fixedDisplacementFvPatchVectorField
{
    // Private Data

        // Young's modulus
        const scalar E_;

        // Poisson's ratio
        const scalar nu_;

        //- Prescribed force
        const vector force_;

public:

    //- Runtime type information
    TypeName("analyticalBoussinesqProblemDisplacement");


    // Constructors

        //- Construct from patch and internal field
        analyticalBoussinesqProblemDisplacementFvPatchVectorField
        (
            const fvPatch&,
            const DimensionedField<vector, volMesh>&
        );

        //- Construct from patch, internal field and dictionary
        analyticalBoussinesqProblemDisplacementFvPatchVectorField
        (
            const fvPatch&,
            const DimensionedField<vector, volMesh>&,
            const dictionary&
        );

        //- Construct by mapping given analyticalBoussinesqProblemDisplacementFvPatchVectorField
        //  onto a new patch
        analyticalBoussinesqProblemDisplacementFvPatchVectorField
        (
            const analyticalBoussinesqProblemDisplacementFvPatchVectorField&,
            const fvPatch&,
            const DimensionedField<vector, volMesh>&,
            const fvPatchFieldMapper&
        );

        //- Construct as copy
        analyticalBoussinesqProblemDisplacementFvPatchVectorField
        (
            const analyticalBoussinesqProblemDisplacementFvPatchVectorField&
#ifdef OPENFOAMFOUNDATION
        ) = delete;
#else
        );

        //- Construct and return a clone
        virtual tmp<fvPatchVectorField> clone() const
        {
            return tmp<fvPatchVectorField>
            (
                new analyticalBoussinesqProblemDisplacementFvPatchVectorField(*this)
            );
        }
#endif

        //- Construct as copy setting internal field reference
        analyticalBoussinesqProblemDisplacementFvPatchVectorField
        (
            const analyticalBoussinesqProblemDisplacementFvPatchVectorField&,
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
                new analyticalBoussinesqProblemDisplacementFvPatchVectorField(*this, iF)
            );
        }



    // Member functions


        // Evaluation functions

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
