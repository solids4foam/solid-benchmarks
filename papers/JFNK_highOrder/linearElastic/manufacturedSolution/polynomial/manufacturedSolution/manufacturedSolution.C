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
#include "tetPoints.H"
#include "tetQuadrature.H"
#include "polyMeshTetDecomposition.H"

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
    //scalar gV = 0.0;
    vector totalBodyForce = vector::zero;

    if (highOrderIntegration_)
    {
        // Get interpolation order
        const dictionary& hoDict = solidModelDict().subDict("highOrderCoeffs");

        const label N = readInt(hoDict.subDict("LRECoeffs").lookup("N"));

        const fvMesh& mesh = mesh_;
        const List<cell>& cells = mesh.cells();
        const pointField& pts = mesh.points();
        //const scalarField& V = mesh.V();

        // Loop over cells
        forAll (cells, cellI)
        {
            const cellShape& shape = mesh.cellShapes()[cellI];

            // Get the vertices (points) of the current cell
            const labelList& cellPoints = mesh.cellPoints()[cellI];
            const point& cellC = mesh.C()[cellI];
            const cell& c = mesh.cells()[cellI];

            // // Handle tetrahedral cells
            if (shape.model() == cellModel::ref(cellModel::TET))
            {
                const tetPoints tet =
                    tetPoints
                    (
                        pts[cellPoints[0]],
                        pts[cellPoints[1]],
                        pts[cellPoints[2]],
                        pts[cellPoints[3]]
                     );

                // Get tet quadrature points and their weight
                const tetQuadrature tq(tet, N);
                const List<point>& tetQP = tq.points();
                const List<scalar>& tetQW = tq.weights();

                // Loop over quadrature points and calculate contribution to
                // cell body force vector
                forAll(tetQP, i)
                {
                     const vector& quadPoint = tetQP[i];
                     const scalar& weight = tetQW[i];
                     const vector bodyForce = calculateBodyForce(quadPoint);

                     bodyForcesI[cellI] += weight * bodyForce;
                }
            }
            else
            {
                scalar cellV = 0.0;

                // Storage for per-cell tets
                DynamicList<tetPoints> cellTets;

                // Loop over faces of the cell
                forAll(c, fI)
                {
                    const label faceI = c[fI];
                    const face& f = mesh.faces()[faceI];
                    const label nTri = f.nTriangles();

                    faceList triFaces(nTri);
                    label t2 = 0;
                    const label t1 = f.triangles(mesh.points(), t2, triFaces);

                    if (nTri != t1 || nTri != t2)
                    {
                        FatalErrorInFunction
                            << "Face triangulation mismatch on cell " << cellI
                            << exit(FatalError);
                    }

                    // For each triangular face, make a tet with the cell centroid
                    forAll(triFaces, triI)
                    {
                        const face& triF = triFaces[triI];

                        // Build tet: (cell centroid + triangle)
                        tetPoints t(
                                      cellC,
                                      mesh.points()[triF[0]],
                                      mesh.points()[triF[1]],
                                      mesh.points()[triF[2]]
                                      );
                        tetPointRef tet(t);
                        cellV += mag(tet.mag());
                        //gV += mag(tet.mag());
                        cellTets.append(t);
                    }
                }

                //Info<< cellV << endl;
                //Info<< mesh.V()[cellI] << endl;
                //Info << nl << endl;

                // Now integrate over quadrature points inside each tet
                forAll(cellTets, tetI)
                {
                    const tetPoints& subTet = cellTets[tetI];
                    tetPointRef subRef(subTet);

                    tetQuadrature tq(subTet, N);
                    const List<point>& tetQP = tq.points();
                    const List<scalar>& tetQW = tq.weights();

                    // Scale weights by tet volume relative to cell volume
                    //const scalar scaleW = subTet.mag() / cellV;
                    //const scalar scaleW = mag(subRef.mag()) / cellV;
                    forAll(tetQP, i)
                    {
                        const vector& quadPoint = tetQP[i];
                        const scalar& weight = tetQW[i];
                        const vector bodyForce = calculateBodyForce(quadPoint);

                        //bodyForcesI[cellI] += scaleW * weight * bodyForce;
                        bodyForcesI[cellI] +=  weight * bodyForce * mag(subRef.mag());
                    }
                }
                bodyForcesI[cellI] /= cellV;
                totalBodyForce += cellV*bodyForcesI[cellI];
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

    const vector analyticalTotalBodyForce =
        vector
        (
            -0.0008*((6*lambda_ + 14*mu_)*ax_+(2*lambda_+2*mu_)*az_),
            -0.0008*((6*lambda_ + 14*mu_)*ay_+(2*lambda_+2*mu_)*ax_),
            -0.0008*((6*lambda_ + 14*mu_)*az_+(2*lambda_+2*mu_)*ay_)
        );

    const scalar relError =
        ((mag(totalBodyForce)-mag(analyticalTotalBodyForce))
      / mag(analyticalTotalBodyForce))*100;

    Info<<"Total body force:            " << totalBodyForce
        << "\nAnalytical total body force: " << -analyticalTotalBodyForce
        << "\nRelative error: " << relError  << endl;


    bodyForcesPtr_().correctBoundaryConditions();
}


// * * * * * * * * * * * * * * * * Constructors  * * * * * * * * * * * * * * //

Foam::manufacturedSolution::manufacturedSolution
(
    const fvMesh& mesh,
    const scalar E,
    const scalar ax,
    const scalar ay,
    const scalar az,
    const scalar nu,
    const Switch highOrderIntegration
)
:
    mesh_(mesh),
    ax_(ax),
    ay_(ay),
    az_(az),
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
     ),
     bodyForcesPtr_(nullptr)
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
    ax_(readScalar(dict.lookup("ax"))),
    ay_(readScalar(dict.lookup("ay"))),
    az_(readScalar(dict.lookup("az"))),
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
     ),
    bodyForcesPtr_(nullptr)
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

    const scalar traceEps = (3*ax_+ az_)*sqr(point.x()) + (ax_+3*ay_)*sqr(point.y()) + (ay_+3*az_)*sqr(point.z());

    sigma.xx() =
        lambda*traceEps + 2.0*mu*ax_*(3.0*sqr(point.x())+sqr(point.y()));

    sigma.yy() =
        lambda*traceEps + 2.0*mu*ay_*(3.0*sqr(point.y())+sqr(point.z()));

    sigma.zz() =
        lambda*traceEps + 2.0*mu*az_*(3.0*sqr(point.z())+sqr(point.x()));

    sigma.xy() = 2.0*ax_*mu*point.x()*point.y();

    // sigma.yx() = sigma.xy();

    sigma.yz() = 2.0*ay_*mu*point.y()*point.z();

    // sigma.zy() = sigma.yz();

    sigma.xz() = 2.0*az_*mu*point.x()*point.z();

    // sigma.zx() = sigma.xz();

    return sigma;
}


