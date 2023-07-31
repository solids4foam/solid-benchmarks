# `Cook's membrane`

---

Author: Ivan Batistić, 05/2023

---

## Case overview

Cook's membrane is well-known bending-dominated benchmark case. The tapered panel (trapezoid) is fixed on one side and subjected to uniform shear traction on the opposite side. The prescribed shear traction is 6250 Pa. The vertices of the trapezoid (in mm) are (0, 0), (48, 44), (48, 60),  and (0, 44). Membrane geometry is shown in the figure below. Young's modulus is set to 70 Pa and Poisson's ratio to 1/3. Gravitation effects are neglected, and there are no body forces. The problem is solved as static, using one loading increment.

<div style="text-align: center;">
  <img src="./images/membrane_geometry.PNG" alt="Image" width="400">
    <figcaption>
     <strong>Figure 1: Problem geometry</strong>
    </figcaption>
</div>
The script is adjusted to perform simulation on 7 uniformly refined grids.
The coarsest grid consists of 36 CVs and the finest of 147456 CVs.

```warning
The case is set using foam-extend 4.1. 
Other versions of the OpenFOAM may require some small tweaks.
```

---

## Benchmark purpose

* To test solver under different Poisson's ratios (incompressibility)
* The problem is complicated as both shear and bending are present in combination with a skew numerical mesh.

---

## Expected results

* Around the top-left corner, the elastic body is squeezed the most
* The body is stretched the most near the bottom side
* There is no known analytical solution for this problem.

Table 1 summarises FEM results for the values of the vertical displacement of the top right corner [[1]](https://cofea.readthedocs.io/en/latest/benchmarks/002-cook-membrane/results.html).  Figure 2 shows the convergence of the vertical displacement in `solids4Foam`. One can see that refining the mesh solution tends to value reported using quadratic elements on fine mesh. 

**Table 1: FEM results for the vertical displacement in the top right corner, reported in [[1]](https://cofea.readthedocs.io/en/latest/benchmarks/002-cook-membrane/results.html)**

|                          Solver                           | Very Fine Mesh <br>  quadratic (Hexahedral mesh) | Very Fine Mesh <br>  quadratic (Tetrahedral mesh) |
| :-------------------------------------------------------: | :----------------------------------------------: | :-----------------------------------------------: |
|                         Calculix                          |                      32.27                       |                       32.27                       |
|                        Code_Aster                         |                      32.20                       |                       32.20                       |
|                           Elmer                           |                      32.28                       |                       32.27                       |
|    __solids4foam__:  `linearGeometryTotalDisplacement`    |                      32.29                       |                                                   |
| __solids4foam__:  `coupledUnsLinearGeometryLinearElastic` |                      32.33                       |                                                   |

<div style="text-align: center;">
  <img src="./images/vertical_displacement.png" alt="Image" width="800">
    <figcaption>
     <strong>Figure 2: Convergence of the vertical displacement in the top right corner (linearGeometryTotalDisplacement solver)</strong>
    </figcaption>
</div>


---

### Literature 

[1] [https://cofea.readthedocs.io/en/latest/benchmarks/002-cook-membrane/results.html](https://cofea.readthedocs.io/en/latest/benchmarks/002-cook-membrane/results.html)

[2] [Kasper EP, Taylor RL. A mixed-enhanced strain method: 
Part I: Geometrically linear problems. Computers & Structures. 2000 Apr 1;75(3):237-50.](https://www.sciencedirect.com/science/article/abs/pii/S0045794999001340)

[3] [Bijelonja I, Demirdžić I, Muzaferija S. Mixed finite volume method for linear thermoelasticity at all Poisson’s ratios. Numerical Heat Transfer, 
Part A: Applications. 2017 Aug 3;72(3):215-35.](https://www.tandfonline.com/doi/abs/10.1080/10407782.2017.1372665?journalCode=unht20)

[4] [Bijelonja I, Demirdžić I, Muzaferija S. A finite volume method for incompressible linear elasticity. Computer methods in applied mechanics and engineering. 2006 Sep 15;195(44-47):6378-90.](https://www.sciencedirect.com/science/article/abs/pii/S0045782506000387)
