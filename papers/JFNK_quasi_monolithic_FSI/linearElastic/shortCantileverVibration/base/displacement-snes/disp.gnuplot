set term pdfcairo dashed enhanced size 5, 2
set datafile separator " "

set output "beamEndDisp.pdf"

set grid
set xrange [0:1]
set yrange [0:0.7]
set xtics
set ytics
set xlabel "Time (in s)"
set ylabel "End displacement (in m)"
#set key left top;
set key right bottom outside;
set rmargin 25
set key spacing 1.2

# Data lines for each p-order (with titles)
set style line 1 lc rgb "red"    pt 7 ps 0.4 lw 1.5
set style line 2 lc rgb "blue"   pt 4 ps 0.4 lw 1.5
set style line 3 lc rgb "violet" pt 9 ps 0.6 lw 1.5
set style line 4 lc rgb "black" pt 4 ps 0.005 lw 1.5
set style line 5 lc rgb "black" pt 8 ps 0.4 lw 1.5

plot \
     NaN title "Greendshields paper" with l ls 5,\
    "../../plotScritps/analyticalEndDeflection.txt" u 1:2 w p ls 4 notitle, \
    "./postProcessing/0/solidPointDisplacement_pointDisp.dat" u 1:($5) every 50 w l ls 1 t "solids4Foam"