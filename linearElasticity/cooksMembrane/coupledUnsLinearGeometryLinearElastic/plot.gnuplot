# Plot vertical top displacement

reset
set output 'coupledUnsLinearGeometryLinearElastic.verticalDisplacement.eps'
set term postscript color

set style line 1 linecolor rgb 'black' linetype 6 linewidth 2 ps 1.8


set logscale x
set key right top
set grid mxtics mytics xtics ytics
set xlabel 'Number of faces per side [-]'
set ylabel 'Vertical top displacement [m]'
set title 'Convergence of vertical displacement (at 48, 60 mm)'


plot "coupledUnsLinearGeometryLinearElastic.verticalDisplacement.txt" u 1:4 w lp ls 1 title'Vertical displacment'

set output

