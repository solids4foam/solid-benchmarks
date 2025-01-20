set term pdfcairo dashed enhanced
set datafile separator " "

set output "cantilever_disp.pdf"

#set size ratio 1

set grid
set xrange [0:1]
#set yrange [1e-5:0.2]
set xtics
#set xtics add (5, 25, 50)
set ytics
#set logscale x
#set logscale y
#set format y "10^{%L}"
#set ytics 0.002
set xlabel "Time (in s)"
set ylabel "Displacement (in m)"
#set key left top;
#set key right bottom;
set key outside right center;

#set label "1^{st} order" at graph 0.5,0.86 center rotate by 10
#set label "2^{nd} order" at graph 0.5,0.37 center rotate by 25

# Average mesh spacing of mesh1
#dx=0.04

# 15,14 - upturned solid penta
# 5,4 - square

# Assume the mesh spacing is being halved for each succesive mesh
plot \
    "hex.hypre.1/postProcessing/0/solidPointDisplacement_pointDisp.dat" u 1:($5) every 10 w lp pt 6 ps 0.6 lc "blue" lw 1 t "{/Symbol \D}x = 33.3 mm", \
    "hex.hypre.2/postProcessing/0/solidPointDisplacement_pointDisp.dat" u 1:($5) every 10 w lp pt 6 ps 0.4 lc "cyan" lw 1 t "{/Symbol \D}x = 16.7 mm", \
    "hex.hypre.3/postProcessing/0/solidPointDisplacement_pointDisp.dat" u 1:($5) every 10 w lp pt 6 ps 0.2 lc "green" lw 1 t "{/Symbol \D}x = 8.3 mm", \
    "hex.hypre.4/postProcessing/0/solidPointDisplacement_pointDisp.dat" u 1:($5) every 10 w lp pt 6 ps 0.1 lc "red" lw 1 t "{/Symbol \D}x = 4.2 mm", \
    "cantilever_abaqus_80percent.txt" u 1:2 w l t "Abaqus (C3D8)"