Foam::symmTensor Foam::manufacturedSolution::calculateStrain
(
    const vector& point
)
{
    symmTensor epsilon = symmTensor::zero;

    epsilon.xx() = ax_*(3.0*sqr(point.x())+sqr(point.y()));

    epsilon.yy() = ay_*(3.0*sqr(point.y())+sqr(point.z()));

    epsilon.zz() = az_*(3.0*sqr(point.z())+sqr(point.x()));

    epsilon.xy() = ax_* point.x()*point.y();

    // epsilon.yx() = epsilon.xy();

    epsilon.yz() = ay_* point.y()*point.z();

    // epsilon.zy() = epsilon.yz();

    epsilon.xz() = az_ * point.x()*point.z();

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
        ax_*(point.x()*point.x()*point.x() + point.x()*point.y()*point.y()),
        ay_*(point.y()*point.y()*point.y() + point.y()*point.z()*point.z()),
        az_*(point.z()*point.z()*point.z() + point.z()*point.x()*point.x())
    );
}


Foam::vector Foam::manufacturedSolution::calculateBodyForce
(
    const vector& point
) const
{
    const scalar x = point.x();
    const scalar y = point.y();
    const scalar z = point.z();

    vector bodyForce = vector::zero;

    bodyForce[vector::X] = -2*x*(lambda_*(3*ax_+az_)+7*mu_*ax_ + mu_*az_);
    bodyForce[vector::Y] = -2*y*(lambda_*(3*ay_+ax_)+7*mu_*ay_ + mu_*ax_);
    bodyForce[vector::Z] = -2*z*(lambda_*(3*az_+ay_)+7*mu_*az_ + mu_*ay_);
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
