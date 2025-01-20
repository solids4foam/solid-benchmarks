set term pdfcairo dashed enhanced
set datafile separator " "

set output "cooksMembrane-hookeanTipDispConvergence.pdf"

set size ratio 0.7

set grid
set xrange [0.099:20]
set yrange [14:34]
set xtics
#set ytics (0.7, 0.8, 0.9, 1)

set logscale x
set format x "%g"

#set logscale y
#set ytics 0.002
set xlabel "Average cell spacing (in mm)"
set ylabel "Reference point vertical displacement (in µm)"
set key bottom center

# Average mesh spacing of mesh1
# Area is 0.00144
# First mesh have 9 elements and one element area is then 0.00016. sqrt of that is 0.012649
dx=12.649

#Average mesh spacing of mesh 1 for Zienkiewicz and Taylor results
dxZT = 18.973666

file = "hex.lu.summary.txt"
file_ZT = "ZienkiewiczAndTaylor.dat"
file_A = "abaqus.dat"

# Assume the mesh spacing is being halved for each succesive mesh
plot \
    file u (dx/(2**($0))):($4*1000*1000) w lp pt 6 ps 1.2 lw 1.2 lc "red" t "Present work",\
    file_ZT u (dxZT/(2**($0))):($2) w lp pt 8 ps 1.2 lw 1.2 lc "gray" t "Zienkiewicz and Taylor (2000) - Q4",\
    file_A u 2:4 w lp pt 4 ps 1.2 lw 1.2 lc "black" t "Abaqus (CPE4H)"
