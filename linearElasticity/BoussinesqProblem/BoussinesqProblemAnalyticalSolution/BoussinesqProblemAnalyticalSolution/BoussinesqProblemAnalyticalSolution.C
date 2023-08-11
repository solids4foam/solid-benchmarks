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

#include "BoussinesqProblemAnalyticalSolution.H"
#include "addToRunTimeSelectionTable.H"
#include "volFields.H"
#include "pointFields.H"
#include "coordinateSystem.H"
#include "symmTensor.H"

// * * * * * * * * * * * * * * Static Data Members * * * * * * * * * * * * * //

namespace Foam
{
    defineTypeNameAndDebug(BoussinesqProblemAnalyticalSolution, 0);

    addToRunTimeSelectionTable
    (
        functionObject,
        BoussinesqProblemAnalyticalSolution,
        dictionary
    );
}


// * * * * * * * * * * * * * Private Member Functions  * * * * * * * * * * * //

Foam::symmTensor
Foam::BoussinesqProblemAnalyticalSolution::BoussinesqProblemStress
(
    const vector& C
)
{
    //Johnson, K., Contact Mechanics; page 51
    symmTensor sigma = symmTensor::zero;
    
    const scalar& nu = nu_;
    const scalar& normalForce = force_.z();
       
    const scalar c = -normalForce/(mathematicalConstant::pi*2);    
    
    const scalar& X = C.x();
    const scalar& Y = C.y();
    const scalar& Z = -C.z();
    const scalar R = 
        Foam::sqrt(Foam::sqr(X) + Foam::sqr(Y) + Foam::sqr(Z));
    const scalar RHO = 
        Foam::sqrt(Foam::sqr(X) + Foam::sqr(Y));

    sigma.xx() = 
        c
      * (   
            ((1-2*nu)/Foam::sqr(RHO))
          * (
               (1-Z/R)*(Foam::sqr(X)-Foam::sqr(Y))/Foam::sqr(RHO) 
             + (Z*Foam::sqr(Y))/Foam::pow(R,3)
            )
          - (3*Z*Foam::sqr(X))/Foam::pow(R,5) 
        ); 
    
    sigma.yy() = 
        c
      * (   
            ((1-2*nu)/Foam::sqr(RHO))
          * (
               (1-Z/R)*(Foam::sqr(Y)-Foam::sqr(X))/Foam::sqr(RHO) 
             + (Z*Foam::sqr(X))/Foam::pow(R,3)
            )
          - (3*Z*Foam::sqr(Y))/Foam::pow(R,5) 
        ); 
    
    sigma.zz() = -3 * c * Foam::pow(Z,3) / Foam::pow(R,5);
    
    sigma.xy() = 
        c
      * (   
            ((1-2*nu)/Foam::sqr(RHO))
          * (
               (1-Z/R)*(X*Y)/Foam::sqr(RHO) - (X*Y*Z)/Foam::pow(R,3)
            )
          - (3*X*Y*Z)/Foam::pow(R,5) 
        ); 
    
    sigma.yz() = 3 * c * Y * Foam::sqr(Z) / Foam::pow(R,5);

    sigma.xz() = 3 * c * X * Foam::sqr(Z) / Foam::pow(R,5);

    return sigma;
}

Foam::vector 
Foam::BoussinesqProblemAnalyticalSolution::BoussinesqProblemDisplacement
(
    const vector& C
)
{
    //Johnson, K., Contact Mechanics; page 51
    vector disp = vector::zero;
    
    const scalar& E = E_;
    const scalar& nu = nu_;
    const scalar& normalForce = force_.z();

    const scalar G = E/(2.0*(1.0+nu));
    const scalar c = -normalForce/(mathematicalConstant::pi*4*G);    
    
    const scalar& X = C.x();
    const scalar& Y = C.y();
    const scalar& Z = -C.z();
    const scalar R = Foam::sqrt(Foam::sqr(X) + Foam::sqr(Y) + Foam::sqr(Z));
    
    disp.x() = c * (X*Z/Foam::pow(R,3) - (1-2*nu)*(X/(R*(R+Z))));
    disp.y() = c * (Y*Z/Foam::pow(R,3) - (1-2*nu)*(Y/(R*(R+Z))));
    disp.z() = -c * (Foam::sqr(Z)/Foam::pow(R,3) + ((2*(1-nu))/R));
    
    return disp;
}


