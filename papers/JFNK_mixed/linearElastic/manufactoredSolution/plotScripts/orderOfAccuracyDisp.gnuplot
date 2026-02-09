set term pdfcairo dashed enhanced
set datafile separator " "

set output "mms_disp_orderOfAccuracy.pdf"

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
dx=0.04

# Assume the mesh spacing is being halved for each succesive mesh
plot \
    "tet.hypre.orderOfAccuracy.txt" using (1e3*dx/(2**($0+1))):2 skip 1 w lp pt 9 lc "green" t "L_2 - Tet", \
    "tet.hypre.orderOfAccuracy.txt" using (1e3*dx/(2**($0+1))):3 skip 1 w lp pt 8 lc "green" t "L_∞ - Tet", \
    "poly.hypre.orderOfAccuracy.txt" using (1e3*dx/(2**($0+1))):2 skip 1 w lp pt 15 lc "blue" t "L_2 - Poly", \
    "poly.hypre.orderOfAccuracy.txt" using (1e3*dx/(2**($0+1))):3 skip 1 w lp pt 14 lc "blue" t "L_∞ - Poly", \
    "hex.hypre.orderOfAccuracy.txt" using (1e3*dx/(2**($0+1))):2 skip 1 w lp pt 5 lc "red" t "L_2 - Hex", \
    "hex.hypre.orderOfAccuracy.txt" using (1e3*dx/(2**($0+1))):3 skip 1 w lp pt 4 lc "red" t "L_∞ - Hex", \
    "distHex.hypre.orderOfAccuracy.txt" using (1e3*dx/(2**($0+1))):2 skip 1 w lp pt 28 lc rgb "#800080" t "L_2 - Hex (distorted)", \
    "distHex.hypre.orderOfAccuracy.txt" using (1e3*dx/(2**($0+1))):3 skip 1 w lp pt 27 lc rgb "#800080" t "L_∞ - Hex (distorted)"

