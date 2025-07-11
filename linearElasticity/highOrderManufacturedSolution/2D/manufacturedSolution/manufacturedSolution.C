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

\*----------------------------------------------------------------------------*/

#include "manufacturedSolution.H"
#include "mathematicalConstants.H"

// * * * * * * * * * * * * * * Static Data Members * * * * * * * * * * * * * //

namespace Foam
{
    defineTypeNameAndDebug(manufacturedSolution, 0);
}


// * * * * * * * * * * * * * Private Member Functions  * * * * * * * * * * * //


void Foam::manufacturedSolution::calcBodyForces() const
{
    if (bodyForcesPtr_.valid())
    {
        FatalErrorIn("void Foam::manufacturedSolution::calcBodyForces() const")
            << "Pointer already set" << abort(FatalError);
    }

    const fvMesh& mesh = mesh_;

    bodyForcesPtr_.reset
    (
        new volVectorField
        (
            IOobject
            (
                "bodyForces",
                mesh.time().timeName(),
                mesh,
                IOobject::NO_READ,
                IOobject::NO_WRITE
            ),
            mesh,
            dimensionedVector("zero", dimForce/dimVolume, vector::zero),
            "zeroGradient"
        )
    );

    // Set the body force term
    vectorField& bodyForcesI = bodyForcesPtr_();

    if (true) // second order volume integration using mid-point rule
    {
        const vectorField& C = mesh.C();
        forAll(bodyForcesI, cellI)
        {
            const scalar x = C[cellI].x();
            const scalar y = C[cellI].y();

            bodyForcesI[cellI][vector::X] =
		-(lambda_ + mu_) *
	        (
		    2*Foam::exp(Foam::sqr(x))*Foam::sin(y)
		  - Foam::sin(x)/(y+3)
	          + 4*Foam::sqr(x)*Foam::exp(Foam::sqr(x))*Foam::sin(y)
		)
	        - mu_*Foam::exp(Foam::sqr(x))*Foam::sin(y)*(4*Foam::sqr(x) + 1.0);


            bodyForcesI[cellI][vector::Y] =
                mu_ *
		(
		    Foam::sin(y)
		  + Foam::cos(x)/Foam::sqr(y+3)
		  + Foam::log(y+3)*Foam::cos(x)
		)
		+ (lambda_ + mu_) *
		(
		    Foam::sin(y)
		  + Foam::cos(x))/Foam::sqr(y+3)
		  - 2*x*Foam::exp(Foam::sqr(x)*Foam::cos(y)
		 );

            bodyForcesI[cellI][vector::Z] = 0.0;
        }
    }

    bodyForcesPtr_().correctBoundaryConditions();
}


// * * * * * * * * * * * * * * * * Constructors  * * * * * * * * * * * * * * //

Foam::manufacturedSolution::manufacturedSolution
(
    const fvMesh& mesh,
    const scalar E,
    const scalar nu
)
:
    mesh_(mesh),
    E_(E),
    nu_(nu),
    mu_(E_/(2.0*(1.0 + nu_))),
    lambda_((E_*nu_)/((1.0 + nu_)*(1.0 - 2.0*nu_)))
{
    if (E_ < SMALL || nu_ < SMALL)
    {
        FatalErrorIn("manufacturedSolution::manufacturedSolution(...)")
            << "E and nu should be positive!"
            << abort(FatalError);
    }
}


Foam::manufacturedSolution::manufacturedSolution
(
    const fvMesh& mesh,
    const dictionary& dict
)
:
    mesh_(mesh),
    E_(readScalar(dict.lookup("E"))),
    nu_(readScalar(dict.lookup("nu"))),
    mu_(E_/(2.0*(1.0 + nu_))),
    lambda_((E_*nu_)/((1.0 + nu_)*(1.0 - 2.0*nu_)))
{
    if (E_ < SMALL || nu_ < SMALL)
    {
        FatalErrorIn("manufacturedSolution::manufacturedSolution(...)")
            << "E and nu should be positive!"
            << abort(FatalError);
    }
}

// * * * * * * * * * * * * * * * Member Functions  * * * * * * * * * * * * * //


Foam::symmTensor Foam::manufacturedSolution::calculateStress
(
    const vector& point
)
{
    symmTensor sigma = symmTensor::zero;

    // Shear modulus
    const scalar mu = E_/(2.0*(1.0 + nu_));

    // Lambda parameter
    const scalar lambda = (E_*nu_)/((1.0 + nu_)*(1.0 - 2.0*nu_));

    sigma.xx() =
        lambda*Foam::sin(2*point.y())*Foam::sin(point.z())*0.0;

    sigma.yy() = mu* 0.0;

    sigma.zz() = lambda*0.0;

    sigma.xy() = 0.0;

    // sigma.yx() = sigma.xy();

    sigma.yz() = 0.0;

    // sigma.zy() = sigma.yz();

    sigma.xz() = 0.0;

    // sigma.zx() = sigma.xz();

    return sigma;
}


Foam::symmTensor Foam::manufacturedSolution::calculateStrain
(
    const vector& point
)
{
    symmTensor epsilon = symmTensor::zero;

    epsilon.xx() = 0.0;
    epsilon.yy() = 0.0;
    epsilon.zz() = 0.0;
    epsilon.xy() = 0.0;
    // epsilon.yx() = epsilon.xy();
    epsilon.yz() = 0.0;
    // epsilon.zy() = epsilon.yz();
    epsilon.xz() = 0.0;
    // epsilon.zx() = epsilon.xz();

    return epsilon;
}

Foam::vector Foam::manufacturedSolution::calculateDisplacement
(
    const vector& point
)
{
    return vector
    (
        Foam::exp(Foam::sqr(point.x()))*Foam::sin(point.y()),
        Foam::log(3+point.y())*Foam::cos(point.x()) + Foam::sin(point.y()),
        0.0
    );
}


const Foam::volVectorField& Foam::manufacturedSolution::bodyForces() const
{
    if (!bodyForcesPtr_.valid())
    {
        calcBodyForces();
    }

    return bodyForcesPtr_();
}

// ************************************************************************* //