bool Foam::BoussinesqProblemAnalyticalSolution::writeData()
{
    Info<< "BoussinesqProblemAnalyticalSolution:" << nl
        << "Writing analytical solution fields"
        << endl;

    // Lookup the solid mesh
    const fvMesh* meshPtr = NULL;
    if (time_.foundObject<fvMesh>("solid"))
    {
        meshPtr = &(time_.lookupObject<fvMesh>("solid"));
    }
    else
    {
        meshPtr = &(time_.lookupObject<fvMesh>("region0"));
    }
    const fvMesh& mesh = *meshPtr;

    // Cell centre coordinates
    const volVectorField& C = mesh.C();
    const vectorField& CI = C;

    // Analytical stress field
    volSymmTensorField analyticalStress
    (
        IOobject
        (
           "analyticalStress",
           time_.timeName(),
           mesh,
           IOobject::NO_READ,
           IOobject::AUTO_WRITE
        ),
        mesh,
        dimensionedSymmTensor("zero", dimPressure, symmTensor::zero)
    );

    // Analytical displacement field
    volVectorField analyticalDisplacement
    (
        IOobject
        (
           "analyticalDisplacement",
           time_.timeName(),
           mesh,
           IOobject::NO_READ,
           IOobject::AUTO_WRITE
        ),
        mesh,
        dimensionedVector("zero", dimLength, vector::zero)
    );

    symmTensorField& sI = analyticalStress;
    volVectorField& aDI = analyticalDisplacement;

    forAll(sI, cellI)
    {
        sI[cellI] = BoussinesqProblemStress(CI[cellI]);
        aDI[cellI] = BoussinesqProblemDisplacement(CI[cellI]);
    }

    forAll(analyticalStress.boundaryField(), patchI)
    {
        if (mesh.boundary()[patchI].type() != "empty")
        {
#ifdef OPENFOAMESIORFOUNDATION
            symmTensorField& sP = analyticalStress.boundaryFieldRef()[patchI];
            vectorField& aDP = analyticalDisplacement.boundaryFieldRef()[patchI];
#else
            symmTensorField& sP = analyticalStress.boundaryField()[patchI];
            vectorField& aDP = analyticalDisplacement.boundaryField()[patchI];
#endif
            const vectorField& CP = C.boundaryField()[patchI];

            forAll(sP, faceI)
            {
                sP[faceI] = BoussinesqProblemStress(CP[faceI]);
                aDP[faceI] = BoussinesqProblemDisplacement(CP[faceI]);
            }
        }
    }
    analyticalStress.write();
    analyticalDisplacement.write();

    return true;
}

// * * * * * * * * * * * * * * * * Constructors  * * * * * * * * * * * * * * //

Foam::BoussinesqProblemAnalyticalSolution::BoussinesqProblemAnalyticalSolution
(
    const word& name,
    const Time& t,
    const dictionary& dict
)
:
    functionObject(name),
    name_(name),
    time_(t),
    force_(dict.lookup("force")),
    E_(readScalar(dict.lookup("E"))),
    nu_(readScalar(dict.lookup("nu")))
{
    Info<< "Creating " << this->name() << " function object" << endl;

    if (E_ < SMALL || nu_ < SMALL)
    {
        FatalErrorIn(this->name() + " function object constructor")
            << "E and nu should be positive!"
            << abort(FatalError);
    }
}


// * * * * * * * * * * * * * * * Member Functions  * * * * * * * * * * * * * //

bool Foam::BoussinesqProblemAnalyticalSolution::start()
{
    return true;
}


#if FOAMEXTEND
bool Foam::BoussinesqProblemAnalyticalSolution::execute(const bool forceWrite)
#else
bool Foam::BoussinesqProblemAnalyticalSolution::execute()
#endif
{
    return writeData();
}


bool Foam::BoussinesqProblemAnalyticalSolution::read(const dictionary& dict)
{
    return true;
}


#ifdef OPENFOAMESIORFOUNDATION
bool Foam::BoussinesqProblemAnalyticalSolution::write()
{
    return false;
}
#endif

// ************************************************************************* //
