set term pdfcairo dashed enhanced size 5, 2
set datafile separator " "

set output "vibratingCantilever_disp.pdf"

set multiplot
set origin 0,0

set grid
set xrange [0:1]
#set yrange [2.5:3]
set xtics
set ytics
#set logscale x
#set logscale y
#set format y "10^{%L}"
#set ytics 0.002
set xlabel "Time (in s)"
set ylabel "Displacement (in m)"
#set key left top;
#set key right bottom;
set key right bottom outside;
set rmargin 25
set key spacing 1.2
set key at 1.4, -0.4

# Data lines for each p-order (with titles)
set style line 11 lc rgb "red"    pt 7 ps 0.4 lw 1
set style line 12 lc rgb "red"    pt 6 ps 0.4 lw 1
set style line 21 lc rgb "blue"   pt 5 ps 0.4 lw 1
set style line 22 lc rgb "blue"   pt 4 ps 0.4 lw 1
set style line 31 lc rgb "violet" pt 9 ps 0.6 lw 1
set style line 32 lc rgb "violet" pt 8 ps 0.6 lw 1

set style line 41 lc rgb "black" pt 4 ps 0.5 lw 2
set style line 51 lc rgb "grey" pt 8 ps 0.5 lw 1

#set key font ",10"
set object 1 rect from 0.25,2 to 0.45,2.85 fc rgb "red" fs empty border lw 1 lc rgb "red"

plot \
    "cantilever_abaqus_50percent.txt" u 1:2 w l ls 41 t "Abaqus\n (C3D8)\n", \
    "hex.struct.snes.1/postProcessing/0/solidPointDisplacement_pointDisp.dat" u 1:($5) every 10 w l ls 51 t "solids4Foam", \
    "hex.struct.ho.N1.1/postProcessing/0/solidPointDisplacement_pointDisp.dat" u 1:($5) every 10 w lp ls 12 t "{/Times-Italic p}_{ }=1", \
    "hex.struct.ho.N2.1/postProcessing/0/solidPointDisplacement_pointDisp.dat" u 1:($5) every 10 w lp ls 22 t "{/Times-Italic p}_{ }=2", \
    "hex.struct.ho.N3.1/postProcessing/0/solidPointDisplacement_pointDisp.dat" u 1:($5) every 10 w lp ls 32 t "{/Times-Italic p}_{ }=3"


set size 0.2,0.2
set origin 0.85,0.4

set lmargin at screen 0.77
set rmargin at screen 0.98
set bmargin at screen 0.6
set tmargin at screen 0.95

set ytics nomirror
unset y2tics
set ytics ("2" 2, "2.85" 2.85)

set xtics ("0.25" 0.25, "0.45" 0.45)
set grid
set xrange [0.25:0.45]
set yrange [2:2.85]
unset key
#set boxwidth 0.1
set border lw 1.5 lc rgb "red"
unset xlabel
unset ylabel
unset y2tics
unset y2label
set xtics textcolor rgb "black"
set ytics textcolor rgb "black"

plot \
    "cantilever_abaqus_50percent.txt" u 1:2  axes x1y1  w l ls 41 t "Abaqus\n (C3D8)\n", \
    "hex.struct.snes.1/postProcessing/0/solidPointDisplacement_pointDisp.dat" u 1:($5) every 10   axes x1y1 w l ls 51 t "solids4Foam", \
    "hex.struct.ho.N1.1/postProcessing/0/solidPointDisplacement_pointDisp.dat" u 1:($5) every 10   axes x1y1 w lp ls 12 t "{/Times-Italic p}_{ }=1", \
    "hex.struct.ho.N2.1/postProcessing/0/solidPointDisplacement_pointDisp.dat" u 1:($5) every 10   axes x1y1 w lp ls 22 t "{/Times-Italic p}_{ }=2", \
    "hex.struct.ho.N3.1/postProcessing/0/solidPointDisplacement_pointDisp.dat" u 1:($5) every 10   axes x1y1 w lp ls 32 t "{/Times-Italic p}_{ }=3"
