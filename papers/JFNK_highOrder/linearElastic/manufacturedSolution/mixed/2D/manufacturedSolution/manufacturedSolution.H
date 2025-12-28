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
    manufacturedSolution

Description
    Class that generates a manufactured displacement solution and related stress
    solution and source term for a solid solver.

    The manufactured solution for displacement takes the form:

    D =
        vector
        (
            e^(x^2)*sin(y),
            ln(3+y)*cos(x) + sin(y),
            0
        )

    Linear elasticity is assumed for calculating the stress and momentum
    equation source term, hence the Young's modulus (E) and Poisson's
    ratio (nu) must be provided.

Author
    Philip Cardiff, UCD.
    Federico Mazzanti, UCD.
    Ivan Batistic, UCD.
    Pablo Castrillo, UCD.

SourceFiles
    manufacturedSolution.C

\*---------------------------------------------------------------------------*/

#ifndef manufacturedSolution_H
#define manufacturedSolution_H

#include "point.H"
#include "symmTensor.H"
#include "vector.H"
#include "fvMesh.H"
#include "volFields.H"
#include "triQuadrature.H"
#include "surfaceFields.H"

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //

namespace Foam
{

/*---------------------------------------------------------------------------*\
                        Class manufacturedSolution Declaration
\*---------------------------------------------------------------------------*/

class manufacturedSolution
{
    // Private data

        //- Const reference to the mesh (need for the body forces field)
        const fvMesh& mesh_;

        //- Young's modulus
        const scalar E_;

        //- Poisson's ratio
        const scalar nu_;

        //- Lame parameters
        const scalar mu_;
        const scalar lambda_;

        //- High order volume integration for body force calculation
        const Switch highOrderIntegration_;

        //- Solid properties dictionary
        mutable IOdictionary solidProperties_;

        //- Body forces
        mutable autoPtr<volVectorField> bodyForcesPtr_;

    // Private Member Functions

        //- Calculate the body forces field
        void calcBodyForces() const;

        //- Return reference to solid properties dictionary
        const dictionary& solidProperties() const
        {
            return solidProperties_;
        }

        //- Return reference to solidModelCoeffs dictionary
        const dictionary& solidModelDict() const
        {
	    const word t = word(solidProperties().lookup("solidModel"));

	    return solidProperties().subDict(t + "Coeffs");
        }

        //- Disallow default bitwise copy construct
        manufacturedSolution
        (
            const manufacturedSolution&
        );

        //- Disallow default bitwise assignment
        void operator=(const manufacturedSolution&);


public:

    //- Runtime type information
    TypeName("manufacturedSolution");


    //- Constructor

        //- Construct from mesh and parameters
        manufacturedSolution
        (
            const fvMesh& mesh,
            const scalar E,
            const scalar nu,
	    const Switch highOrderIntegration = false
        );

        //- Construct from mesh and dictionary
        manufacturedSolution
        (
            const fvMesh& mesh,
            const dictionary& dict
        );

    //- Destructor
    virtual ~manufacturedSolution()
    {}


    // Member Functions

        //- Calculate the body force at the given point
        vector calculateBodyForce(const vector& point) const;

        //- Calculate the stress at the given point
        symmTensor calculateStress(const vector& point);

        //- Calculate the strain at the given point
        symmTensor calculateStrain(const vector& point);

        //- Calculate the stress at the given point
        vector calculateDisplacement(const vector& point);

        //- Body forces
        const volVectorField& bodyForces() const;
};


// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //

} // End namespace Foam

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //

#endif

// ************************************************************************* //
