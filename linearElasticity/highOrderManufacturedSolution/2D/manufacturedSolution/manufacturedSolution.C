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

    if (highOrderIntegration_)
    {
	if (mesh_.solutionD()[vector::Z] > -1)
	{
	    FatalErrorIn("void manufacturedSolution::calcBodyForces()")
		<< "The empty direction must be z!"
		<< abort(FatalError);
	}

	// Get interpolation order
	const dictionary& hoDict = solidModelDict().subDict("highOrderCoeffs");

	const label N = 10;//readInt(hoDict.subDict("LRECoeffs").lookup("N"));

	Info<<"Body force is integrated exactly for polynomials of order: "
	    << N << endl;

	const fvMesh& mesh = mesh_;
	const pointField& pts = mesh.points();
	const faceList& faces = mesh.faces();
	const surfaceVectorField Sn(mesh.Sf()/mesh.magSf());

        // Loop over cells
	forAll (mesh.cells(), cellI)
	{
	    const cell& c = mesh.cells()[cellI];

	    // Get index of face with positive z normal
	    label faceI = -1;
	    forAll(c, i)
	    {
		label faceIndex = c[i];

		if (faceIndex > mesh.nInternalFaces())
		{
		    const label patchID =
			mesh.boundaryMesh().whichPatch(faceIndex);

		    if (mesh.boundaryMesh()[patchID].type() == "empty")
		    {
			faceI = faceIndex;
			break;
		    }
		}
	    }
	    if (faceI == -1)
	    {
		FatalErrorInFunction
		    << "Inavalid face index, something went wrong!"
		    << exit(FatalError);
	    }

	    const scalar& faceArea = mag(mesh.faceAreas()[faceI]);
	    const face& f = faces[faceI];
            const label nTri = f.nTriangles();

	    // Have face triangulate itself (results in faceList)
	    faceList triFaces(nTri);
	    label nTmp = 0;

	    f.triangles(pts, nTmp, triFaces);

	    // Loop over face triangles
	    forAll(triFaces, triFaceI)
	    {
	        const face& triF = triFaces[triFaceI];

		// Triangle points, forcing z=0 becouse we can have face on
		// poitive or negative empty direction
		const point a = point(pts[triF[0]].x(), pts[triF[0]].y(), 0.0);
		const point b = point(pts[triF[1]].x(), pts[triF[1]].y(), 0.0);
		const point c = point(pts[triF[2]].x(), pts[triF[2]].y(), 0.0);

		// Construct triPoints (triangle)
		const triPoints triangle = triPoints(a, b, c);

		const scalar triArea = triangle.mag();

		const scalar scaleW = triArea / faceArea;

		// Get triangle quadrature points and their weight
		const triQuadrature tq(triangle, N);
		const List<point>& triangleQP = tq.points();
		const List<scalar>& triangleQPweights = tq.weights();

		// Loop over quadrature points and calculate contribution to
		// cell body force vector
		forAll(triangleQP, i)
		{
		     const vector& quadPoint = triangleQP[i];
		     const scalar& weight = triangleQPweights[i];
		     const vector bodyForce = calculateBodyForce(quadPoint);

		     bodyForcesI[cellI] += scaleW * weight * bodyForce;
		}
	    }
	}
    }
    else
    {
	// second order volume integration using mid-point rule
        const vectorField& cellCentres = mesh.C();
        forAll(bodyForcesI, cellI)
        {
            const vector& cellCentre = cellCentres[cellI];

	    bodyForcesI[cellI] = calculateBodyForce(cellCentre);
        }
    }

    bodyForcesPtr_().correctBoundaryConditions();
}


// * * * * * * * * * * * * * * * * Constructors  * * * * * * * * * * * * * * //

