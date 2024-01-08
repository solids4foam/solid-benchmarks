#!/usr/bin/gnuplot

set term pngcairo dashed font "Arial,20" size 1920,1080

set linestyle 1 lt 6 lc rgb "black" lw 2 ps 2
set linestyle 2 lt 6 lc rgb "red" lw 2 ps 2

set grid
set xlabel "y [m]" 
set xrange[0:1]

set key r b
set sample 100

# Analytical solution
rho = 7800      # Density
E = 2.1e11      # Young modulus
L = 1           # Lenght
g = 9.80665     # Gravity

sigma(x) = g*rho*x
displacement(x) =  (g*rho*L**2)/(2.0*E) - (g*rho*x**2)/(2.0*E)

set output 'sigma.png'
set ylabel "{/Symbol s}_{yy}  [Pa]"
plot \
    sigma(x) w l ls 2 title'analytical',\
    "postProcessing/sets/1/line_sigma.xy" u 1:5 w lp ls 1 title"solids4foam"
    
set output 'displacement.png'
set ylabel "D_y  [m]"
set key r t
plot \
    displacement(x) w l ls 2 title'analytical',\
    "postProcessing/sets/1/line_D.xy" u 1:(-$3) w lp ls 1 title"solids4foam"
