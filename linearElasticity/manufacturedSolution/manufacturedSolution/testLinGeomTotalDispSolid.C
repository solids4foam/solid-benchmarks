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

\*---------------------------------------------------------------------------*/

#include "testLinGeomTotalDispSolid.H"
#include "fvm.H"
#include "fvc.H"
#include "fvMatrices.H"
#include "addToRunTimeSelectionTable.H"
#include "solidTractionFvPatchVectorField.H"
#include "fixedDisplacementZeroShearFvPatchVectorField.H"
#include "symmetryFvPatchFields.H"

#include "manufacturedSolution.H"
#include "leastSquaresGrad.H"
#include "LeastSquaresGrad.H"
#include "centredCPCCellToCellStencilObject.H"
#include <Eigen/Dense>

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //

using namespace std;
using namespace Eigen;

Vector3d compute_weighted_gradient
(
    const vector<Vector3d>& stencil_points, 
    const vector<double>& function_values, 
    const vector<double>& weights
)
{
    int N = stencil_points.size();
    //const int N = 27;

    // Design matrix A for quadratic polynomial fit
    MatrixXd A(N, 10);
    
    for (int i = 0; i < N; ++i)
    {
        double x = stencil_points[i](0) ;
        double y = stencil_points[i](1) ;
        double z = stencil_points[i](2) ;
        A(i, 0) = 1.0;       // constant term
        A(i, 1) = x;         // linear x term
        A(i, 2) = y;         // linear y term
        A(i, 3) = z;         // linear z term
        A(i, 4) = x * x;     // quadratic x^2 term
        A(i, 5) = x * y;     // quadratic xy term
        A(i, 6) = x * z;     // quadratic xz term
        A(i, 7) = y * y;     // quadratic y^2 term
        A(i, 8) = y * z;     // quadratic yz term
        A(i, 9) = z * z;     // quadratic z^2 term
    }
    
    // Convert function_values to Eigen vector
    VectorXd b = VectorXd::Map(function_values.data(), N);

    // Create the weight matrix W as a diagonal matrix
    // VectorXd weightsVec = VectorXd::Map(weights.data(), N);
    // auto W = weightsVec.asDiagonal();
    auto W = VectorXd::Map(weights.data(), N).asDiagonal();
    
    // Solve the weighted least squares problem using QR decomposition
    VectorXd coeffs = (W * A).householderQr().solve(W * b);
    
    // Gradient at the center (x=0, y=0, z=0) is (a1, a2, a3)
    Vector3d gradient;
    gradient << coeffs(1), coeffs(2), coeffs(3);
    
    return gradient;
}