Foam::manufacturedSolution::manufacturedSolution
(
    const fvMesh& mesh,
    const scalar E,
    const scalar nu,
    const Switch highOrderIntegration
)
:
    mesh_(mesh),
    E_(E),
    nu_(nu),
    mu_(E_/(2.0*(1.0 + nu_))),
    lambda_((E_*nu_)/((1.0 + nu_)*(1.0 - 2.0*nu_))),
    highOrderIntegration_(highOrderIntegration),
    solidProperties_
    (
        IOobject
        (
            "solidProperties",
            mesh_.time().constant(),
            mesh_,
            IOobject::MUST_READ,
            IOobject::NO_WRITE
        )
    )
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
    lambda_((E_*nu_)/((1.0 + nu_)*(1.0 - 2.0*nu_))),
    highOrderIntegration_
    (
        dict.lookupOrDefault<Switch>("highOrderIntegration", false)
    ),
    solidProperties_
    (
        IOobject
        (
            "solidProperties",
            mesh_.time().constant(),
            mesh_,
            IOobject::MUST_READ,
            IOobject::NO_WRITE
        )
    )
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
	lambda*(Foam::cos(point.y())
       + Foam::cos(point.x())/(point.y() + 3.0)
       + 2.0*point.x()*Foam::exp(Foam::sqr(point.x()))*Foam::sin(point.y()))
       + 4.0*mu*point.x()*Foam::exp(Foam::sqr(point.x()))*Foam::sin(point.y());

    sigma.yy() =
	lambda*(Foam::cos(point.y())
      + Foam::cos(point.x())/(point.y() + 3.0)
      + 2.0*point.x()*Foam::exp(Foam::sqr(point.x()))*Foam::sin(point.y()))
      + 2.0*mu*(Foam::cos(point.y()) + Foam::cos(point.x())/(point.y() + 3.0));

    sigma.zz() =
	lambda*(Foam::cos(point.y())
      + Foam::cos(point.x())/(point.y() + 3.0)
      + 2.0*point.x()*Foam::exp(Foam::sqr(point.x()))*Foam::sin(point.y()));

    sigma.xy() =
	2.0*mu*
	(
	    (Foam::exp(Foam::sqr(point.x()))*Foam::cos(point.y()))/2.0
	  - (Foam::log(point.y() + 3.0)*Foam::sin(point.x()))/2.0
	);

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

    epsilon.xx() =
	2.0*point.x()*Foam::exp(Foam::sqr(point.x()))*Foam::sin(point.y());

    epsilon.xy() =
	Foam::exp(Foam::sqr(point.x()))*Foam::cos(point.y())/2.0
      - Foam::log(point.y()+3.0)*Foam::sin(point.x())/2.0;

    epsilon.yy() = Foam::cos(point.y()) + Foam::cos(point.x())/(point.y()+3.0);

    epsilon.zz() = 0.0;

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

Foam::vector Foam::manufacturedSolution::calculateBodyForce
(
    const vector& point
) const
{
    const scalar x = point.x();
    const scalar y = point.y();

    vector bodyForce = vector::zero;

    bodyForce[vector::X] =
       -(lambda_ + mu_) *
        (
    	    2*Foam::exp(Foam::sqr(x))*Foam::sin(y)
    	  - Foam::sin(x)/(y+3.0)
    	    + 4*Foam::sqr(x)*Foam::exp(Foam::sqr(x))*Foam::sin(y)
    	)
      - mu_*Foam::exp(Foam::sqr(x))*Foam::sin(y)*(4*Foam::sqr(x) + 1.0);


    bodyForce[vector::Y] =
        mu_ *
    	(
    	    Foam::sin(y)
    	  + Foam::cos(x)/Foam::sqr(y+3.0)
    	  + Foam::log(y+3.0)*Foam::cos(x)
    	)
      + (lambda_ + mu_) *
    	(
    	    Foam::sin(y)
    	  + Foam::cos(x)/Foam::sqr(y+3.0)
    	  - 2*x*Foam::exp(Foam::sqr(x))*Foam::cos(y)
    	 );

    bodyForce[vector::Z] = 0.0;

    return -bodyForce;
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
