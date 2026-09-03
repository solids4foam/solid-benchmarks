set term pdfcairo dashed enhanced
set datafile separator " "

set output "mms_stress_orderOfAccuracy_v2.pdf"

set grid
set xrange [1:50]
set yrange [0:3]
set xtics
set xtics add (5, 25, 50)
set ytics
set logscale x
set xlabel "Average cell spacing (in mm)"
set ylabel "Order of accuracy"
set key bottom right

# Average mesh spacing of mesh1
dx=0.04

dataDir = system("if test -f poly.hypre.orderOfAccuracy.txt; then printf './'; else printf '../'; fi")

# Assume the mesh spacing is being halved for each successive mesh
plot \
    dataDir."poly.hypre.orderOfAccuracy.txt" u (1e3*dx/(2**($1))):4 w lp pt 5 lc rgb "#d7191c" t "L_2 - poly", \
    dataDir."poly.hypre.orderOfAccuracy.txt" u (1e3*dx/(2**($1))):5 w lp pt 4 lc rgb "#d7191c" t "L_inf - poly", \
    dataDir."hex.hypre.orderOfAccuracy.txt" u (1e3*dx/(2**($1))):4 w lp pt 7 lc rgb "#2c7bb6" t "L_2 - hex", \
    dataDir."hex.hypre.orderOfAccuracy.txt" u (1e3*dx/(2**($1))):5 w lp pt 6 lc rgb "#2c7bb6" t "L_inf - hex", \
    dataDir."distHex.hypre.orderOfAccuracy.txt" u (1e3*dx/(2**($1))):4 w lp pt 9 lc rgb "#fdae61" t "L_2 - distHex", \
    dataDir."distHex.hypre.orderOfAccuracy.txt" u (1e3*dx/(2**($1))):5 w lp pt 8 lc rgb "#fdae61" t "L_inf - distHex"
