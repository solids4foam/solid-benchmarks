set term pdfcairo dashed enhanced
set datafile separator " "

set output "ventricleInflation-stabLinearIterations.pdf"

set size ratio 0.7
set grid
set xrange [0.1:*]
set yrange [1:*]
set xtics
set logscale x
set logscale y
set format x "%g"
set xlabel "Approximate circumferential cell spacing (in mm)"
set ylabel "Total linear iterations"
set key left top

dx=1.26

plot \
    "hex_snes__rhiechow.iterations.txt" u (dx/(2**($1-1))):4 w lp pt 5 ps 1 lw 1.2 lc rgb "#d7191c" t "RhieChow", \
    "hex_snes__jst.iterations.txt" u (dx/(2**($1-1))):4 w lp pt 9 ps 1 lw 1.2 lc rgb "#fdae61" t "JST", \
    "hex_snes__evenlap_m1.iterations.txt" u (dx/(2**($1-1))):4 w lp pt 13 ps 1 lw 1.2 lc rgb "#2ca25f" t "EvenLap m1"
