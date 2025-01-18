set term pdfcairo dashed enhanced
set datafile separator " "

set output "mms_dispErrors.pdf"

#set size ratio 1

set grid
set xrange [1:50]
set yrange [1e-5:0.2]
set xtics
set xtics add (5, 25, 50)
set ytics
set logscale x
set logscale y
set format y "10^{%L}"
#set ytics 0.002
set xlabel "Average cell spacing (in mm)"
set ylabel "Error (in μm)"
#set key left top;
set key right bottom;

set label "1^{st} order" at graph 0.5,0.86 center rotate by 10
set label "2^{nd} order" at graph 0.5,0.37 center rotate by 25

# Average mesh spacing of mesh1
dx=0.04

# 15,14 - upturned solid penta
# 5,4 - square

# Assume the mesh spacing is being halved for each succesive mesh
plot \
    "tet.hypre.summary.txt" u (1e3*dx/(2**($0))):(1e6*$4) w lp pt 9 lc "green" t "L_2 - Tet", \
    "tet.hypre.summary.txt" u (1e3*dx/(2**($0))):(1e6*$5) w lp pt 8 lc "green" t "L_∞ - Tet", \
    "poly.hypre.summary.txt" u (1e3*dx/(2**($0))):(1e6*$4) pt 15 lc "blue" w lp t "L_2 - Poly", \
    "poly.hypre.summary.txt" u (1e3*dx/(2**($0))):(1e6*$5) pt 14 lc "blue" w lp t "L_∞ - Poly", \
    "hex.hypre.summary.txt" u (1e3*dx/(2**($0))):(1e6*$4) w lp pt 5 lc "red" t "L_2 - Hex", \
    "hex.hypre.summary.txt" u (1e3*dx/(2**($0))):(1e6*$5) w lp pt 4 lc "red" t "L_∞ - Hex", \
    "distHex.hypre.summary.txt" u (1e3*dx/(2**($0))):(1e6*$4) w lp pt 28 lc rgb "#800080" t "L_2 - Hex (distorted)", \
    "distHex.hypre.summary.txt" u (1e3*dx/(2**($0))):(1e6*$5) w lp pt 27 lc rgb "#800080" t "L_∞ - Hex (distorted)", \
    "orderOfAccuracySlopesDisp.dat" u 1:2 w l lw 2 lc "black" notitle, \
    "orderOfAccuracySlopesDisp.dat" u 1:3 w l lw 2 lc "black" notitle
