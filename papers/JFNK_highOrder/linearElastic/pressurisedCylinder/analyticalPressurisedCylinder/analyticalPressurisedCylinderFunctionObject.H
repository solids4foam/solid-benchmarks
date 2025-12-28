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
    analyticalPressurisedCylinder

Description
    FunctionObject that generates analytical solution for pressurised cylinder.

Author
    Ivan Batistic, UCD.

SourceFiles
    analyticalPressurisedCylinderFunctionObject.C

\*---------------------------------------------------------------------------*/

#ifndef analyticalPressurisedCylinderFunctionObject_H
#define analyticalPressurisedCylinderFunctionObject_H

#include "functionObject.H"
#include "dictionary.H"
#include "fvMesh.H"
#include "OFstream.H"

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //

namespace Foam
{

/*---------------------------------------------------------------------------*\
         Class analyticalPressurisedCylinderFunctionObject Declaration
\*---------------------------------------------------------------------------*/

class analyticalPressurisedCylinderFunctionObject
:
    public functionObject
{
    // Private data

        //- Name
        const word name_;

        //- Reference to main object registry
        const Time& time_;

        //- Axis, i.e. z coordinate
        vector axis_;

        //- Polar coordinate system origin
        const vector origin_;

        //- Pressure
        const scalar p_;

        //- Inner radius
        const scalar Ri_;

        //- Outer radius
        const scalar Ro_;

        //- Young's modulus
        const scalar E_;

        //- Poisson's ratio
        const scalar nu_;

        //- Calculate cell displacement fields
        const Switch cellDisplacement_;

        //- Calculate point displacement fields
        const Switch pointDisplacement_;

        //- Calculate cell stress fields
        const Switch cellStress_;

        //- Calculate point stress fields
        const Switch pointStress_;


    // Private Member Functions

        //- Analitical displacement for point
        vector displacement(const vector& pos) const;

        //- Analytical stress for point
        symmTensor stress(const vector& pos) const;

        //- Write data
        bool writeData();

        //- Disallow default bitwise copy construct
        analyticalPressurisedCylinderFunctionObject
        (
            const analyticalPressurisedCylinderFunctionObject&
        );

        //- Disallow default bitwise assignment
        void operator=(const analyticalPressurisedCylinderFunctionObject&);


public:

    //- Runtime type information
    TypeName("analyticalPressurisedCylinder");


    // Constructors

        //- Construct from components
        analyticalPressurisedCylinderFunctionObject
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

#ifdef OPENFOAM_NOT_EXTEND
        //- Write
        virtual bool write();
#else
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
