
set term pdfcairo dashed enhanced
set datafile separator " "

set output "mms_dispErrors.pdf"

#set size ratio 1

set grid
set xrange [5:1000]
set yrange [1e-7:1e-3]
set xtics
set xtics add (5, 25, 50)
set ytics
set logscale x
set logscale y
set format y "10^{%L}"
#set ytics 0.002
set xlabel "Average cell spacing (in mm)"
set ylabel "Error (in mm)"
#set key left top;
set key right bottom;

#set label "1^{st} order" at graph 0.5,0.86 center rotate by 10
#set label "2^{nd} order" at graph 0.5,0.37 center rotate by 25

# 15,14 - upturned solid penta
# 5,4 - square

# Assume the mesh spacing is being halved for each succesive mesh
plot \
    "hex.struct.hypre-snes.summary.txt" u ((1/$4)**0.5*1e3):($5*1e-3) w lp pt 9 lc "green" t "L_2 - Hex", \
    "hex.struct.hypre-snes.summary.txt" u ((1/$4)**0.5*1e3):($6*1e-3) w lp pt 8 lc "green" t "L_∞ - Hex", \
    "tet.struct.hypre-snes.summary.txt" u ((4*(1/$4)/3**2)**0.5*1e3):($5*1e-3) w lp pt 9 lc "red" t "L_2 - Tet-struct", \
    "tet.struct.hypre-snes.summary.txt" u ((4*(1/$4)/3**2)**0.5*1e3):($6*1e-3) w lp pt 8 lc "red" t "L_∞ - Tet-struct", \
    "tet.unstruct_v1.hypre-snes.summary.txt" u ((4*(1/$4)/3**2)**0.5*1e3):($5*1e-3) w lp pt 9 lc "orange" t "L_2 - Tet-unstruct-v1", \
    "tet.unstruct_v1.hypre-snes.summary.txt" u ((4*(1/$4)/3**2)**0.5*1e3):($6*1e-3) w lp pt 8 lc "orange" t "L_∞ - Tet-unstruct-v1", \
    "tet.unstruct_v2.hypre-snes.summary.txt" u ((4*(1/$4)/3**2)**0.5*1e3):($5*1e-3) w lp pt 9 lc "yellow" t "L_2 - Tet-unstruct-v2", \
    "tet.unstruct_v2.hypre-snes.summary.txt" u ((4*(1/$4)/3**2)**0.5*1e3):($6*1e-3) w lp pt 8 lc "yellow" t "L_∞ - Tet-unstruct-v2", \
    (3e-9 * x**2) w l lw 2 lc "black" notitle


#    (3e-7 * x) w l lw 2 lc "black" notitle, \
