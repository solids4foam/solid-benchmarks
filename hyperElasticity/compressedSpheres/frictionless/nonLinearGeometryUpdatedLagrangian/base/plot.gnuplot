#!/usr/bin/gnuplot

set term pngcairo dashed font "Arial,20" size 1920,1080

set linestyle 1 lt 6 lc rgb "black" lw 2 ps 2
set linestyle 2 lt 6 lc rgb "red" lw 2 ps 2
set linestyle 3 lt 6 lc rgb "orange" lw 2 ps 2
set linestyle 4 lt 6 lc rgb "green" lw 2 ps 2
set linestyle 5 lt 6 lc rgb "purple" lw 2 ps 2

set border 3
set tics nomirror
set grid
set xlabel "Displacement (in mm)"
set ylabel "Force (in N)"
set key right top;
set xrange [0:9]
set yrange [0:6]

Areias = "../../../data/frictionless/Areias.csv"
Puso = "../../../data/frictionless/Puso&Laursen.csv"
FEBio = "../../../data/frictionless/FEBio.csv"
Abaqus = "../../../data/frictionless/Abaqus.csv"

set output "compressedSpheres.png"

plot Abaqus u ($1):($2) w l ls 4 title"Abaqus",\
     Areias u ($1*10):(-$2) w l ls 2 title"Areias",\
     FEBio u ($1*10):(-$2) w l ls 3 title"FEBio",\
     Puso u ($1*10):(-$2) w p ls 5 title"Puso and Laursen",\
     "postProcessing/0/solidForcesR_top.dat" u ($1*10):($4) w lp ls 1 title"solids4foam"
