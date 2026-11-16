/*---------------------------------------------------------------------------*\
Application
    setLand2015FibreField

Description
    Build an analytic Land et al. 2015 ellipsoidal transmural coordinate and
    fibre basis for diagnostic comparison with an existing fibre field.

\*---------------------------------------------------------------------------*/

#include "fvCFD.H"
#include "unitConversion.H"

#include <cmath>

using namespace Foam;

namespace
{

struct LandGeometry
{
    scalar rShortEndo;
    scalar rShortEpi;
    scalar rLongEndo;
    scalar rLongEpi;
};


struct FibreAngles
{
    scalar endoDeg;
    scalar epiDeg;
};


struct FieldStats
{
    label n;
    scalar minValue;
    scalar maxValue;
    scalar sum;
    scalar sumSqr;

    FieldStats()
    :
        n(0),
        minValue(VGREAT),
        maxValue(-VGREAT),
        sum(0),
        sumSqr(0)
    {}

    void add(const scalar value)
    {
        ++n;
        minValue = min(minValue, value);
        maxValue = max(maxValue, value);
        sum += value;
        sumSqr += sqr(value);
    }

    scalar mean() const
    {
        return n ? sum/scalar(n) : 0;
    }

    scalar rms() const
    {
        return n ? Foam::sqrt(sumSqr/scalar(n)) : 0;
    }
};


enum class CoordinateConvention
{
    paperNegativeU,
    directPositiveU
};


scalar clamp01(const scalar x)
{
    return max(scalar(0), min(scalar(1), x));
}


scalar clampMinusOneToOne(const scalar x)
{
    return max(scalar(-1), min(scalar(1), x));
}


scalar rsAt(const scalar t, const LandGeometry& geom)
{
    return geom.rShortEndo + (geom.rShortEpi - geom.rShortEndo)*t;
}


scalar rlAt(const scalar t, const LandGeometry& geom)
{
    return geom.rLongEndo + (geom.rLongEpi - geom.rLongEndo)*t;
}


scalar ellipsoidResidual
(
    const vector& X,
    const scalar t,
    const LandGeometry& geom
)
{
    const scalar rs = rsAt(t, geom);
    const scalar rl = rlAt(t, geom);

    return (sqr(X.x()) + sqr(X.y()))/sqr(rs) + sqr(X.z())/sqr(rl) - 1.0;
}


scalar analyticLandT
(
    const vector& X,
    const scalar rShortEndo,
    const scalar rShortEpi,
    const scalar rLongEndo,
    const scalar rLongEpi,
    scalar& finalResidual
)
{
    const LandGeometry geom
    {
        rShortEndo,
        rShortEpi,
        rLongEndo,
        rLongEpi
    };

    const scalar geomTol = 1e-10;
    const scalar g0 = ellipsoidResidual(X, 0.0, geom);
    const scalar g1 = ellipsoidResidual(X, 1.0, geom);

    if (mag(g0) <= geomTol)
    {
        finalResidual = mag(g0);
        return 0.0;
    }

    if (mag(g1) <= geomTol)
    {
        finalResidual = mag(g1);
        return 1.0;
    }

    if (g0 < -geomTol || g1 > geomTol)
    {
        FatalErrorInFunction
            << "Point is not bracketed by the Land ellipsoids." << nl
            << "    X = " << X << nl
            << "    g(0) = " << g0 << nl
            << "    g(1) = " << g1 << nl
            << "    rShortEndo = " << rShortEndo << nl
            << "    rShortEpi = " << rShortEpi << nl
            << "    rLongEndo = " << rLongEndo << nl
            << "    rLongEpi = " << rLongEpi << nl
            << abort(FatalError);
    }

    scalar lo = 0.0;
    scalar hi = 1.0;
    scalar mid = 0.5;

    for (label iter = 0; iter < 60; ++iter)
    {
        mid = 0.5*(lo + hi);
        const scalar gm = ellipsoidResidual(X, mid, geom);

        if (gm > 0)
        {
            lo = mid;
        }
        else
        {
            hi = mid;
        }
    }

    mid = 0.5*(lo + hi);
    finalResidual = mag(ellipsoidResidual(X, mid, geom));

    return clamp01(mid);
}


scalar analyticLandTChecked
(
    const vector& X,
    const LandGeometry& geom,
    const word& context,
    const scalar bracketTolerance,
    label& endoToleranceClamps,
    label& epiToleranceClamps,
    scalar& finalResidual
)
{
    const scalar numericTol = 1e-10;
    const scalar g0 = ellipsoidResidual(X, 0.0, geom);
    const scalar g1 = ellipsoidResidual(X, 1.0, geom);

    const bool onEndo = mag(g0) <= numericTol;
    const bool onEpi = mag(g1) <= numericTol;
    const bool bracketed = g0 >= -numericTol && g1 <= numericTol;

    if (!onEndo && !onEpi && !bracketed)
    {
        if (g0 < 0 && g0 >= -bracketTolerance && g1 <= numericTol)
        {
            ++endoToleranceClamps;
            finalResidual = mag(g0);
            return 0.0;
        }

        if (g1 > 0 && g1 <= bracketTolerance && g0 >= -numericTol)
        {
            ++epiToleranceClamps;
            finalResidual = mag(g1);
            return 1.0;
        }
    }

    if (!onEndo && !onEpi && !bracketed)
    {
        FatalErrorInFunction
            << "Failed to determine analytic Land t for " << context << nl
            << "    X = " << X << nl
            << "    g(0) = " << g0 << nl
            << "    g(1) = " << g1 << nl
            << "    rShortEndo = " << geom.rShortEndo << nl
            << "    rShortEpi = " << geom.rShortEpi << nl
            << "    rLongEndo = " << geom.rLongEndo << nl
            << "    rLongEpi = " << geom.rLongEpi << nl
            << "    bracketTolerance = " << bracketTolerance << nl
            << abort(FatalError);
    }

    return analyticLandT
    (
        X,
        geom.rShortEndo,
        geom.rShortEpi,
        geom.rLongEndo,
        geom.rLongEpi,
        finalResidual
    );
}


word conventionName(const CoordinateConvention convention)
{
    if (convention == CoordinateConvention::paperNegativeU)
    {
        return "paperNegativeU";
    }

    return "directPositiveU";
}


CoordinateConvention readCoordinateConvention(const dictionary& dict)
{
    const word conventionName
    (
        dict.lookupOrDefault<word>("coordinateConvention", "paperNegativeU")
    );

    if (conventionName == "paperNegativeU")
    {
        return CoordinateConvention::paperNegativeU;
    }

    if (conventionName == "directPositiveU")
    {
        return CoordinateConvention::directPositiveU;
    }

    FatalErrorInFunction
        << "Unsupported coordinateConvention " << conventionName << nl
        << "Supported values are paperNegativeU and directPositiveU"
        << abort(FatalError);

    return CoordinateConvention::paperNegativeU;
}


void uvForConvention
(
    const vector& X,
    const scalar rl,
    const CoordinateConvention convention,
    scalar& uu,
    scalar& vv
)
{
    const scalar zOverRl = clampMinusOneToOne(X.z()/rl);

    if (convention == CoordinateConvention::directPositiveU)
    {
        uu = Foam::acos(zOverRl);
        vv = Foam::atan2(X.y(), X.x());
    }
    else
    {
        uu = -Foam::acos(zOverRl);
        vv = Foam::atan2(-X.y(), -X.x());
    }
}


bool isAxisPoint(const vector& X, const scalar axisTolerance)
{
    return Foam::sqrt(sqr(X.x()) + sqr(X.y())) <= axisTolerance;
}


vector reconstructedPoint
(
    const scalar uu,
    const scalar vv,
    const scalar rs,
    const scalar rl
)
{
    return vector
    (
        rs*Foam::sin(uu)*Foam::cos(vv),
        rs*Foam::sin(uu)*Foam::sin(vv),
        rl*Foam::cos(uu)
    );
}


vector normalisedOrFatal
(
    const vector& value,
    const word& context
)
{
    const scalar valueMag = mag(value);

    if (valueMag <= SMALL)
    {
        FatalErrorInFunction
            << "Cannot normalise near-zero vector for " << context << nl
            << "    value = " << value << nl
            << abort(FatalError);
    }

    return value/valueMag;
}


void analyticBasis
(
    const vector& X,
    const scalar t,
    const LandGeometry& geom,
    const CoordinateConvention convention,
    const scalar axisTolerance,
    scalar& uu,
    scalar& vv,
    vector& eU,
    vector& eV,
    scalar& reconstructionError,
    bool& regularised
)
{
    const scalar rs = rsAt(t, geom);
    const scalar rl = rlAt(t, geom);
    const scalar rho = Foam::sqrt(sqr(X.x()) + sqr(X.y()));

    uvForConvention(X, rl, convention, uu, vv);

    const vector Xrec = reconstructedPoint(uu, vv, rs, rl);
    reconstructionError = mag(Xrec - X);

    regularised = false;
    if (rho <= axisTolerance)
    {
        regularised = true;
        FatalErrorInFunction
            << "Axis point must be regularised by neighbouring cell fibres, "
            << "not by an arbitrary global direction" << nl
            << "    X = " << X << nl
            << "    t = " << t << nl
            << "    axisRegularisationTolerance = " << axisTolerance
            << abort(FatalError);
    }

    const vector er(X.x()/rho, X.y()/rho, 0);
    const vector ez(0, 0, 1);
    const vector eVRaw(-X.y()/rho, X.x()/rho, 0);

    vector eURaw(vector::zero);
    if (convention == CoordinateConvention::paperNegativeU)
    {
        eURaw = -(rs*X.z()/rl)*er + (rl*rho/rs)*ez;
    }
    else
    {
        eURaw = (rs*X.z()/rl)*er - (rl*rho/rs)*ez;
    }

    eU = normalisedOrFatal(eURaw, "Land eU tangent");
    eV = normalisedOrFatal(eVRaw, "Land eV tangent");
}


vector analyticFibre
(
    const vector& X,
    const scalar t,
    const LandGeometry& geom,
    const FibreAngles& angles,
    const CoordinateConvention convention,
    const scalar axisTolerance,
    scalar& uu,
    scalar& vv,
    scalar& reconstructionError,
    bool& regularised
)
{
    vector eU(vector::zero);
    vector eV(vector::zero);

    analyticBasis
    (
        X,
        t,
        geom,
        convention,
        axisTolerance,
        uu,
        vv,
        eU,
        eV,
        reconstructionError,
        regularised
    );

    const scalar pi = constant::mathematical::pi;
    const scalar alpha =
        (angles.endoDeg + (angles.epiDeg - angles.endoDeg)*t)*pi/180.0;

    vector f = Foam::sin(alpha)*eU + Foam::cos(alpha)*eV;
    f = normalisedOrFatal(f, "Land fibre");

    return f;
}


scalar signInsensitiveAngleDeg(const vector& a, const vector& b)
{
    const scalar magA = mag(a);
    const scalar magB = mag(b);

    if (magA <= SMALL || magB <= SMALL)
    {
        return GREAT;
    }

    const scalar c = clampMinusOneToOne(mag(a & b)/(magA*magB));
    return Foam::acos(c)*180.0/constant::mathematical::pi;
}


bool finiteScalar(const scalar value)
{
    return std::isfinite(value);
}


bool finiteVector(const vector& value)
{
    return
        std::isfinite(value.x())
     && std::isfinite(value.y())
     && std::isfinite(value.z());
}


void printStats(const word& name, const FieldStats& stats)
{
    if (!stats.n)
    {
        Info<< name << ": n = 0" << nl;
        return;
    }

    Info<< name
        << ": n = " << stats.n
        << ", min = " << stats.minValue
        << ", max = " << stats.maxValue
        << ", mean = " << stats.mean()
        << ", RMS = " << stats.rms()
        << nl;
}


void addSignAligned
(
    vector& sum,
    vector& reference,
    bool& haveReference,
    const vector& value
)
{
    vector aligned = value;

    if (!haveReference)
    {
        reference = normalisedOrFatal(value, "sign alignment reference");
        haveReference = true;
    }
    else if ((reference & aligned) < 0)
    {
        aligned = -aligned;
    }

    sum += aligned;
}


label layerIndex(const scalar t)
{
    if (t < scalar(1)/scalar(3))
    {
        return 0;
    }

    if (t < scalar(2)/scalar(3))
    {
        return 1;
    }

    return 2;
}


scalar wrappedAngleDifference(const scalar a, const scalar b)
{
    return Foam::atan2(Foam::sin(a - b), Foam::cos(a - b));
}


void derivativeBasisFromUV
(
    const scalar uu,
    const scalar vv,
    const scalar rs,
    const scalar rl,
    vector& eU,
    vector& eV
)
{
    eU = normalisedOrFatal
    (
        vector
        (
            rs*Foam::cos(uu)*Foam::cos(vv),
            rs*Foam::cos(uu)*Foam::sin(vv),
            -rl*Foam::sin(uu)
        ),
        "exact-test dX/du"
    );

    eV = normalisedOrFatal
    (
        vector
        (
            -rs*Foam::sin(uu)*Foam::sin(vv),
             rs*Foam::sin(uu)*Foam::cos(vv),
             0
        ),
        "exact-test dX/dv"
    );
}


void requireSmall
(
    const word& name,
    const scalar value,
    const scalar tolerance,
    label& failures
)
{
    if (value > tolerance)
    {
        ++failures;
        Info<< "    FAILED " << name << " = " << value
            << " tolerance = " << tolerance << nl;
    }
}


void runExactPointTests
(
    const LandGeometry& geom,
    const FibreAngles& angles,
    const CoordinateConvention convention,
    const scalar axisTolerance
)
{
    const scalar pi = constant::mathematical::pi;
    const scalar tValues[5] = {0, 0.25, 0.5, 0.75, 1};
    const scalar vValues[4] = {0, 0.5*pi, pi, -0.5*pi};
    const scalar uAbsValues[5] = {0.2*pi, 0.35*pi, 0.5*pi, 0.65*pi, 0.8*pi};

    const tensor Rz90(0, -1, 0, 1, 0, 0, 0, 0, 1);
    const scalar tolerance = 1e-10;

    FieldStats fibreMagError;
    FieldStats eUeVDotError;
    FieldStats tangencyError;
    FieldStats dyadSignError;
    FieldStats rotationFibreError;
    FieldStats rotationDyadError;
    FieldStats derivativeEUError;
    FieldStats derivativeEVError;
    FieldStats recoveredAngleError;
    FieldStats endpointError;

    label failures = 0;
    label nTests = 0;

    for (label ti = 0; ti < 5; ++ti)
    {
        const scalar t = tValues[ti];
        const scalar rs = rsAt(t, geom);
        const scalar rl = rlAt(t, geom);
        const scalar alpha =
            (angles.endoDeg + (angles.epiDeg - angles.endoDeg)*t)*pi/180.0;

        for (label vi = 0; vi < 4; ++vi)
        {
            for (label ui = 0; ui < 5; ++ui)
            {
                const scalar uu =
                    convention == CoordinateConvention::paperNegativeU
                  ? -uAbsValues[ui]
                  :  uAbsValues[ui];
                const scalar vv = vValues[vi];
                const vector X = reconstructedPoint(uu, vv, rs, rl);

                scalar uuDiag = 0;
                scalar vvDiag = 0;
                scalar recErr = 0;
                bool regularised = false;
                vector eU(vector::zero);
                vector eV(vector::zero);

                analyticBasis
                (
                    X,
                    t,
                    geom,
                    convention,
                    axisTolerance,
                    uuDiag,
                    vvDiag,
                    eU,
                    eV,
                    recErr,
                    regularised
                );

                scalar fU = 0;
                scalar fV = 0;
                scalar fRecErr = 0;
                bool fRegularised = false;
                const vector f =
                    analyticFibre
                    (
                        X,
                        t,
                        geom,
                        angles,
                        convention,
                        axisTolerance,
                        fU,
                        fV,
                        fRecErr,
                        fRegularised
                    );

                vector eUDeriv(vector::zero);
                vector eVDeriv(vector::zero);
                derivativeBasisFromUV(uu, vv, rs, rl, eUDeriv, eVDeriv);

                const vector gradG
                (
                    2*X.x()/sqr(rs),
                    2*X.y()/sqr(rs),
                    2*X.z()/sqr(rl)
                );

                const vector Xrot = Rz90 & X;
                scalar ru = 0;
                scalar rv = 0;
                scalar rRecErr = 0;
                bool rRegularised = false;
                const vector fRot =
                    analyticFibre
                    (
                        Xrot,
                        t,
                        geom,
                        angles,
                        convention,
                        axisTolerance,
                        ru,
                        rv,
                        rRecErr,
                        rRegularised
                    );

                const symmTensor ff = sqr(f);
                const symmTensor ffRotExpected = symm(Rz90 & ff & Rz90.T());

                fibreMagError.add(mag(mag(f) - 1));
                eUeVDotError.add(mag(eU & eV));
                tangencyError.add(max(mag(gradG & eU), mag(gradG & eV)));
                dyadSignError.add(mag(sqr(f) - sqr(-f)));
                rotationFibreError.add(mag(fRot - (Rz90 & f)));
                rotationDyadError.add(mag(sqr(fRot) - ffRotExpected));
                derivativeEUError.add(mag(eU - eUDeriv));
                derivativeEVError.add(mag(eV - eVDeriv));
                recoveredAngleError.add
                (
                    mag(wrappedAngleDifference(Foam::atan2(f & eU, f & eV), alpha))
                );

                requireSmall("exact |f0|-1", fibreMagError.maxValue, tolerance, failures);
                requireSmall("exact eu.ev", eUeVDotError.maxValue, tolerance, failures);
                requireSmall("exact tangency", tangencyError.maxValue, tolerance, failures);
                requireSmall("exact dyad sign invariance", dyadSignError.maxValue, tolerance, failures);
                requireSmall("exact z-rotation fibre", rotationFibreError.maxValue, tolerance, failures);
                requireSmall("exact z-rotation dyad", rotationDyadError.maxValue, tolerance, failures);
                requireSmall("exact derivative eU", derivativeEUError.maxValue, tolerance, failures);
                requireSmall("exact derivative eV", derivativeEVError.maxValue, tolerance, failures);
                requireSmall("exact recovered alpha", recoveredAngleError.maxValue, tolerance, failures);

                if (mag(t) <= SMALL)
                {
                    endpointError.add(mag((f & eU) - 1));
                    requireSmall("t=0 f0 parallel +eu", endpointError.maxValue, tolerance, failures);
                }
                else if (mag(t - 0.5) <= SMALL)
                {
                    endpointError.add(mag((f & eV) - 1));
                    requireSmall("t=0.5 f0 parallel +ev", endpointError.maxValue, tolerance, failures);
                }
                else if (mag(t - 1) <= SMALL)
                {
                    endpointError.add(mag((f & eU) + 1));
                    requireSmall("t=1 f0 parallel -eu", endpointError.maxValue, tolerance, failures);
                }

                ++nTests;
            }
        }
    }

    Info<< nl << "Exact Land fibre point tests" << nl
        << "    convention = " << conventionName(convention) << nl
        << "    evaluated points = " << nTests << nl;
    printStats("|f0|-1", fibreMagError);
    printStats("|eu.ev|", eUeVDotError);
    printStats("ellipsoid tangency", tangencyError);
    printStats("f0 dyad sign invariance", dyadSignError);
    printStats("z-rotation fibre covariance", rotationFibreError);
    printStats("z-rotation dyad covariance", rotationDyadError);
    printStats("branch-free vs derivative eU", derivativeEUError);
    printStats("branch-free vs derivative eV", derivativeEVError);
    printStats("recovered alpha error", recoveredAngleError);
    printStats("endpoint orientation error", endpointError);

    if (failures)
    {
        FatalErrorInFunction
            << "Exact Land point tests failed " << failures << " checks"
            << abort(FatalError);
    }
}

} // End anonymous namespace


