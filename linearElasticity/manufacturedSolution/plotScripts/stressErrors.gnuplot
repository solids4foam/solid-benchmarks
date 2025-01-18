set term pdfcairo dashed enhanced
set datafile separator " "

set output "mms_stressErrors_v2.pdf"

#set size ratio 1

set grid
set xrange [1:50]
set yrange [0.001:10]
set xtics
set xtics add (5, 25, 50)
set ytics
set logscale x
set logscale y
set format y "10^{%L}"
#set ytics 0.002
set xlabel "Average cell spacing (in mm)"
set ylabel "Error (in MPa)"
#set key left top;
set key right bottom;

set label "1^{st} order" at graph 0.5,0.78 center rotate by 10
set label "2^{nd} order" at graph 0.5,0.264 center rotate by 25

# Average mesh spacing of mesh1
dx=0.04

# Assume the mesh spacing is being halved for each succesive mesh
plot \
    "hex.hypre.summary.txt" u (1e3*dx/(2**($0))):(1e-6*$6) w lp pt 5 lc "red" t "L_2 - Hexahedra", \
    "hex.hypre.summary.txt" u (1e3*dx/(2**($0))):(1e-6*$7) w lp pt 4 lc "red" t "L_∞ - Hexahedra", \
    "tet.hypre.summary.txt" u (1e3*dx/(2**($0))):(1e-6*$6) w lp pt 9 lc "green" t "L_2 - Tetrahedra", \
    "tet.hypre.summary.txt" u (1e3*dx/(2**($0))):(1e-6*$7) w lp pt 8 lc "green" t "L_∞ - Tetrahedra", \
    "poly.hypre.summary.txt" u (1e3*dx/(2**($0))):(1e-6*$6) pt 15 lc "blue" w lp t "L_2 - Polyhedra", \
    "poly.hypre.summary.txt" u (1e3*dx/(2**($0))):(1e-6*$7) pt 14 lc "blue" w lp t "L_∞ - Polyhedra", \
    "orderOfAccuracySlopesStress.dat" u 1:2 w l lw 2 lc "black" notitle, \
    "orderOfAccuracySlopesStress.dat" u 1:3 w l lw 2 lc "black" notitle
