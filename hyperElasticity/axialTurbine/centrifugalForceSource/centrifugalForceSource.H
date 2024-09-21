/*---------------------------------------------------------------------------*\
  =========                 |
  \\      /  F ield         | OpenFOAM: The Open Source CFD Toolbox
   \\    /   O peration     |
    \\  /    A nd           | www.openfoam.com
     \\/     M anipulation  |
-------------------------------------------------------------------------------
    Copyright (C) 2015-2017 OpenFOAM Foundation
    Copyright (C) 2020 OpenCFD Ltd.
-------------------------------------------------------------------------------
License
    This file is part of OpenFOAM.

    OpenFOAM is free software: you can redistribute it and/or modify it
    under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    OpenFOAM is distributed in the hope that it will be useful, but WITHOUT
    ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
    FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
    for more details.

    You should have received a copy of the GNU General Public License
    along with OpenFOAM.  If not, see <http://www.gnu.org/licenses/>.

Class
    Foam::fv::centrifugalForceSource

Group
    grpFvOptionsSources

Description
    Calculates a centrifugal force source term for a solid solver.

Usage
    Minimal example by using \c constant/fvOptions:
    \verbatim
    centrifugalForceSource1
    {
        // Mandatory entries (unmodifiable)
        type             centrifugalForceSource;
        fields           (D);

        // Mandatory/Optional (inherited) entries
        ...
    }
    \endverbatim

SourceFiles
    centrifugalForceSource.C

Author
    Philip Cardiff

\*---------------------------------------------------------------------------*/

#ifndef centrifugalForceSource_H
#define centrifugalForceSource_H

#include "fvOption.H"
#include "volFields.H"

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //

namespace Foam
{
namespace fv
{

/*---------------------------------------------------------------------------*\
                        Class centrifugalForceSource Declaration
\*---------------------------------------------------------------------------*/

class centrifugalForceSource
:
    public fv::option
{
    // Private Data

        //- Density
        const dimensionedScalar rho_;

        //- Revolutions per minute
        const scalar rpm_;

        //- Angular velocity
        const dimensionedScalar omega_;

        //- Point on the axis
        const vector origin_;

        //- Axis direction
        vector axis_;

        //- Radial vector coordinate
        volVectorField r_;


public:

    //- Runtime type information
    TypeName("centrifugalForceSource");


    // Constructors

        //- Construct from explicit source name and mesh
        centrifugalForceSource
        (
            const word& sourceName,
            const word& modelType,
            const dictionary& dict,
            const fvMesh& mesh
        );

        //- No copy construct
        centrifugalForceSource(const centrifugalForceSource&) = delete;

        //- No copy assignment
        void operator=(const centrifugalForceSource&) = delete;


    //- Destructor
    virtual ~centrifugalForceSource() = default;


    // Member Functions

        //- Add explicit contribution to momentum equation
        virtual void addSup
        (
            const volScalarField&,
            fvMatrix<vector>& eqn,
            const label fieldi
        );

        //- Read source dictionary
        virtual bool read(const dictionary& dict);
};


// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //

} // End namespace fv
} // End namespace Foam

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //

#endif

// ************************************************************************* //
