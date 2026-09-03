set term pdfcairo dashed enhanced
set datafile separator " "

# Run this script from the problem2 directory after creating
# runs/mesh1 ... runs/mesh4/midLineDeformed.txt.

set output "midline.pdf"

set size ratio -1

set grid
set xrange [-14:0]
set yrange [-28:5.01]
set xtics 5
#set xtics add (5, 25, 50)
set ytics
#set logscale x
#set logscale y
#set format y "10^{%L}"
#set ytics 0.002
set xlabel "x (in mm)"
set ylabel "z (in mm)"
#set key left top;
#set key right bottom;
set key outside left center;

#set label "1^{st} order" at graph 0.5,0.86 center rotate by 10
#set label "2^{nd} order" at graph 0.5,0.37 center rotate by 25

# Calculate the deltaX as cbrt(totalVolume/numCells)
plot \
    "runs/mesh1/midLineDeformed.txt" u (1e3*$1):(1e3*$3) every 9::0 w lp pt 5 ps 0.75 lc rgb "#d7191c" t "Mesh 1", \
    "runs/mesh2/midLineDeformed.txt" u (1e3*$1):(1e3*$3) every 9::0 w lp pt 9 ps 0.8 lc rgb "#fdae61" t "Mesh 2", \
    "runs/mesh3/midLineDeformed.txt" u (1e3*$1):(1e3*$3) every 9::0 w lp pt 13 ps 0.6 lc rgb "#2ca25f" t "Mesh 3"

# Apex plot
set output "midline_apex.pdf"
set xrange [-5:0]
set yrange [-28:-25]
set size ratio 1
plot \
    "runs/mesh1/midLineDeformed.txt" u (1e3*$1):(1e3*$3) w lp pt 5 ps 0.75 lc rgb "#d7191c" t "Mesh 1", \
    "runs/mesh2/midLineDeformed.txt" u (1e3*$1):(1e3*$3) w lp pt 9 ps 0.8 lc rgb "#fdae61" t "Mesh 2", \
    "runs/mesh3/midLineDeformed.txt" u (1e3*$1):(1e3*$3) w lp pt 13 ps 0.6 lc rgb "#2ca25f" t "Mesh 3"

# Inflection plot
set output "midline_inflection.pdf"
set xrange [-13.5:-12.3]
set yrange [-9:-2]
set xtics 0.5
set size ratio 1
plot \
    "runs/mesh1/midLineDeformed.txt" u (1e3*$1):(1e3*$3) w lp pt 5 ps 0.75 lc rgb "#d7191c" t "Mesh 1", \
    "runs/mesh2/midLineDeformed.txt" u (1e3*$1):(1e3*$3) w lp pt 9 ps 0.8 lc rgb "#fdae61" t "Mesh 2", \
    "runs/mesh3/midLineDeformed.txt" u (1e3*$1):(1e3*$3) w lp pt 13 ps 0.6 lc rgb "#2ca25f" t "Mesh 3"
