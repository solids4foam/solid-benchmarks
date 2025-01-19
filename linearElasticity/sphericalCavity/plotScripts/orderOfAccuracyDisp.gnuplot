set term pdfcairo dashed enhanced
set datafile separator " "

set output "sphericalCavityDispOrder.pdf"

set grid
set xrange [1:50]
set yrange [0:3]
set xtics
set xtics add (5, 25, 50)
set ytics
set logscale x
#set logscale y
#set ytics 0.002
set xlabel "Average cell spacing (in mm)"
set ylabel "Order of accuracy"
set key bottom left;

# Average mesh spacing of mesh1
# Calculated as the cbrt(meshVolume/numCells)
dx = cbrt(0.120845/976)

# Assume the mesh spacing is being halved for each succesive mesh
plot \
    "poly.hypre.orderOfAccuracy.txt" using (1e3*dx/(2**($0+1))):2 w lp pt 15 lc "blue" t "L_2", \
    "poly.hypre.orderOfAccuracy.txt" using (1e3*dx/(2**($0+1))):3 w lp pt 14 lc "blue" t "L_∞"
