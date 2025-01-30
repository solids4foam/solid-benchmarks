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
    BoussinesqProblemAnalyticalSolution

Description
    FunctionObject that generates the analytical solution for elastic
    half-space loaded with concetrated force

    The solution is taken from
        Johnson, K., Contact Mechanics, Cambridge University, 1985.

    The analytical solution requires the following inputs:
        - force : Applied concetrated force
        - E : Young's modulus
        - nu : Poisson's ratio

Author
    Ivan Batistic & Philip Cardiff, UCD. All rights reserved.

SourceFiles
    BoussinesqProblemAnalyticalSolution.C

\*---------------------------------------------------------------------------*/

#ifndef BoussinesqProblemAnalyticalSolution_H
#define BoussinesqProblemAnalyticalSolution_H

#include "functionObject.H"
#include "dictionary.H"
#include "fvMesh.H"
#include "OFstream.H"

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //

namespace Foam
{

/*---------------------------------------------------------------------------*\
                        Class BoussinesqProblemAnalyticalSolution Declaration
\*---------------------------------------------------------------------------*/

class BoussinesqProblemAnalyticalSolution
:
    public functionObject
{
    // Private data

        //- Name
        const word name_;

        //- Reference to main object registry
        const Time& time_;

        //- Beam end traction
        const vector force_;

        //- Young's modulus
        const scalar E_;

        //- Poisson's ratio
        const scalar nu_;


    // Private Member Functions

        //- Calculate stress tensor for given point
        symmTensor BoussinesqProblemStress(const vector& C);

        //- Calculate displacement vector for given point
        vector BoussinesqProblemDisplacement(const vector& C);

        //- Write data
        bool writeData();

        //- Disallow default bitwise copy construct
        BoussinesqProblemAnalyticalSolution
        (
            const BoussinesqProblemAnalyticalSolution&
        );

        //- Disallow default bitwise assignment
        void operator=(const BoussinesqProblemAnalyticalSolution&);


public:

    //- Runtime type information
    TypeName("BoussinesqProblemAnalyticalSolution");


    // Constructors

        //- Construct from components
        BoussinesqProblemAnalyticalSolution
        (
            const word& name,
            const Time&,
            const dictionary&
        );


    // Member Functions

        //- start is called at the start of the time-loop
        virtual bool start();

        //- execute is called at each ++ or += of the time-loop
#if FOAMEXTEND
        virtual bool execute(const bool forceWrite);
#else
        virtual bool execute();
#endif

        //- Called when time was set at the end of the Time::operator++
        virtual bool timeSet()
        {
            return true;
        }

        //- Read and set the function object if its data has changed
        virtual bool read(const dictionary& dict);

#ifdef OPENFOAMESIORFOUNDATION
        //- Write
        virtual bool write();
#endif

#ifndef OPENFOAMESIORFOUNDATION
        //- Update for changes of mesh
        virtual void updateMesh(const mapPolyMesh&)
        {}

        //- Update for changes of mesh
        virtual void movePoints(const pointField&)
        {}
#endif
};


// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //

} // End namespace Foam

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //

#endif

// ************************************************************************* //
