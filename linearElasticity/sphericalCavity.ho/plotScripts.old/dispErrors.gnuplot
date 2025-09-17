set term pdfcairo dashed enhanced
set datafile separator " "

set output "sphericalCavityDispError.pdf"

#set size ratio 1

set grid
set xrange [1:100]
set yrange [1e-5:0.1]
set xtics
#set xtics add (5, 25, 50)
set ytics
set logscale x
set logscale y
set format y "10^{%L}"
#set ytics 0.002
set xlabel "Average cell spacing (in mm)"
set ylabel "Error (in μm)"
#set key left top;
set key right bottom;

set label "1^{st} order" at graph 0.5,0.86 center rotate by 12
set label "2^{nd} order" at graph 0.5,0.37 center rotate by 30

# Average mesh spacing of mesh1
# Calculated as the cbrt(meshVolume/numCells)
dx = cbrt(0.120845/976)

# Assume the mesh spacing is being halved for each succesive mesh
plot \
    "poly.hypre.summary.txt" u (1e3*dx/(2**($0))):(1e6*$4) w lp pt 15 lc "blue" t "L_2", \
    "poly.hypre.summary.txt" u (1e3*dx/(2**($0))):(1e6*$5) w lp pt 14 lc "blue" t "L_∞", \
    "orderOfAccuracySlopesDisp.dat" u 1:2 w l lw 2 lc "black" notitle, \
    "orderOfAccuracySlopesDisp.dat" u 1:3 w l lw 2 lc "black" notitle
