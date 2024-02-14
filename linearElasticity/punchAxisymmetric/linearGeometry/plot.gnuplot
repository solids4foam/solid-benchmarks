reset
set term pngcairo dashed size 1024,768 font "Arial,12"
set datafile separator " "

set style line 1 linecolor rgb 'black' linetype 6 linewidth 2 ps 2
set style line 2 linecolor rgb 'green' linetype 6 linewidth 2 ps 1.8
set style line 3 linecolor rgb 'orange' linetype 6 linewidth 2 ps 1.8
set style line 4 linecolor rgb 'red' linetype 6 linewidth 2 ps 1.8


set grid
set key right top;
set xrange [0:100]
set yrange [-0.018:0.002]
set xtics 10

set ytics 0.002
set output "radialDisplacement.png"
set xlabel "Radius [mm]"
set ylabel "Radial displacement [mm]"

plot "postProcessing/surfaces/1/Dx_cylinderContact.raw" u ($1*1000):($4*1000) w lp ls 1 title"S4F",\
     "../data/radialDisplacementFrictionMARC.dat" u 1:2 w l ls 2 title"MSC.MARC cof=0.1",\
     "../data/radialDisplacementFrictionMARC-quadratic.dat" u 1:2 w p ls 3 title"MSC.MARC cof=0.1 -quadratic",\
     "../data/radialDisplacementFrictionABAQUS-quadratic.dat" u 1:2 w p ls 4 title"ABAQUS cof=0.1 -quadratic"

set ytics 0.02
set yrange [-0.14:0]
set output "axialDisplacement.png"
set xlabel "Radius [mm]"
set ylabel "Axial displacement [mm]"

plot "postProcessing/surfaces/1/Dz_cylinderContact.raw" u ($1*1000):($4*1000) w lp ls 1 title"S4F",\
     "../data/axialDisplacementFrictionMARC.dat" u 1:2 w l ls 2 title"MSC.MARC cof=0.1",\
     "../data/axialDisplacementFrictionMARC-quadratic.dat" u 1:2 w p ls 3 title"MSC.MARC cof=0.1"

set output "contactPressureStress.png"
set xlabel "Radius [mm]"
set yrange [0:450]
set xrange [0:60]
set ytics 50
set ylabel "Normal contact pressure [N/mm^2]"

plot "postProcessing/surfaces/1/slavePressure_cylinderContact_cylinderContact.raw" u (1000*$1):($6*-1e-6) w lp ls 1 title"S4F",\
     "../data/normalPressurePunchMARC.dat" u 1:2 w l ls 2 title"MSC.MARC cof=0.1",\
     "../data/normalPressurePunchABAQUS.dat" u 1:2 w p ls 4 title"ABAQUS cof=0.1"

set output "contactFrictionStress.png"
set xlabel "Radius [mm]"
set ylabel "Contact tangential stress [N/mm^2]"
set yrange [-5:45]
set xrange [0:60]
set ytics 5

plot "postProcessing/surfaces/1/slaveShearTraction_cylinderContact_cylinderContact.raw" u ($1*1000):($4*1e-6) w lp ls 1 title"S4F",\
     "../data/frictionPressurePunchMARC.dat" u 1:2 w l ls 2 title"MSC.MARC cof=0.1",\
     "../data/frictionPressurePunchABAQUS.dat" u 1:2 w p ls 4 title"ABAQUS cof=0.1"
