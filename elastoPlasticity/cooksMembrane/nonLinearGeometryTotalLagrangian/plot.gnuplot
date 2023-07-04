# Plot vertical top displacement

reset
set output 'nonLinearGeometryTotalLagrangian.verticalDisplacement.eps'
set term postscript color

set style line 1 linecolor rgb 'black' linetype 6 linewidth 2 ps 1.8

set key right bottom
set grid mxtics mytics xtics ytics
set xlabel 'Number of faces per side [-]'
set ylabel 'Vertical top displacement [mm]'
set title 'Convergence of vertical displacement (at 48, 60 mm)'
set xrange [0:140]
set yrange [0:8]

plot "nonLinearGeometryTotalLagrangian.verticalDisplacement.txt" u 1:($4*1000) w lp ls 1 title'Vertical displacment'

set output

