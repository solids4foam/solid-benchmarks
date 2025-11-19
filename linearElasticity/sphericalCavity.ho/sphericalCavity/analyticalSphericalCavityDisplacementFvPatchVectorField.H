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
    Foam::analyticalSphericalCavityDisplacementFvPatchVectorField

Description
    Traction boundary condition for a spherical cavity in an infinite elastic
    medium subjected to a distant stress test case to enforce analytical
    tractions at the boundaries.

Author
   Philip Cardiff, UCD.
   Ivan Batistic, UCD.

SourceFiles
    analyticalSphericalCavityDisplacementFvPatchVectorField.C

Author
    Philip Cardiff, UCD. All rights reserved.

\*---------------------------------------------------------------------------*/

#ifndef analyticalSphericalCavityDisplacementFvPatchVectorField_H
#define analyticalSphericalCavityDisplacementFvPatchVectorField_H

#include "fixedDisplacementFvPatchVectorField.H"

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //

namespace Foam
{

/*---------------------------------------------------------------------------*\
                 Class analyticalSphericalCavityDisplacementFvPatch Declaration
\*---------------------------------------------------------------------------*/

class analyticalSphericalCavityDisplacementFvPatchVectorField
:
    public fixedDisplacementFvPatchVectorField
{
    // Private Data

        //- Far field traction
        //  It is assumed that it acts in the positive Z direction
        const scalar T0_;

        //- Hole radius
        const scalar cavityR_;

        //- Poisson's ration
        const scalar nu_;

        //- Young modulus
        const scalar E_;

        //- A copy of the constructor dict
        const dictionary dict_;


public:

    //- Runtime type information
    TypeName("analyticalSphericalCavityDisplacement");


    // Constructors

        //- Construct from patch and internal field
        analyticalSphericalCavityDisplacementFvPatchVectorField
        (
            const fvPatch&,
            const DimensionedField<vector, volMesh>&
        );

        //- Construct from patch, internal field and dictionary
        analyticalSphericalCavityDisplacementFvPatchVectorField
        (
            const fvPatch&,
            const DimensionedField<vector, volMesh>&,
            const dictionary&
        );

        //- Construct by mapping given analyticalSphericalCavityDisplacementFvPatchVectorField
        //  onto a new patch
        analyticalSphericalCavityDisplacementFvPatchVectorField
        (
            const analyticalSphericalCavityDisplacementFvPatchVectorField&,
            const fvPatch&,
            const DimensionedField<vector, volMesh>&,
            const fvPatchFieldMapper&
        );

        //- Construct as copy
        analyticalSphericalCavityDisplacementFvPatchVectorField
        (
            const analyticalSphericalCavityDisplacementFvPatchVectorField&
#ifdef OPENFOAM_ORG
        ) = delete;
#else
        );

        //- Construct and return a clone
        virtual tmp<fvPatchVectorField> clone() const
        {
            return tmp<fvPatchVectorField>
            (
                new analyticalSphericalCavityDisplacementFvPatchVectorField(*this)
            );
        }
#endif

        //- Construct as copy setting internal field reference
        analyticalSphericalCavityDisplacementFvPatchVectorField
        (
            const analyticalSphericalCavityDisplacementFvPatchVectorField&,
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
                new analyticalSphericalCavityDisplacementFvPatchVectorField(*this, iF)
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
