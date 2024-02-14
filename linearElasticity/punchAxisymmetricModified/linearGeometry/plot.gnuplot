reset
set term pngcairo dashed size 1024,768 font "Arial,12"
set datafile separator " "

set style line 1 linecolor rgb 'black' linetype 6 linewidth 2 ps 2
set style line 2 linecolor rgb 'black' linetype 4 linewidth 2 ps 2
set style line 3 linecolor rgb 'red' linetype 6 linewidth 2 ps 1.8

# Analytical solution for a
a=14.2857142857143

# Analytical solution for peak contact pressure
pm=696503868.508771

set grid

set xrange [0:50]
set yrange [-0.026:0.002]
set xtics 10
set ytics 0.002
set output "radialDisplacement.png"
set xlabel "Radius [mm]"
set ylabel "Radial displacement [mm]"
set key right bottom;

plot "postProcessing/surfaces/1/Dx_cylinderContact.raw" u ($1*1000):($4*1000) w lp ls 1 title"cylinder",\
     "postProcessing/surfaces/1/Dx_punchContact.raw" u ($1*1000):($4*1000) w lp ls 2 title"punch"

set ytics 0.02
set yrange [-0.16:0]
set output "axialDisplacement.png"
set xlabel "Radius [mm]"
set ylabel "Axial displacement [mm]"
set key right top;

plot "postProcessing/surfaces/1/Dz_cylinderContact.raw" u ($1*1000):($4*1000) w lp ls 1 title"cylinder"

set output "contactPressureStress.png"
set xlabel "r / a [-]"
set yrange [-0.1:1.7]
set xrange [0:1.1]
set ytics 0.2
set xtics 0.1
set ylabel "p_n / p_m [-]"

plot "postProcessing/surfaces/1/slavePressure_cylinderContact_cylinderContact.raw" u ((1000/a)*$1):(-$6/pm) w lp ls 1 title"S4F",\
     "../data/analytical_ab07.dat" u 1:2 w l ls 3 title"Analytical",\

set output "contactFrictionStress.png"
set xlabel "r / a [-]"
set ylabel "Contact tangential stress [MPa]"
set autoscale y
set xrange [0:1.1]
set ytics 0.1
set xtics 0.1

analyticalShearTrac(x)=0

plot "postProcessing/surfaces/1/slaveShearTraction_cylinderContact_cylinderContact.raw" u ((1000/a)*$1):($6*1e-6) w lp ls 1 title"S4F",\
     analyticalShearTrac(x) w l ls 3 title"Analytical"