int main(int argc, char *argv[])
{
    #include "addRegionOption.H"
    #include "setRootCase.H"
    #include "createTime.H"

    runTime.setTime(0.0, 0);

    #include "createNamedMesh.H"

    Info<< "Forced preprocessing time directory: " << runTime.timeName() << nl;

    Info<< "Reading system/setFibreFieldDict" << nl;
    IOdictionary dict
    (
        IOobject
        (
            "setFibreFieldDict",
            runTime.system(),
            runTime,
            IOobject::MUST_READ,
            IOobject::NO_WRITE
        )
    );

    const word paperModel(dict.lookupOrDefault<word>("paperModel", "Land2015"));
    const word transmuralCoordinate
    (
        dict.lookupOrDefault<word>("transmuralCoordinate", "analyticEllipsoid")
    );

    if (paperModel != "Land2015")
    {
        FatalErrorInFunction
            << "setLand2015FibreField only supports paperModel Land2015; got "
            << paperModel << abort(FatalError);
    }

    if (transmuralCoordinate != "analyticEllipsoid")
    {
        FatalErrorInFunction
            << "This dedicated test utility requires transmuralCoordinate "
            << "analyticEllipsoid; got " << transmuralCoordinate
            << abort(FatalError);
    }

    const FibreAngles angles
    {
        dict.lookupOrDefault<scalar>("fibreAngleEndo", 90.0),
        dict.lookupOrDefault<scalar>("fibreAngleEpi", -90.0)
    };

    const Switch allowNonBenchmarkAngles
    (
        dict.lookupOrDefault<Switch>("allowNonBenchmarkAngles", Switch(false))
    );

    const scalar benchmarkAngleTolerance
    (
        dict.lookupOrDefault<scalar>("benchmarkAngleTolerance", 1e-10)
    );

    if
    (
        !allowNonBenchmarkAngles
     && (
            mag(angles.endoDeg - 90.0) > benchmarkAngleTolerance
         || mag(angles.epiDeg + 90.0) > benchmarkAngleTolerance
        )
    )
    {
        FatalErrorInFunction
            << "Land2015 benchmark mode requires fibreAngleEndo = +90 and "
            << "fibreAngleEpi = -90 degrees." << nl
            << "    fibreAngleEndo = " << angles.endoDeg << nl
            << "    fibreAngleEpi = " << angles.epiDeg << nl
            << "    allowNonBenchmarkAngles = " << allowNonBenchmarkAngles
            << abort(FatalError);
    }

    const LandGeometry geom
    {
        dict.lookupOrDefault<scalar>("rShortEndo", 0.007),
        dict.lookupOrDefault<scalar>("rShortEpi", 0.010),
        dict.lookupOrDefault<scalar>("rLongEndo", 0.017),
        dict.lookupOrDefault<scalar>("rLongEpi", 0.020)
    };

    const scalar axisTolerance
    (
        dict.lookupOrDefault<scalar>("axisRegularisationTolerance", 1e-12)
    );
    const scalar ellipsoidBracketTolerance
    (
        dict.lookupOrDefault<scalar>("ellipsoidBracketTolerance", 1e-10)
    );

    const Switch comparisonMode
    (
        dict.lookupOrDefault<Switch>("comparisonMode", Switch(false))
    );

    const word endocardialPatch
    (
        dict.lookupOrDefault<word>("endocardialPatch", "inside")
    );
    const word epicardialPatch
    (
        dict.lookupOrDefault<word>("epicardialPatch", "outside")
    );
    const word basalPatch
    (
        dict.lookupOrDefault<word>("basalPatch", "fixed")
    );

    const CoordinateConvention selectedConvention =
        readCoordinateConvention(dict);

    Info<< nl << "Land2015 benchmark fibre generation controls" << nl
        << "    comparisonMode = " << comparisonMode << nl
        << "    coordinateConvention = "
        << conventionName(selectedConvention) << nl
        << "    endocardialPatch = " << endocardialPatch << nl
        << "    epicardialPatch = " << epicardialPatch << nl
        << "    basalPatch = " << basalPatch << nl
        << "    allowNonBenchmarkAngles = " << allowNonBenchmarkAngles << nl
        << "    fibreAngleEndo = " << angles.endoDeg << " degrees" << nl
        << "    fibreAngleEpi = " << angles.epiDeg << " degrees" << nl
        << "    alpha(t) = " << angles.endoDeg
        << " + (" << angles.epiDeg << " - " << angles.endoDeg
        << ")*t degrees" << nl;

    Info<< "Analytic Land geometry" << nl
        << "    rs(t) = " << geom.rShortEndo
        << " + (" << geom.rShortEpi << " - " << geom.rShortEndo << ")*t" << nl
        << "    rl(t) = " << geom.rLongEndo
        << " + (" << geom.rLongEpi << " - " << geom.rLongEndo << ")*t" << nl
        << "    axisRegularisationTolerance = " << axisTolerance << nl
        << "    ellipsoidBracketTolerance = " << ellipsoidBracketTolerance << nl;

    runExactPointTests(geom, angles, selectedConvention, axisTolerance);

    const word backupInstance("originalLaplaceFibres");

    volScalarField tLaplaceOriginal
    (
        IOobject
        (
            "tLaplaceOriginalForComparison",
            runTime.timeName(),
            mesh,
            IOobject::NO_READ,
            IOobject::NO_WRITE
        ),
        mesh,
        dimensionedScalar("zero", dimless, 0)
    );

    volVectorField f0Original
    (
        IOobject
        (
            "f0OriginalForComparison",
            runTime.timeName(),
            mesh,
            IOobject::NO_READ,
            IOobject::NO_WRITE
        ),
        mesh,
        dimensionedVector("zero", dimless, vector::zero)
    );

    surfaceVectorField f0fOriginal
    (
        IOobject
        (
            "f0fOriginalForComparison",
            runTime.timeName(),
            mesh,
            IOobject::NO_READ,
            IOobject::NO_WRITE
        ),
        mesh,
        dimensionedVector("zero", dimless, vector::zero)
    );

    if (comparisonMode)
    {
        Info<< "Reading backed-up original fields from "
            << backupInstance << nl;

        volScalarField tRead
        (
            IOobject
            (
                "t",
                backupInstance,
                mesh,
                IOobject::MUST_READ,
                IOobject::NO_WRITE
            ),
            mesh
        );
        tLaplaceOriginal = tRead;

        volVectorField f0Read
        (
            IOobject
            (
                "f0",
                backupInstance,
                mesh,
                IOobject::MUST_READ,
                IOobject::NO_WRITE
            ),
            mesh
        );
        f0Original = f0Read;

        surfaceVectorField f0fRead
        (
            IOobject
            (
                "f0f",
                backupInstance,
                mesh,
                IOobject::READ_IF_PRESENT,
                IOobject::NO_WRITE
            ),
            mesh,
            dimensionedVector("zero", dimless, vector::zero)
        );
        f0fOriginal = f0fRead;
    }
    else
    {
        Info<< "comparisonMode is false: not reading "
            << backupInstance << nl;
    }

    volScalarField tLaplace
    (
        IOobject("tLaplace", runTime.timeName(), mesh, IOobject::NO_READ, IOobject::AUTO_WRITE),
        tLaplaceOriginal
    );

    volVectorField f0LaplaceOrCurrent
    (
        IOobject("f0LaplaceOrCurrent", runTime.timeName(), mesh, IOobject::NO_READ, IOobject::AUTO_WRITE),
        f0Original
    );

    volScalarField tAnalytic
    (
        IOobject("tAnalytic", runTime.timeName(), mesh, IOobject::NO_READ, IOobject::AUTO_WRITE),
        tLaplaceOriginal
    );

    volScalarField t
    (
        IOobject("t", runTime.timeName(), mesh, IOobject::NO_READ, IOobject::AUTO_WRITE),
        tLaplaceOriginal
    );

    volScalarField tDifference
    (
        IOobject("tDifference", runTime.timeName(), mesh, IOobject::NO_READ, IOobject::AUTO_WRITE),
        tLaplaceOriginal
    );

    volScalarField absTDifference
    (
        IOobject("absTDifference", runTime.timeName(), mesh, IOobject::NO_READ, IOobject::AUTO_WRITE),
        tLaplaceOriginal
    );

    volScalarField alphaRadiansAnalytic
    (
        IOobject("alphaRadiansAnalytic", runTime.timeName(), mesh, IOobject::NO_READ, IOobject::AUTO_WRITE),
        mesh,
        dimensionedScalar("zero", dimless, 0)
    );

    volScalarField rsAnalytic
    (
        IOobject("rsAnalytic", runTime.timeName(), mesh, IOobject::NO_READ, IOobject::AUTO_WRITE),
        mesh,
        dimensionedScalar("zero", dimLength, 0)
    );

    volScalarField rlAnalytic
    (
        IOobject("rlAnalytic", runTime.timeName(), mesh, IOobject::NO_READ, IOobject::AUTO_WRITE),
        mesh,
        dimensionedScalar("zero", dimLength, 0)
    );

    volScalarField uuAnalytic
    (
        IOobject("uuAnalytic", runTime.timeName(), mesh, IOobject::NO_READ, IOobject::AUTO_WRITE),
        mesh,
        dimensionedScalar("zero", dimless, 0)
    );

    volScalarField vvAnalytic
    (
        IOobject("vvAnalytic", runTime.timeName(), mesh, IOobject::NO_READ, IOobject::AUTO_WRITE),
        mesh,
        dimensionedScalar("zero", dimless, 0)
    );

    volScalarField coordinateReconstructionError
    (
        IOobject("coordinateReconstructionError", runTime.timeName(), mesh, IOobject::NO_READ, IOobject::AUTO_WRITE),
        mesh,
        dimensionedScalar("zero", dimLength, 0)
    );

    volVectorField f0Analytic
    (
        IOobject("f0Analytic", runTime.timeName(), mesh, IOobject::NO_READ, IOobject::AUTO_WRITE),
        f0Original
    );

    volVectorField f0
    (
        IOobject("f0", runTime.timeName(), mesh, IOobject::NO_READ, IOobject::AUTO_WRITE),
        f0Original
    );

    volVectorField f0AnalyticBasisWithLaplaceT
    (
        IOobject("f0AnalyticBasisWithLaplaceT", runTime.timeName(), mesh, IOobject::NO_READ, IOobject::AUTO_WRITE),
        f0Original
    );

    volScalarField fibreAngleError
    (
        IOobject("fibreAngleError", runTime.timeName(), mesh, IOobject::NO_READ, IOobject::AUTO_WRITE),
        mesh,
        dimensionedScalar("zero", dimless, 0)
    );

    volScalarField fibreAngleErrorCurrentVsAnalyticBasisLaplaceT
    (
        IOobject("fibreAngleErrorCurrentVsAnalyticBasisLaplaceT", runTime.timeName(), mesh, IOobject::NO_READ, IOobject::AUTO_WRITE),
        mesh,
        dimensionedScalar("zero", dimless, 0)
    );

    volScalarField fibreAngleErrorAnalyticBasisLaplaceTToAnalytic
    (
        IOobject("fibreAngleErrorAnalyticBasisLaplaceTToAnalytic", runTime.timeName(), mesh, IOobject::NO_READ, IOobject::AUTO_WRITE),
        mesh,
        dimensionedScalar("zero", dimless, 0)
    );

    surfaceScalarField tfAnalytic
    (
        IOobject("tfAnalytic", runTime.timeName(), mesh, IOobject::NO_READ, IOobject::AUTO_WRITE),
        mesh,
        dimensionedScalar("zero", dimless, 0)
    );

    surfaceScalarField alphaRadiansfAnalytic
    (
        IOobject("alphaRadiansfAnalytic", runTime.timeName(), mesh, IOobject::NO_READ, IOobject::AUTO_WRITE),
        mesh,
        dimensionedScalar("zero", dimless, 0)
    );

    surfaceVectorField f0fAnalytic
    (
        IOobject("f0fAnalytic", runTime.timeName(), mesh, IOobject::NO_READ, IOobject::AUTO_WRITE),
        f0fOriginal
    );

    surfaceVectorField f0f
    (
        IOobject("f0f", runTime.timeName(), mesh, IOobject::NO_READ, IOobject::AUTO_WRITE),
        f0fOriginal
    );

    scalar maxEllipsoidResidual = 0;
    scalar maxPatchExactResidual = 0;
    label nonFiniteCount = 0;
    label endoToleranceClamps = 0;
    label epiToleranceClamps = 0;
    label endocardialPatchAssignments = 0;
    label epicardialPatchAssignments = 0;

    const vectorField& C = mesh.C();

    forAll(C, cellI)
    {
        scalar residual = 0;
        const scalar tCell =
            analyticLandTChecked
            (
                C[cellI],
                geom,
                "cell " + name(cellI),
                ellipsoidBracketTolerance,
                endoToleranceClamps,
                epiToleranceClamps,
                residual
            );

        maxEllipsoidResidual = max(maxEllipsoidResidual, residual);
        tAnalytic[cellI] = tCell;
        t[cellI] = tCell;
    }

    forAll(mesh.C().boundaryField(), patchI)
    {
        const vectorField& patchC = mesh.C().boundaryField()[patchI];
        const word& patchName = mesh.boundary()[patchI].name();
        scalarField& patchTAnalytic = tAnalytic.boundaryFieldRef()[patchI];
        scalarField& patchT = t.boundaryFieldRef()[patchI];

        forAll(patchC, faceI)
        {
            scalar residual = 0;
            scalar tFace = 0;
            bool patchExact = false;

            if (patchName == endocardialPatch)
            {
                tFace = 0;
                residual = mag(ellipsoidResidual(patchC[faceI], 0, geom));
                patchExact = true;
                ++endocardialPatchAssignments;
            }
            else if (patchName == epicardialPatch)
            {
                tFace = 1;
                residual = mag(ellipsoidResidual(patchC[faceI], 1, geom));
                patchExact = true;
                ++epicardialPatchAssignments;
            }
            else
            {
                tFace =
                    analyticLandTChecked
                    (
                        patchC[faceI],
                        geom,
                        "boundary patch "
                      + patchName
                      + " face "
                      + name(faceI),
                        ellipsoidBracketTolerance,
                        endoToleranceClamps,
                        epiToleranceClamps,
                        residual
                    );
            }

            if (patchExact)
            {
                maxPatchExactResidual = max(maxPatchExactResidual, residual);
            }
            else
            {
                maxEllipsoidResidual = max(maxEllipsoidResidual, residual);
            }
            patchTAnalytic[faceI] = tFace;
            patchT[faceI] = tFace;
        }
    }

    Info<< "Selected coordinate convention = "
        << conventionName(selectedConvention) << nl;

    FieldStats tLaplaceStats;
    FieldStats tAnalyticStats;
    FieldStats absTDifferenceStats;
    FieldStats tDifferenceStats;
    FieldStats zBandAbsTDifferenceStats;
    FieldStats zBandTDifferenceStats;
    FieldStats layerAbsTDifferenceStats[3];
    FieldStats layerTDifferenceStats[3];

    FieldStats currentVsBasisLaplaceAngleStats;
    FieldStats basisLaplaceVsAnalyticAngleStats;
    FieldStats currentVsAnalyticAngleStats;
    FieldStats zBandCurrentVsBasisLaplaceAngleStats;
    FieldStats zBandBasisLaplaceVsAnalyticAngleStats;
    FieldStats zBandCurrentVsAnalyticAngleStats;
    FieldStats layerCurrentVsBasisLaplaceAngleStats[3];
    FieldStats layerBasisLaplaceVsAnalyticAngleStats[3];
    FieldStats layerCurrentVsAnalyticAngleStats[3];
    FieldStats nonRegularisedCurrentVsAnalyticAngleStats;

    FieldStats f0MagnitudeStats;
    FieldStats f0fMagnitudeStats;

    label regularisedCells = 0;
    label regularisedFaces = 0;
    List<bool> cellRegularised(mesh.nCells(), false);
    List<bool> cellFibreSet(mesh.nCells(), false);
    DynamicList<label> regularisedCellIDs;
    DynamicList<label> regularisedInternalFaceIDs;
    DynamicList<label> regularisedBoundaryFaceIDs;

    const scalar pi = constant::mathematical::pi;

    forAll(C, cellI)
    {
        const scalar tA = tAnalytic[cellI];
        alphaRadiansAnalytic[cellI] =
            (angles.endoDeg + (angles.epiDeg - angles.endoDeg)*tA)*pi/180.0;
        rsAnalytic[cellI] = rsAt(tA, geom);
        rlAnalytic[cellI] = rlAt(tA, geom);

        tAnalyticStats.add(tA);
        const label layer = layerIndex(tA);

        if (isAxisPoint(C[cellI], axisTolerance))
        {
            ++regularisedCells;
            cellRegularised[cellI] = true;
            regularisedCellIDs.append(cellI);
            continue;
        }

        scalar uu = 0;
        scalar vv = 0;
        scalar recErr = 0;
        bool regularised = false;
        const vector fibre =
            analyticFibre
            (
                C[cellI],
                tA,
                geom,
                angles,
                selectedConvention,
                axisTolerance,
                uu,
                vv,
                recErr,
                regularised
            );

        f0Analytic[cellI] = fibre;
        f0[cellI] = fibre;
        cellFibreSet[cellI] = true;

        uuAnalytic[cellI] = uu;
        vvAnalytic[cellI] = vv;
        coordinateReconstructionError[cellI] = recErr;
        f0MagnitudeStats.add(mag(f0[cellI]));

        if (comparisonMode)
        {
            const scalar tL = tLaplace[cellI];

            scalar uuLaplace = 0;
            scalar vvLaplace = 0;
            scalar recErrLaplace = 0;
            bool regularisedLaplace = false;
            const vector fibreLaplaceT =
                analyticFibre
                (
                    C[cellI],
                    tL,
                    geom,
                    angles,
                    selectedConvention,
                    axisTolerance,
                    uuLaplace,
                    vvLaplace,
                    recErrLaplace,
                    regularisedLaplace
                );

            f0AnalyticBasisWithLaplaceT[cellI] = fibreLaplaceT;

            const scalar diff = tL - tA;
            tDifference[cellI] = diff;
            absTDifference[cellI] = mag(diff);

            tLaplaceStats.add(tL);
            tDifferenceStats.add(diff);
            absTDifferenceStats.add(mag(diff));

            layerTDifferenceStats[layer].add(diff);
            layerAbsTDifferenceStats[layer].add(mag(diff));

            if (C[cellI].z() >= -0.010 && C[cellI].z() <= -0.004)
            {
                zBandTDifferenceStats.add(diff);
                zBandAbsTDifferenceStats.add(mag(diff));
            }

            const scalar angleCurrentVsBasisLaplace =
                signInsensitiveAngleDeg(f0Original[cellI], fibreLaplaceT);
            const scalar angleBasisLaplaceVsAnalytic =
                signInsensitiveAngleDeg(fibreLaplaceT, fibre);
            const scalar angleCurrentVsAnalytic =
                signInsensitiveAngleDeg(f0Original[cellI], fibre);

            fibreAngleErrorCurrentVsAnalyticBasisLaplaceT[cellI] =
                angleCurrentVsBasisLaplace;
            fibreAngleErrorAnalyticBasisLaplaceTToAnalytic[cellI] =
                angleBasisLaplaceVsAnalytic;
            fibreAngleError[cellI] = angleCurrentVsAnalytic;

            currentVsBasisLaplaceAngleStats.add(angleCurrentVsBasisLaplace);
            basisLaplaceVsAnalyticAngleStats.add(angleBasisLaplaceVsAnalytic);
            currentVsAnalyticAngleStats.add(angleCurrentVsAnalytic);

            layerCurrentVsBasisLaplaceAngleStats[layer].add(angleCurrentVsBasisLaplace);
            layerBasisLaplaceVsAnalyticAngleStats[layer].add(angleBasisLaplaceVsAnalytic);
            layerCurrentVsAnalyticAngleStats[layer].add(angleCurrentVsAnalytic);

            nonRegularisedCurrentVsAnalyticAngleStats.add(angleCurrentVsAnalytic);

            if (C[cellI].z() >= -0.010 && C[cellI].z() <= -0.004)
            {
                zBandCurrentVsBasisLaplaceAngleStats.add(angleCurrentVsBasisLaplace);
                zBandBasisLaplaceVsAnalyticAngleStats.add(angleBasisLaplaceVsAnalytic);
                zBandCurrentVsAnalyticAngleStats.add(angleCurrentVsAnalytic);
            }
        }

        if
        (
            !finiteScalar(tA)
         || !finiteVector(f0[cellI])
         || (comparisonMode && !finiteVector(f0AnalyticBasisWithLaplaceT[cellI]))
        )
        {
            ++nonFiniteCount;
        }
    }

    const labelListList& cellCells = mesh.cellCells();

    forAll(regularisedCellIDs, i)
    {
        const label cellI = regularisedCellIDs[i];
        vector sum(vector::zero);
        vector reference(vector::zero);
        bool haveReference = false;
        label nNbr = 0;

        const labelList& nbrs = cellCells[cellI];
        forAll(nbrs, nbrI)
        {
            const label nbrCellI = nbrs[nbrI];
            if (!cellRegularised[nbrCellI] && cellFibreSet[nbrCellI])
            {
                addSignAligned(sum, reference, haveReference, f0[nbrCellI]);
                ++nNbr;
            }
        }

        if (!nNbr)
        {
            FatalErrorInFunction
                << "Cannot regularise axis-centred cell from non-axis "
                << "neighbour fibres" << nl
                << "    cell = " << cellI << nl
                << "    C = " << C[cellI] << nl
                << abort(FatalError);
        }

        const vector fibre =
            normalisedOrFatal(sum, "axis-centred cell averaged fibre");
        f0[cellI] = fibre;
        f0Analytic[cellI] = fibre;
        f0AnalyticBasisWithLaplaceT[cellI] = fibre;
        cellFibreSet[cellI] = true;
        f0MagnitudeStats.add(mag(fibre));
    }

    forAll(mesh.C().boundaryField(), patchI)
    {
        const vectorField& patchC = mesh.C().boundaryField()[patchI];
        const scalarField& patchTAnalytic = tAnalytic.boundaryField()[patchI];
        const scalarField& patchTLaplace = tLaplace.boundaryField()[patchI];

        vectorField& patchF0Analytic = f0Analytic.boundaryFieldRef()[patchI];
        vectorField& patchF0 = f0.boundaryFieldRef()[patchI];
        vectorField& patchF0LaplaceT =
            f0AnalyticBasisWithLaplaceT.boundaryFieldRef()[patchI];
        scalarField& patchU = uuAnalytic.boundaryFieldRef()[patchI];
        scalarField& patchV = vvAnalytic.boundaryFieldRef()[patchI];
        scalarField& patchRec =
            coordinateReconstructionError.boundaryFieldRef()[patchI];
        scalarField& patchAlpha =
            alphaRadiansAnalytic.boundaryFieldRef()[patchI];
        scalarField& patchRs = rsAnalytic.boundaryFieldRef()[patchI];
        scalarField& patchRl = rlAnalytic.boundaryFieldRef()[patchI];
        scalarField& patchTDiff = tDifference.boundaryFieldRef()[patchI];
        scalarField& patchAbsTDiff = absTDifference.boundaryFieldRef()[patchI];
        scalarField& patchAngleError = fibreAngleError.boundaryFieldRef()[patchI];
        scalarField& patchAngleCurrentBasis =
            fibreAngleErrorCurrentVsAnalyticBasisLaplaceT.boundaryFieldRef()[patchI];
        scalarField& patchAngleBasisAnalytic =
            fibreAngleErrorAnalyticBasisLaplaceTToAnalytic.boundaryFieldRef()[patchI];
        const labelUList& patchFaceCells = mesh.boundary()[patchI].faceCells();

        forAll(patchC, faceI)
        {
            scalar uu = 0;
            scalar vv = 0;
            scalar recErr = 0;
            bool regularised = false;
            vector fibre(vector::zero);
            vector fibreLaplaceT(vector::zero);

            if (isAxisPoint(patchC[faceI], axisTolerance))
            {
                fibre = normalisedOrFatal
                (
                    f0[patchFaceCells[faceI]],
                    "axis boundary face owner-cell fibre"
                );
                fibreLaplaceT = fibre;
            }
            else
            {
                fibre =
                    analyticFibre
                    (
                        patchC[faceI],
                        patchTAnalytic[faceI],
                        geom,
                        angles,
                        selectedConvention,
                        axisTolerance,
                        uu,
                        vv,
                        recErr,
                        regularised
                    );
            }

            if (comparisonMode && !isAxisPoint(patchC[faceI], axisTolerance))
            {
                scalar uuLaplace = 0;
                scalar vvLaplace = 0;
                scalar recErrLaplace = 0;
                bool regularisedLaplace = false;
                fibreLaplaceT =
                    analyticFibre
                    (
                        patchC[faceI],
                        patchTLaplace[faceI],
                        geom,
                        angles,
                        selectedConvention,
                        axisTolerance,
                        uuLaplace,
                        vvLaplace,
                        recErrLaplace,
                        regularisedLaplace
                    );
            }
            else
            {
                fibreLaplaceT = fibre;
            }

            patchF0Analytic[faceI] = fibre;
            patchF0[faceI] = fibre;
            patchF0LaplaceT[faceI] = fibreLaplaceT;
            patchU[faceI] = uu;
            patchV[faceI] = vv;
            patchRec[faceI] = recErr;
            patchAlpha[faceI] =
                (angles.endoDeg + (angles.epiDeg - angles.endoDeg)*patchTAnalytic[faceI])*pi/180.0;
            patchRs[faceI] = rsAt(patchTAnalytic[faceI], geom);
            patchRl[faceI] = rlAt(patchTAnalytic[faceI], geom);

            if (comparisonMode)
            {
                const scalar diff = patchTLaplace[faceI] - patchTAnalytic[faceI];
                patchTDiff[faceI] = diff;
                patchAbsTDiff[faceI] = mag(diff);

                patchAngleCurrentBasis[faceI] =
                    signInsensitiveAngleDeg
                    (
                        f0Original.boundaryField()[patchI][faceI],
                        fibreLaplaceT
                    );
                patchAngleBasisAnalytic[faceI] =
                    signInsensitiveAngleDeg(fibreLaplaceT, fibre);
                patchAngleError[faceI] =
                    signInsensitiveAngleDeg
                    (
                        f0Original.boundaryField()[patchI][faceI],
                        fibre
                    );
            }

            f0MagnitudeStats.add(mag(fibre));

            if
            (
                !finiteVector(fibre)
             || (comparisonMode && !finiteVector(fibreLaplaceT))
            )
            {
                ++nonFiniteCount;
            }
        }
    }

    const surfaceVectorField& Cf = mesh.Cf();
    const vectorField& CfInternal = Cf;

    forAll(CfInternal, faceI)
    {
        scalar residual = 0;
        const scalar tFace =
            analyticLandTChecked
            (
                CfInternal[faceI],
                geom,
                "internal face " + name(faceI),
                ellipsoidBracketTolerance,
                endoToleranceClamps,
                epiToleranceClamps,
                residual
            );

        maxEllipsoidResidual = max(maxEllipsoidResidual, residual);
        tfAnalytic[faceI] = tFace;
        alphaRadiansfAnalytic[faceI] =
            (angles.endoDeg + (angles.epiDeg - angles.endoDeg)*tFace)*pi/180.0;

        vector fibre(vector::zero);
        if (isAxisPoint(CfInternal[faceI], axisTolerance))
        {
            ++regularisedFaces;
            regularisedInternalFaceIDs.append(faceI);
            vector sum(vector::zero);
            vector reference(vector::zero);
            bool haveReference = false;

            addSignAligned(sum, reference, haveReference, f0[mesh.owner()[faceI]]);
            addSignAligned(sum, reference, haveReference, f0[mesh.neighbour()[faceI]]);

            fibre = normalisedOrFatal(sum, "axis internal face owner/neighbour fibre");
        }
        else
        {
            scalar uu = 0;
            scalar vv = 0;
            scalar recErr = 0;
            bool regularised = false;
            fibre =
                analyticFibre
                (
                    CfInternal[faceI],
                    tFace,
                    geom,
                    angles,
                    selectedConvention,
                    axisTolerance,
                    uu,
                    vv,
                    recErr,
                    regularised
                );
        }

        f0fAnalytic[faceI] = fibre;
        f0f[faceI] = fibre;
        f0fMagnitudeStats.add(mag(fibre));

        if (!finiteScalar(tFace) || !finiteVector(fibre))
        {
            ++nonFiniteCount;
        }
    }

    forAll(Cf.boundaryField(), patchI)
    {
        const vectorField& patchCf = Cf.boundaryField()[patchI];
        const word& patchName = mesh.boundary()[patchI].name();
        const labelUList& patchFaceCells = mesh.boundary()[patchI].faceCells();
        const label startFace = mesh.boundaryMesh()[patchI].start();
        scalarField& patchTf = tfAnalytic.boundaryFieldRef()[patchI];
        scalarField& patchAlphaf = alphaRadiansfAnalytic.boundaryFieldRef()[patchI];
        vectorField& patchF0fAnalytic = f0fAnalytic.boundaryFieldRef()[patchI];
        vectorField& patchF0f = f0f.boundaryFieldRef()[patchI];

        forAll(patchCf, faceI)
        {
            scalar residual = 0;
            scalar tFace = 0;
            bool patchExact = false;

            if (patchName == endocardialPatch)
            {
                tFace = 0;
                residual = mag(ellipsoidResidual(patchCf[faceI], 0, geom));
                patchExact = true;
                ++endocardialPatchAssignments;
            }
            else if (patchName == epicardialPatch)
            {
                tFace = 1;
                residual = mag(ellipsoidResidual(patchCf[faceI], 1, geom));
                patchExact = true;
                ++epicardialPatchAssignments;
            }
            else
            {
                tFace =
                    analyticLandTChecked
                    (
                        patchCf[faceI],
                        geom,
                        "surface boundary patch "
                      + patchName
                      + " face "
                      + name(faceI),
                        ellipsoidBracketTolerance,
                        endoToleranceClamps,
                        epiToleranceClamps,
                        residual
                    );
            }

            if (patchExact)
            {
                maxPatchExactResidual = max(maxPatchExactResidual, residual);
            }
            else
            {
                maxEllipsoidResidual = max(maxEllipsoidResidual, residual);
            }
            patchTf[faceI] = tFace;
            patchAlphaf[faceI] =
                (angles.endoDeg + (angles.epiDeg - angles.endoDeg)*tFace)*pi/180.0;

            vector fibre(vector::zero);
            if (isAxisPoint(patchCf[faceI], axisTolerance))
            {
                ++regularisedFaces;
                regularisedBoundaryFaceIDs.append(startFace + faceI);
                fibre = normalisedOrFatal
                (
                    f0[patchFaceCells[faceI]],
                    "axis boundary face owner-cell fibre"
                );
            }
            else
            {
                scalar uu = 0;
                scalar vv = 0;
                scalar recErr = 0;
                bool regularised = false;
                fibre =
                    analyticFibre
                    (
                        patchCf[faceI],
                        tFace,
                        geom,
                        angles,
                        selectedConvention,
                        axisTolerance,
                        uu,
                        vv,
                        recErr,
                        regularised
                    );
            }

            patchF0fAnalytic[faceI] = fibre;
            patchF0f[faceI] = fibre;
            f0fMagnitudeStats.add(mag(fibre));

            if (!finiteScalar(tFace) || !finiteVector(fibre))
            {
                ++nonFiniteCount;
            }
        }
    }

    Info<< nl << "Transmural coordinate statistics (cells)" << nl;
    printStats("tAnalytic", tAnalyticStats);

    if (comparisonMode)
    {
        printStats("tLaplace", tLaplaceStats);
        printStats("tDifference", tDifferenceStats);
        printStats("absTDifference", absTDifferenceStats);

        Info<< "z band -0.010 <= z <= -0.004 statistics" << nl;
        printStats("zBand tDifference", zBandTDifferenceStats);
        printStats("zBand absTDifference", zBandAbsTDifferenceStats);

        for (label layer = 0; layer < 3; ++layer)
        {
            printStats("layer" + name(layer) + " tDifference", layerTDifferenceStats[layer]);
            printStats("layer" + name(layer) + " absTDifference", layerAbsTDifferenceStats[layer]);
        }

        Info<< nl << "Fibre angle statistics in degrees (cells)" << nl;
        printStats("current vs analytic-basis/Laplace-t", currentVsBasisLaplaceAngleStats);
        printStats("analytic-basis/Laplace-t vs fully analytic", basisLaplaceVsAnalyticAngleStats);
        printStats("current vs fully analytic", currentVsAnalyticAngleStats);
        printStats("current vs fully analytic excluding regularised cells", nonRegularisedCurrentVsAnalyticAngleStats);

        Info<< "z band -0.010 <= z <= -0.004 fibre-angle statistics" << nl;
        printStats("zBand current vs analytic-basis/Laplace-t", zBandCurrentVsBasisLaplaceAngleStats);
        printStats("zBand analytic-basis/Laplace-t vs fully analytic", zBandBasisLaplaceVsAnalyticAngleStats);
        printStats("zBand current vs fully analytic", zBandCurrentVsAnalyticAngleStats);

        for (label layer = 0; layer < 3; ++layer)
        {
            printStats("layer" + name(layer) + " current vs analytic-basis/Laplace-t", layerCurrentVsBasisLaplaceAngleStats[layer]);
            printStats("layer" + name(layer) + " analytic-basis/Laplace-t vs fully analytic", layerBasisLaplaceVsAnalyticAngleStats[layer]);
            printStats("layer" + name(layer) + " current vs fully analytic", layerCurrentVsAnalyticAngleStats[layer]);
        }
    }

    Info<< nl << "Analytic field checks" << nl
        << "maximum solved ellipsoid residual = "
        << maxEllipsoidResidual << nl
        << "maximum patch-exact ellipsoid residual = "
        << maxPatchExactResidual << nl
        << "maximum coordinate reconstruction error = "
        << max(coordinateReconstructionError).value() << nl
        << "patch-exact endocardial t=0 assignments = "
        << endocardialPatchAssignments << nl
        << "patch-exact epicardial t=1 assignments = "
        << epicardialPatchAssignments << nl
        << "endpoint tolerance clamps to endocardium = "
        << endoToleranceClamps << nl
        << "endpoint tolerance clamps to epicardium = "
        << epiToleranceClamps << nl
        << "regularised cells = " << regularisedCells << nl
        << "regularised faces = " << regularisedFaces << nl
        << "non-finite value count = " << nonFiniteCount << nl;
    printStats("f0 magnitude", f0MagnitudeStats);
    printStats("f0f magnitude", f0fMagnitudeStats);

    if (regularisedCellIDs.size())
    {
        Info<< "regularised axis cell IDs = " << regularisedCellIDs << nl;
    }
    if (regularisedInternalFaceIDs.size())
    {
        Info<< "regularised axis internal face IDs = "
            << regularisedInternalFaceIDs << nl;
    }
    if (regularisedBoundaryFaceIDs.size())
    {
        Info<< "regularised axis boundary global face IDs = "
            << regularisedBoundaryFaceIDs << nl;
    }

    if (nonFiniteCount)
    {
        FatalErrorInFunction
            << "Detected " << nonFiniteCount
            << " non-finite analytic field values" << abort(FatalError);
    }

    Info<< nl << "Writing diagnostic and final fields to time "
        << runTime.timeName() << nl;

    tAnalytic.write();
    tfAnalytic.write();
    alphaRadiansAnalytic.write();
    alphaRadiansfAnalytic.write();
    rsAnalytic.write();
    rlAnalytic.write();
    uuAnalytic.write();
    vvAnalytic.write();
    coordinateReconstructionError.write();
    f0Analytic.write();
    f0fAnalytic.write();

    if (comparisonMode)
    {
        tLaplace.write();
        f0LaplaceOrCurrent.write();
        tDifference.write();
        absTDifference.write();
        f0AnalyticBasisWithLaplaceT.write();
        fibreAngleError.write();
        fibreAngleErrorCurrentVsAnalyticBasisLaplaceT.write();
        fibreAngleErrorAnalyticBasisLaplaceTToAnalytic.write();
    }

    t.write();
    f0.write();
    f0f.write();

    Info<< "Done" << nl;

    return 0;
}


// ************************************************************************* //
