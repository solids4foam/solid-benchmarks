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

Class
    concentratedForceFvPatchVectorField

Description
    solidTraction boundary condition for concentrated force on the specific 
    location on the traction-free patch. Force vector can be time-varying.

    Note:
    Force is applied to one face, closest to the prescribed force location.
    The closest face is found on the initial undeformed configuration.


Author
    Ivan Batistic & Philip Cardiff, UCD.

SourceFiles
    concentratedForceFvPatchVectorField.C

\*---------------------------------------------------------------------------*/

#ifndef concentratedForceFvPatchVectorField_H
#define concentratedForceFvPatchVectorField_H

#include "fvPatchFields.H"
#include "solidTractionFvPatchVectorField.H"
#include "interpolationTable.H"

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //

namespace Foam
{

/*---------------------------------------------------------------------------*\
             Class concentratedForceFvPatchVectorField Declaration
\*---------------------------------------------------------------------------*/

class concentratedForceFvPatchVectorField
:
    public solidTractionFvPatchVectorField
{

    // Private Data

        //- Constant force
        vector force_;

        //- Constant force location
        vector forceLocation_;
       
        //- Force face ID
        label faceID_;
        
        //- Time-varying force vector
        interpolationTable<vector> forceSeries_;
        
public:

    //- Runtime type information
    TypeName("concentratedForce");


    // Constructors

        //- Construct from patch and internal field
        concentratedForceFvPatchVectorField
        (
            const fvPatch&,
            const DimensionedField<vector, volMesh>&
        );

        //- Construct from patch, internal field and dictionary
        concentratedForceFvPatchVectorField
        (
            const fvPatch&,
            const DimensionedField<vector, volMesh>&,
            const dictionary&
        );

        //- Construct by mapping given
        //  concentratedForceFvPatchVectorField onto a new patch
        concentratedForceFvPatchVectorField
        (
            const concentratedForceFvPatchVectorField&,
            const fvPatch&,
            const DimensionedField<vector, volMesh>&,
            const fvPatchFieldMapper&
        );

        //- Construct as copy
        concentratedForceFvPatchVectorField
        (
            const concentratedForceFvPatchVectorField&
#ifdef OPENFOAMFOUNDATION
        ) = delete;
#else
        );

        //- Construct and return a clone
        virtual tmp<fvPatchVectorField> clone() const
        {
            return tmp<fvPatchVectorField>
            (
                new concentratedForceFvPatchVectorField(*this)
            );
        }
#endif

        //- Construct as copy setting internal field reference
        concentratedForceFvPatchVectorField
        (
            const concentratedForceFvPatchVectorField&,
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
                new concentratedForceFvPatchVectorField(*this, iF)
            );
        }


    // Member functions

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
