#!/usr/bin/gnuplot

set term pngcairo dashed font "Arial,20" size 1920,1080

set linestyle 1 lt 6 lc rgb "black" lw 2 ps 2
set linestyle 2 lt 6 lc rgb "red" lw 2 ps 2
set linestyle 3 lt 6 lc rgb "orange" lw 2 ps 2

set border 3
set tics nomirror
set grid
set key r b
set xrange [0:10]
set xlabel "Rotation angle (in deg)"
set xtics nomirror
set xtics \
(\
    "0°" 0,\
    "0°" 1,\
    "20°" 2,\
    "40°" 3,\
    "60°" 4,\
    "80°" 5,\
    "100°" 6,\
    "120°" 7,\
    "140°" 8,\
    "160°" 9,\
    "180°" 10,\
)

deLorenzisF = "../../data/deLorenzisForce.dat"
deLorenzisT = "../../data/deLorenzisMoment.dat"
febioT = "../../data/febioMoment.dat"

# Force diagram

set output "twistingHemisphereForce.png"
set ylabel "Vertical force (in N)"
set yrange [0:15]
set ytics \
(\
    "0" 0,\
    " "  2.5,\
    "5" 5,\
    " "  7.5,\
    "10" 10,\
    " "  12.5,\
    "15" 15,\
) #offset -1,0,0

plot  \
    "postProcessing/0/solidForcessphere-displacement.dat" u ($1):(-$3*10) w lp ls 1 pi 2 title"solids4foam",\
    deLorenzisF u (($1*9/180)+1):($2*10) w l ls 2 title"R. A. Sauer and L. De Lorenzis"

# Torque diagram

set output "twistingHemisphereTorque.png"
set ytics 1
set yrange [0:5]
set ylabel "Twisting torque (in Nmm)"

plot  \
    "postProcessing/0/solidTorquesphere-displacementsphereTorque.dat" u ($1):($2*10) w lp ls 1 pi 2 title"solids4foam",\
    deLorenzisT u (($1*9/180)+1):($2*10) w l ls 2 title"R. A. Sauer and L. De Lorenzis",\
    febioT u (($1*9/180)+1):($2) w l ls 3 title"B. K. Zimmerman and G. A. Ateshian"
