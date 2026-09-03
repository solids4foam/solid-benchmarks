/*---------------------------------------------------------------------------*\
License
    This file is part of solids4foam.

    solids4foam is free software: you can redistribute it and/or modify it
    under the terms of the GNU General Public License as published by the
    Free Software Foundation, either version 3 of the License, or (at your
    option) any later version.

    solids4foam is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
    or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
    for more details.

    You should have received a copy of the GNU General Public License
    along with solids4foam. If not, see <http://www.gnu.org/licenses/>.
\*---------------------------------------------------------------------------*/

#include "cantileverStressDisplacement.H"

Foam::symmTensor Foam::cantileverStress
(
    const vector& C,
    const scalar P,
    const scalar E,
    const scalar nu,
    const scalar L,
    const scalar D,
    const scalar I
)
{
    symmTensor sigma = symmTensor::zero;

    const scalar x = C.x();
    const scalar y = C.y();

    sigma.xx() = P*(L - x)*y/I;
    sigma.xy() = -(P/(2*I))*(D*D/4 - y*y);

    return sigma;
}


Foam::vector Foam::cantileverDisplacement
(
    const vector& C,
    const scalar P,
    const scalar E,
    const scalar nu,
    const scalar L,
    const scalar D,
    const scalar I
)
{
    vector disp = vector::zero;

    const scalar x = C.x();
    const scalar y = C.y();

    disp.x() = (P*y/(6*E*I))*((6*L - 3*x)*x + (2 + nu)*(y*y - D*D/4));

    disp.y() =
        -(P/(6*E*I))
        *(
            3*nu*y*y*(L - x) + (4 + 5*nu)*D*D*x/4 + (3*L - x)*x*x
        );

    return disp;
}

// ************************************************************************* //
