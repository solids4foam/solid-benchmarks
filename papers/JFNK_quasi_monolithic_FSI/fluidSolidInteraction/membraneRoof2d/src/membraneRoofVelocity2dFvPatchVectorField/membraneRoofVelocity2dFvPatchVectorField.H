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

Class
    Foam::membraneRoofVelocity2dFvPatchVectorField

Description
    Prescribed inlet velocity profile from:

    Von Scheven, M., and E. Ramm. Strong coupling schemes for interaction of
    thin‐walled structures and incompressible flows, International journal
    for numerical methods in engineering, 87.1‐5 (2011): 214-231.

SourceFiles
    membraneRoofVelocity2dFvPatchVectorField.C

Author
    Ivan Batistsic, UCD.
    Philip Cardiff, UCD. All rights reserved.
\*---------------------------------------------------------------------------*/

#ifndef membraneRoofVelocity2dFvPatchVectorField_H
#define membraneRoofVelocity2dFvPatchVectorField_H

#include "fvPatchFields.H"
#include "fixedValueFvPatchFields.H"

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //

namespace Foam
{

/*---------------------------------------------------------------------------* \
               Class membraneRoofVelocity2dFvPatchVectorField Declaration
\*---------------------------------------------------------------------------*/


class membraneRoofVelocity2dFvPatchVectorField
:
    public fixedValueFvPatchVectorField
{
public:

    //- Runtime type information
    TypeName("membraneRoofVelocity2d");


    // Constructors

        //- Construct from patch and internal field
        membraneRoofVelocity2dFvPatchVectorField
        (
            const fvPatch&,
            const DimensionedField<vector, volMesh>&
        );

        //- Construct from patch, internal field and dictionary
        membraneRoofVelocity2dFvPatchVectorField
        (
            const fvPatch&,
            const DimensionedField<vector, volMesh>&,
            const dictionary&
        );

        //- Construct by mapping onto a new patch
        membraneRoofVelocity2dFvPatchVectorField
        (
            const membraneRoofVelocity2dFvPatchVectorField&,
            const fvPatch&,
            const DimensionedField<vector, volMesh>&,
            const fvPatchFieldMapper&
        );

        //- Construct as copy
        membraneRoofVelocity2dFvPatchVectorField
        (
            const membraneRoofVelocity2dFvPatchVectorField&
#ifdef OPENFOAM_ORG
        ) = delete;
#else
        );

        //- Construct and return a clone
        virtual tmp<fvPatchVectorField> clone() const
        {
            return tmp<fvPatchVectorField>
            (
                new membraneRoofVelocity2dFvPatchVectorField(*this)
            );
        }
#endif

        //- Construct as copy setting internal field reference
        membraneRoofVelocity2dFvPatchVectorField
        (
            const membraneRoofVelocity2dFvPatchVectorField&,
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
                new membraneRoofVelocity2dFvPatchVectorField(*this, iF)
            );
        }


    //- Destructor
    virtual ~membraneRoofVelocity2dFvPatchVectorField();


    // Member functions

        //- Map (and resize as needed) from self given a mapping object
        virtual void autoMap
        (
            const fvPatchFieldMapper&
        );

        //- Reverse map the given fvPatchField onto this fvPatchField
        virtual void rmap
        (
            const fvPatchField<vector>&,
            const labelList&
        );

        //- Update the coefficients associated with the patch field
        virtual void updateCoeffs();
};

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //

} // End namespace Foam

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //

#endif

// ************************************************************************* //