namespace Foam
{

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //

namespace solidModels
{

// * * * * * * * * * * * * * * Static Data Members * * * * * * * * * * * * * //

defineTypeNameAndDebug(testLinGeomTotalDispSolid, 0);
addToRunTimeSelectionTable(solidModel, testLinGeomTotalDispSolid, dictionary);


// * * * * * * * * * * *  Private Member Functions * * * * * * * * * * * * * //


void testLinGeomTotalDispSolid::predict()
{
    Info<< "Applying linear predictor to D" << endl;

    // Predict D using previous time steps
    D() = D().oldTime() + U()*runTime().deltaT();

    // Update gradient of displacement
    mechanical().grad(D(), gradD());

    // Calculate the stress using run-time selectable mechanical law
    mechanical().correct(sigma());
}


void testLinGeomTotalDispSolid::enforceTractionBoundaries
(
    surfaceVectorField& traction,
    const volVectorField& D,
    const surfaceVectorField& n
) const
{
    // Enforce traction conditions
    forAll(D.boundaryField(), patchI)
    {
        if
        (
            isA<solidTractionFvPatchVectorField>
            (
                D.boundaryField()[patchI]
            )
        )
        {
            const solidTractionFvPatchVectorField& tracPatch =
                refCast<const solidTractionFvPatchVectorField>
                (
                    D.boundaryField()[patchI]
                );

            const vectorField& nPatch = n.boundaryField()[patchI];

            traction.boundaryFieldRef()[patchI] =
                tracPatch.traction() - nPatch*tracPatch.pressure();
        }
        else if
        (
            isA<fixedDisplacementZeroShearFvPatchVectorField>
            (
                D.boundaryField()[patchI]
            )
         || isA<symmetryFvPatchVectorField>
            (
                D.boundaryField()[patchI]
            )
        )
        {
            // Unit normals
            const vectorField& nPatch = n.boundaryField()[patchI];

            // Set shear traction to zero
            traction.boundaryFieldRef()[patchI] =
                sqr(nPatch) & traction.boundaryField()[patchI];
        }
    }
}


bool testLinGeomTotalDispSolid::evolveImplicitSegregated()
{
    Info<< "Evolving solid solver using an implicit segregated approach"
        << endl;

    if (predictor_ && newTimeStep())
    {
        predict();
    }

    // Mesh update loop
    do
    {
        int iCorr = 0;
#ifdef OPENFOAM_NOT_EXTEND
        SolverPerformance<vector> solverPerfD;
        SolverPerformance<vector>::debug = 0;
#else
        lduSolverPerformance solverPerfD;
        blockLduMatrix::debug = 0;
#endif

        Info<< "Solving the momentum equation for D" << endl;

        // Momentum equation loop
        do
        {
            // Store fields for under-relaxation and residual calculation
            D().storePrevIter();

            // Linear momentum equation total displacement form
            fvVectorMatrix DEqn
            (
                rho()*fvm::d2dt2(D())
             == fvm::laplacian(impKf_, D(), "laplacian(DD,D)")
              - fvc::laplacian(impKf_, D(), "laplacian(DD,D)")
              + fvc::div(sigma(), "div(sigma)")
              + rho()*g()
              + stabilisation().stabilisation(D(), gradD(), impK_)
              + fvOptions()(ds_, D())
            );

            // Add damping
            if (dampingCoeff().value() > SMALL)
            {
                DEqn += dampingCoeff()*rho()*fvm::ddt(D());
            }

            // Under-relaxation the linear system
            DEqn.relax();

            // Enforce any cell displacements
            solidModel::setCellDisps(DEqn);

            // Solve the linear system
            solverPerfD = DEqn.solve();

            // Fixed or adaptive field under-relaxation
            relaxField(D(), iCorr);

            // Update increment of displacement
            DD() = D() - D().oldTime();

            // Update gradient of displacement
            mechanical().grad(D(), gradD());

            // Update gradient of displacement increment
            gradDD() = gradD() - gradD().oldTime();

            // Update the momentum equation inverse diagonal field
            // This may be used by the mechanical law when calculating the
            // hydrostatic pressure
            const volScalarField DEqnA("DEqnA", DEqn.A());

            // Calculate the stress using run-time selectable mechanical law
            mechanical().correct(sigma());
        }
        while
        (
            !converged
            (
                iCorr,
#ifdef OPENFOAM_NOT_EXTEND
                mag(solverPerfD.initialResidual()),
                cmptMax(solverPerfD.nIterations()),
#else
                solverPerfD.initialResidual(),
                solverPerfD.nIterations(),
#endif
                D()
            )
         && ++iCorr < nCorr()
        );

        // Interpolate cell displacements to vertices
        mechanical().interpolate(D(), gradD(), pointD());

        // Increment of displacement
        DD() = D() - D().oldTime();

        // Increment of point displacement
        pointDD() = pointD() - pointD().oldTime();

        // Velocity
        U() = fvc::ddt(D());
    }
    while (solidModel::mesh().update());

#ifdef OPENFOAM_NOT_EXTEND
    SolverPerformance<vector>::debug = 1;
#else
    blockLduMatrix::debug = 1;
#endif

    return true;
}


bool testLinGeomTotalDispSolid::evolveSnes()
{
    Info<< "Solving the momentum equation for D using PETSc SNES" << endl;

    // Update D boundary conditions
    D().correctBoundaryConditions();

    // Solution predictor
    if (predictor_ && newTimeStep())
    {
        predict();

        // Map the D field to the SNES solution vector
        foamPetscSnesHelper::mapSolutionFoamToPetsc();
    }

    // Solve the nonlinear system and check the convergence
    foamPetscSnesHelper::solve();

    // Retrieve the solution
    // Map the PETSc solution to the D field
    foamPetscSnesHelper::mapSolutionPetscToFoam();

    // Testing MMS
    manufacturedSolution mms(mesh(), solidModelDict());

    // Enforce exact D
    const vectorField& CI = mesh().C();
    vectorField& DI = D();
    forAll(CI, cellI)
    {
        DI[cellI] = mms.calculateDisplacement(CI[cellI]);
    }
    forAll(mesh().C().boundaryField(), patchI)
    {
        const vectorField& CP = mesh().C().boundaryField()[patchI];
        vectorField& DP = D().boundaryFieldRef()[patchI];
        forAll(CP, faceI)
        {
            DP[faceI] = mms.calculateDisplacement(CP[faceI]);
        }
    }

    // Increment of displacement
    DD() = D() - D().oldTime();

    // Velocity
    U() = fvc::ddt(D());

    // Update gradient of displacement
    mechanical().grad(D(), gradD());
    // gradD() = fv::leastSquaresGrad<vector>(mesh()).calcGrad(D(), "grad(D)");
    // gradD() =
    //     fv::LeastSquaresGrad<vector, centredCPCCellToCellStencilObject>
    //     (
    //         mesh(), mesh().gradScheme("testGrad")
    //     ).calcGrad(D(), "grad(D)");

    // Interpolate D to pointD
    //mechanical().interpolate(D(), pointD(), false);

    // Enforce exact pointD
    const vectorField& XI = mesh().points();
    vectorField& pointDI = pointD();
    forAll(XI, pointI)
    {
        pointDI[pointI] = mms.calculateDisplacement(XI[pointI]);
    }

    // Update gradient of displacement
    //surfaceTensorField gradDf(fvc::interpolate(gradD()));
    //mechanical().grad(D(), pointD(), gradD(), gradDf);

    // Least squares quadratic gradient
    tensorField& gradDI = gradD();
    const labelListList& cellCells = mesh().cellCells();
    forAll(gradDI, cellI)
    {
        // Construct the stencil, weights and initialise the function values
        const labelList& curCellCells = cellCells[cellI];
        std::vector<Vector3d> stencil_points(curCellCells.size() + 1);
        std::vector<double> weights(curCellCells.size() + 1, 1.0);
        scalar maxW = 0;
        std::vector<double> function_values(curCellCells.size() + 1, 0.0);
        stencil_points[0] = Vector3d(0, 0, 0);
        forAll(curCellCells, ccI)
        {
            const vector d = CI[curCellCells[ccI]] - CI[cellI];
            stencil_points[ccI + 1] = Vector3d(d.x(), d.y(), d.z());
            weights[ccI + 1] = 1/magSqr(d);
            maxW = max(weights[ccI + 1], maxW);
        }
        // Set central weight to be larger than maxW
        weights[0] = 2*maxW;

        // Calculate the gradients for each component
        for (int cmptI = 0; cmptI < 3; cmptI++)
        {
            // Set the function values
            function_values[0] = 0.0;
            forAll(curCellCells, ccI)
            {
                function_values[ccI + 1] = DI[curCellCells[ccI]][cmptI] - DI[cellI][cmptI];
            }
            const Vector3d gradient =
                compute_weighted_gradient
                (
                    stencil_points, function_values, weights
                );

            // Copy gradient components to gradD
            gradDI[cellI][3*cmptI + 0] = gradient(0);
            gradDI[cellI][3*cmptI + 1] = gradient(1);
            gradDI[cellI][3*cmptI + 2] = gradient(2);
        }
    }

    // Update gradient of displacement increment
    gradDD() = gradD() - gradD().oldTime();

    // Interpolate cell displacements to vertices
    mechanical().interpolate(D(), gradD(), pointD());

    // Increment of point displacement
    pointDD() = pointD() - pointD().oldTime();

    // Calculate the stress using run-time selectable mechanical law
    mechanical().correct(sigma());

    // Enforce exact stress
    symmTensorField& sigmaI = sigma();
    // forAll(CI, cellI)
    // {
    //     sigmaI[cellI] = mms.calculateStress(CI[cellI]);
    // }
    forAll(mesh().C().boundaryField(), patchI)
    {
        const vectorField& CP = mesh().C().boundaryField()[patchI];
        symmTensorField& sigmaP = sigma().boundaryFieldRef()[patchI];
        const labelList& faceCells = mesh().boundary()[patchI].faceCells();

        forAll(CP, faceI)
        {
            // Patch face values
            sigmaP[faceI] = mms.calculateStress(CP[faceI]);

            // Patch internal cell values
            sigmaI[faceCells[faceI]] = mms.calculateStress(CI[faceCells[faceI]]);
        }
    }

    return true;
}


bool testLinGeomTotalDispSolid::evolveExplicit()
{
    if (time().timeIndex() == 1)
    {
        Info<< "Solving the solid momentum equation for D using an explicit "
            << "approach" << nl
            << "Simulation Time, Clock Time, Max Stress" << endl;
    }

    physicsModel::printInfo() = bool
    (
        time().timeIndex() % infoFrequency() == 0
     || mag(time().value() - time().endTime().value()) < SMALL
    );

    if (physicsModel::printInfo())
    {
        Info<< time().value() << " " << time().elapsedClockTime()
            << " " << max(mag(sigma())).value() << endl;

        physicsModel::printInfo() = false;
    }

    // Take references for brevity and efficiency
    const fvMesh& mesh = solidModel::mesh();
    volVectorField& D = solidModel::D();
    volTensorField& gradD = solidModel::gradD();
    volVectorField& U = solidModel::U();
    volSymmTensorField& sigma = solidModel::sigma();
    const volScalarField& rho = solidModel::rho();

    // Central difference scheme

    // Take a reference to the current and previous time-step
    const dimensionedScalar& deltaT = time().deltaT();
    //const dimensionedScalar& deltaT0 = time().deltaT0();

    // Compute the velocity
    // Note: this is the velocity at the middle of the time-step
    //pointU_ = pointU_.oldTime() + 0.5*(deltaT + deltaT0)*pointA_.oldTime();
    U = U.oldTime() + deltaT*A_.oldTime();

    // Compute displacement
    D = D.oldTime() + deltaT*U;

    // Enforce boundary conditions on the displacement field
    D.correctBoundaryConditions();

    if (solidModel::twoD())
    {
        // Remove displacement in the empty directions
        forAll(mesh.geometricD(), dirI)
        {
            if (mesh.geometricD()[dirI] < 0)
            {
                D.primitiveFieldRef().replace(dirI, 0.0);
            }
        }
    }

    // Update gradient of displacement
    mechanical().grad(D, gradD);

    // Calculate the stress using run-time selectable mechanical law
    mechanical().correct(sigma);

    // Unit normal vectors at the faces
    const surfaceVectorField n(mesh.Sf()/mesh.magSf());

    // Calculate the traction vectors at the faces
    surfaceVectorField traction(n & fvc::interpolate(sigma));

    // Add stabilisation to the traction
    // We add this before enforcing the traction condition as the stabilisation
    // is set to zero on traction boundaries
    // To-do: add a stabilisation traction function to momentumStabilisation
    const scalar scaleFactor =
        readScalar(stabilisation().dict().lookup("scaleFactor"));
    const surfaceTensorField gradDf(fvc::interpolate(gradD));
    traction += scaleFactor*impKf_*(fvc::snGrad(D) - (n & gradDf));

    // Enforce traction boundary conditions
    enforceTractionBoundaries(traction, D, n);

    // Solve the momentum equation for acceleration
    A_ = fvc::div(mesh.magSf()*traction)/rho
       + g()
       - dampingCoeff()*fvc::ddt(D);

    return true;
}


// * * * * * * * * * * * * * * * * Constructors  * * * * * * * * * * * * * * //

testLinGeomTotalDispSolid::testLinGeomTotalDispSolid
(
    Time& runTime,
    const word& region
)
:
    solidModel(typeName, runTime, region),
    foamPetscSnesHelper
    (
        fileName
        (
            solidModelDict().lookupOrDefault<fileName>
            (
                "optionsFile", "petscOptions"
            )
        ),
        D(),
        solidModel::twoD(),
        solidModelDict().lookupOrDefault<Switch>("stopOnPetscError", true),
        bool(solutionAlg() == solutionAlgorithm::PETSC_SNES)
    ),
    impK_(mechanical().impK()),
    impKf_(mechanical().impKf()),
    rImpK_(1.0/impK_),
    A_
    (
        IOobject
        (
            "A",
            mesh().time().timeName(),
            mesh(),
            IOobject::READ_IF_PRESENT,
            IOobject::NO_WRITE
        ),
        mesh(),
        dimensionedVector("zero", dimLength/pow(dimTime, 2), vector::zero)
    ),
    predictor_(solidModelDict().lookupOrDefault<Switch>("predictor", false)),
    ds_
    (
        IOobject
        (
            "ds",
            mesh().time().timeName(),
            mesh(),
            IOobject::NO_READ,
            IOobject::NO_WRITE
        ),
        mesh(),
        dimensionedScalar("ds", (dimForce/dimVolume)/dimVelocity, 1.0)
    )
{
    DisRequired();

    // Force all required old-time fields to be created
    fvm::d2dt2(D());

    // For consistent restarts, we will calculate the gradient field
    D().correctBoundaryConditions();
    D().storePrevIter();
    mechanical().grad(D(), gradD());

    if (predictor_)
    {
        // Check ddt scheme for D is not steadyState
        const word ddtDScheme
        (
#ifdef OPENFOAM_NOT_EXTEND
            mesh().ddtScheme("ddt(" + D().name() +')')
#else
            mesh().schemesDict().ddtScheme("ddt(" + D().name() +')')
#endif
        );

        if (ddtDScheme == "steadyState")
        {
            FatalErrorIn(type() + "::" + type())
                << "If predictor is turned on, then the ddt(" << D().name()
                << ") scheme should not be 'steadyState'!" << abort(FatalError);
        }
    }

    // Check the gradScheme
    const word gradDScheme
    (
        mesh().gradScheme("grad(" + D().name() +')')
    );

    if (solutionAlg() == solutionAlgorithm::PETSC_SNES)
    {
        if (gradDScheme != "leastSquaresS4f")
        {
            FatalErrorIn(type() + "::" + type())
                << "The `leastSquaresS4f` gradScheme should be used for "
                << "`grad(D)` when using the "
                << solidModel::solutionAlgorithmNames_
                   [
                       solidModel::solutionAlgorithm::PETSC_SNES
                   ]
                << " solution algorithm" << abort(FatalError);
        }

        // Set extrapolateValue to true for solidTraction boundaries
        forAll(D().boundaryField(), patchI)
        {
            if
            (
                isA<solidTractionFvPatchVectorField>
                (
                    D().boundaryField()[patchI]
                )
            )
            {
                Info<< "    Setting `extrapolateValue` to `true` on the "
                    << mesh().boundary()[patchI].name() << " patch of the D "
                    << "field" << endl;

                solidTractionFvPatchVectorField& tracPatch =
                    refCast<solidTractionFvPatchVectorField>
                    (
                        D().boundaryFieldRef()[patchI]
                    );

                tracPatch.extrapolateValue() = true;
            }
        }
    }
    else if (solutionAlg() != solutionAlgorithm::EXPLICIT)
    {
        if (gradDScheme == "leastSquaresS4f")
        {
            FatalErrorIn(type() + "::" + type())
                << "The `leastSquaresS4f` gradScheme should only be used for "
                << "`grad(D)` when using the "
                << solidModel::solutionAlgorithmNames_
                   [
                       solidModel::solutionAlgorithm::PETSC_SNES
                   ]
                << " and "
                << solidModel::solutionAlgorithmNames_
                   [
                       solidModel::solutionAlgorithm::PETSC_SNES
                   ]
                << " solution algorithms" << abort(FatalError);
        }

    }
}


// * * * * * * * * * * * * * * * Member Functions  * * * * * * * * * * * * * //


void testLinGeomTotalDispSolid::setDeltaT(Time& runTime)
{
    if (solutionAlg() == solutionAlgorithm::EXPLICIT)
    {
        // Max wave speed in the domain
        const scalar waveSpeed = max
        (
            Foam::sqrt(mechanical().impK()/mechanical().rho())
        ).value();

        // deltaT = cellWidth/waveVelocity == (1.0/deltaCoeff)/waveSpeed
        // In the current discretisation, information can move two cells per
        // time-step. This means that we use 1/(2*d) == 0.5*deltaCoeff when
        // calculating the required stable time-step
        // i.e. deltaT = (1.0/(0.5*deltaCoeff)/waveSpeed
        // For safety, we should use a time-step smaller than this e.g. Abaqus uses
        // stableTimeStep/sqrt(2): we will default to this value
        const scalar requiredDeltaT =
            1.0/
            gMax
            (
                DimensionedField<scalar, Foam::surfaceMesh>
                (
                    mesh().surfaceInterpolation::
                    deltaCoeffs().internalField()
                   *waveSpeed
                )
            );

        // Lookup the desired Courant number
        const scalar maxCo =
            runTime.controlDict().lookupOrDefault<scalar>("maxCo", 0.1);

        const scalar newDeltaT = maxCo*requiredDeltaT;

        // Update print info
        physicsModel::printInfo() = bool
        (
            runTime.timeIndex() % infoFrequency() == 0
         || mag(runTime.value() - runTime.endTime().value()) < SMALL
        );

        physicsModel::printInfo() = false;

        if (time().timeIndex() == 1)
        {
            Info<< nl << "Setting deltaT = " << newDeltaT
                << ", maxCo = " << maxCo << endl;
        }

        runTime.setDeltaT(newDeltaT);
    }
}


bool testLinGeomTotalDispSolid::evolve()
{
    if (solutionAlg() == solutionAlgorithm::PETSC_SNES)
    {
        return evolveSnes();
    }
    // else if (solutionAlg() == solutionAlgorithm::IMPLICIT_COUPLED)
    // {
    //     // Not yet implmented, although coupledUnsLinGeomLinearElasticSolid
    //     // could be combined with PETSc to achieve this.. todo!
    //     return evolveImplicitCoupled();
    // }
    else if (solutionAlg() == solutionAlgorithm::IMPLICIT_SEGREGATED)
    {
        return evolveImplicitSegregated();
    }
    else if (solutionAlg() == solutionAlgorithm::EXPLICIT)
    {
        return evolveExplicit();
    }
    else
    {
        FatalErrorIn("bool vertexCentredLinGeomSolid::evolve()")
            << "Unrecognised solution algorithm. Available options are "
            // << solutionAlgorithmNames_.names() << endl;
            << solidModel::solutionAlgorithmNames_
               [
                   solidModel::solutionAlgorithm::PETSC_SNES
               ]
            << solidModel::solutionAlgorithmNames_
               [
                   solidModel::solutionAlgorithm::IMPLICIT_SEGREGATED
               ]
            << solidModel::solutionAlgorithmNames_
               [
                   solidModel::solutionAlgorithm::EXPLICIT
               ]
            << endl;
    }

    // Keep compiler happy
    return true;
}


tmp<vectorField> testLinGeomTotalDispSolid::residualMomentum
(
    const volVectorField& D
)
{
    // Prepare result
    tmp<vectorField> tresidual(new vectorField(D.size(), vector::zero));
    vectorField& residual = tresidual.ref();

    // Enforce the boundary conditions
    const_cast<volVectorField&>(D).correctBoundaryConditions();

    // Update gradient of displacement
    mechanical().grad(D, gradD());

    // Calculate the stress using run-time selectable mechanical law
    mechanical().correct(sigma());

    // Unit normal vectors at the faces
    const surfaceVectorField n(mesh().Sf()/mesh().magSf());

    // Traction vectors at the faces
    surfaceVectorField traction(n & fvc::interpolate(sigma()));

    // Add stabilisation to the traction
    // We add this before enforcing the traction condition as the stabilisation
    // is set to zero on traction boundaries
    // To-do: add a stabilisation traction function to momentumStabilisation
    const scalar scaleFactor =
        readScalar(stabilisation().dict().lookup("scaleFactor"));
    const surfaceTensorField gradDf(fvc::interpolate(gradD()));
    traction += scaleFactor*impKf_*(fvc::snGrad(D) - (n & gradDf));

    // Enforce traction boundary conditions
    enforceTractionBoundaries(traction, D, n);

    // The residual vector is defined as
    // F = div(sigma) + rho*g
    //     - rho*d2dt2(D) - dampingCoeff*rho*ddt(D) + stabilisationTerm
    // where, here, we roll the stabilisationTerm into the div(sigma)
    residual =
        fvc::div(mesh().magSf()*traction)
      + rho()
       *(
            g() - fvc::d2dt2(D) - dampingCoeff()*fvc::ddt(D)
        );

    // Make residual extensive as fvc operators are intensive (per unit volume)
    residual *= mesh().V();

    // Add optional fvOptions, e.g. MMS body force
    // Note that "source()" is already multiplied by the volumes
    residual -= fvOptions()(ds_, const_cast<volVectorField&>(D))().source();

    return tresidual;
}


tmp<sparseMatrix> testLinGeomTotalDispSolid::JacobianMomentum
(
    const volVectorField& D
)
{
    // Count the number of non-zeros for a Laplacian discretisation
    // This equals the sum of one plus the number of internal faces for each,
    // which can be calculated as nCells + 2*nInternalFaces
    // Multiply by the blockSize since we will form the block matrix
    const int blockSize = solidModel::twoD() ? 2 : 3;
    const label numNonZeros =
        blockSize*returnReduce
        (
            mesh().nCells() + 2.0*mesh().nInternalFaces(), sumOp<label>()
        );

    // Calculate a segregated approximation of the Jacobian
    fvVectorMatrix approxJ
    (
        fvm::laplacian(impKf_, D, "laplacian(DD,D)")
      - rho()*fvm::d2dt2(D)
    );

    if (dampingCoeff().value() > SMALL)
    {
        approxJ -= dampingCoeff()*rho()*fvm::ddt(D);
    }

    // Optional: under-relaxation of the linear system
    approxJ.relax();

    // Convert fvMatrix matrix to sparseMatrix

    // Initialise matrix
    tmp<sparseMatrix> tmatrix(new sparseMatrix(numNonZeros));
    sparseMatrix& matrix = tmatrix.ref();

    // Insert the diagonal
    {
        const vectorField diag(approxJ.DD());
        forAll(diag, blockRowI)
        {
            const tensor coeff
            (
                diag[blockRowI][vector::X], 0, 0,
                0, diag[blockRowI][vector::Y], 0,
                0,  0, diag[blockRowI][vector::Z]
            );

            const label globalBlockRowI =
                foamPetscSnesHelper::globalCells().toGlobal(blockRowI);

            matrix(globalBlockRowI, globalBlockRowI) = coeff;
        }
    }

    // Insert the off-diagonal
    {
        const labelUList& own = mesh().owner();
        const labelUList& nei = mesh().neighbour();
        const scalarField& upper = approxJ.upper();
        forAll(own, faceI)
        {
            const tensor coeff(upper[faceI]*I);

            const label blockRowI = own[faceI];
            const label blockColI = nei[faceI];

            const label globalBlockRowI =
                foamPetscSnesHelper::globalCells().toGlobal(blockRowI);
            const label globalBlockColI =
                foamPetscSnesHelper::globalCells().toGlobal(blockColI);

            matrix(globalBlockRowI, globalBlockColI) = coeff;
            matrix(globalBlockColI, globalBlockRowI) = coeff;
        }
    }

    // Collect the global cell indices from neighbours at processor boundaries
    // These are used to insert the off-processor coefficients
    // First, send the data
    forAll(D.boundaryField(), patchI)
    {
        const fvPatchField<vector>& pD = D.boundaryField()[patchI];
        if (pD.type() == "processor")
        {
            // Take a copy of the faceCells (local IDs) and convert them to
            // global IDs
            labelList globalFaceCells(mesh().boundary()[patchI].faceCells());
            foamPetscSnesHelper::globalCells().inplaceToGlobal(globalFaceCells);

            // Send global IDs to the neighbour proc
            const processorFvPatch& procPatch =
                refCast<const processorFvPatch>(mesh().boundary()[patchI]);
            procPatch.send
            (
                Pstream::commsTypes::blocking, globalFaceCells
            );
        }
    }
    // Next, receive the data
    PtrList<labelList> neiProcGlobalIDs(D.boundaryField().size());
    forAll(D.boundaryField(), patchI)
    {
        const fvPatchField<vector>& pD = D.boundaryField()[patchI];
        if (pD.type() == "processor")
        {
            neiProcGlobalIDs.set(patchI, new labelList(pD.size()));
            labelList& globalFaceCells = neiProcGlobalIDs[patchI];

            // Receive global IDs from the neighbour proc
            const processorFvPatch& procPatch =
                refCast<const processorFvPatch>(mesh().boundary()[patchI]);
            procPatch.receive
            (
                Pstream::commsTypes::blocking, globalFaceCells
            );
        }
    }

    // Insert the off-processor coefficients
    forAll(D.boundaryField(), patchI)
    {
        const fvPatchField<vector>& pD = D.boundaryField()[patchI];

        if (pD.type() == "processor")
        {
            const vectorField& intCoeffs = approxJ.internalCoeffs()[patchI];
            const vectorField& neiCoeffs = approxJ.boundaryCoeffs()[patchI];
            const unallocLabelList& faceCells =
                mesh().boundary()[patchI].faceCells();
            const labelList& neiGlobalFaceCells = neiProcGlobalIDs[patchI];

            forAll(pD, faceI)
            {
                const label globalBlockRowI =
                    foamPetscSnesHelper::globalCells().toGlobal
                    (
                        faceCells[faceI]
                    );

                // On-proc diagonal coefficient
                {
                    const tensor coeff
                    (
                        intCoeffs[faceI][vector::X], 0, 0,
                        0, intCoeffs[faceI][vector::Y], 0,
                        0, 0, intCoeffs[faceI][vector::Z]
                    );

                    matrix(globalBlockRowI, globalBlockRowI) += coeff;
                }

                // Off-proc off-diagonal coefficient
                {
                    // Take care: we need to flip the sign
                    const tensor coeff
                    (
                        -neiCoeffs[faceI][vector::X], 0, 0,
                        0, -neiCoeffs[faceI][vector::Y], 0,
                        0, 0, -neiCoeffs[faceI][vector::Z]
                    );

                    const label globalBlockColI = neiGlobalFaceCells[faceI];

                    matrix(globalBlockRowI, globalBlockColI) += coeff;
                }
            }
        }
        else if (pD.coupled()) // coupled but not a processor boundary
        {
            FatalErrorIn
            (
                "tmp<sparseMatrix> testLinGeomTotalDispSolid::JacobianMomentum"
            )   << "Coupled boundaries (except processors) not implemented"
                << abort(FatalError);
        }
        // else non-coupled boundary contributions have already been added to
        // the diagonal
    }

    return tmatrix;
}


tmp<vectorField> testLinGeomTotalDispSolid::tractionBoundarySnGrad
(
    const vectorField& traction,
    const scalarField& pressure,
    const fvPatch& patch
) const
{
    // Patch index
    const label patchID = patch.index();

    // Patch mechanical property
    const scalarField& impK = impK_.boundaryField()[patchID];

    // Patch reciprocal implicit stiffness field
    const scalarField& rImpK = rImpK_.boundaryField()[patchID];

    // Patch gradient
    const tensorField& pGradD = gradD().boundaryField()[patchID];

    // Patch stress
    const symmTensorField& pSigma = sigma().boundaryField()[patchID];

    // Patch unit normals
    const vectorField n(patch.nf());

    // Return patch snGrad
    return tmp<vectorField>
    (
        new vectorField
        (
            (
                (traction - n*pressure)
              - (n & (pSigma - impK*pGradD))
            )*rImpK
        )
    );
}


// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //

} // End namespace solidModels

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * //

} // End namespace Foam

// ************************************************************************* //
