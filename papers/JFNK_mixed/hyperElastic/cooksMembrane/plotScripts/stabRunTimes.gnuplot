set term pdfcairo dashed enhanced
set datafile separator " "

set output "cooksMembrane-stabRunTimes.pdf"

set size ratio 0.7
set grid
set xrange [0.098:20]
set yrange [0.1:*]
set xtics
set logscale x
set logscale y
set format x "%g"
set xlabel "Average cell spacing (in mm)"
set ylabel "Clock time (s)"
set key left top

dx=12.649

plot \
    "hex_snes__rhiechow.summary.txt" u (dx/(2**($1-1))):($2 > 0 ? $2 : 0.1) w lp pt 5 ps 1 lw 1.2 lc rgb "#d7191c" t "RhieChow", \
    "hex_snes__laplacian.summary.txt" u (dx/(2**($1-1))):($2 > 0 ? $2 : 0.1) w lp pt 7 ps 1 lw 1.2 lc rgb "#2c7bb6" t "Laplacian", \
    "hex_snes__jst.summary.txt" u (dx/(2**($1-1))):($2 > 0 ? $2 : 0.1) w lp pt 9 ps 1 lw 1.2 lc rgb "#fdae61" t "JST", \
    "hex_snes__evenlap_m0.summary.txt" u (dx/(2**($1-1))):($2 > 0 ? $2 : 0.1) w lp pt 11 ps 1 lw 1.2 lc rgb "#abd9e9" t "EvenLap m0", \
    "hex_snes__evenlap_m1.summary.txt" u (dx/(2**($1-1))):($2 > 0 ? $2 : 0.1) w lp pt 13 ps 1 lw 1.2 lc rgb "#2ca25f" t "EvenLap m1", \
    "hex_snes__evenlap_m2.summary.txt" u (dx/(2**($1-1))):($2 > 0 ? $2 : 0.1) w lp pt 15 ps 1 lw 1.2 lc rgb "#756bb1" t "EvenLap m2"
