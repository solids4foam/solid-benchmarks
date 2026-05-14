set term pdfcairo dashed enhanced
set datafile separator " "

set output "cooksMembrane-neoHookeanTipDispConvergenceStabCompatible.pdf"

set size ratio 0.7
set grid
set xrange [0.098:20]
set yrange [0:16]
set xtics
set logscale x
set format x "%g"
set xlabel "Average cell spacing (in mm)"
set ylabel "Reference point vertical displacement (in mm)"
set key bottom center

# Average mesh spacing of mesh 1
dx=12.649

# Average mesh spacing of mesh 1 for Zienkiewicz and Taylor results
dxZT=18.973666

plot \
    "hex_snes__rhiechow.summary.txt" u (dx/(2**($1-1))):($4*1000) w lp pt 5 ps 1 lw 1.2 lc rgb "#d7191c" t "RhieChow", \
    "hex_snes__laplacian.summary.txt" u (dx/(2**($1-1))):($4*1000) w lp pt 7 ps 1 lw 1.2 lc rgb "#2c7bb6" t "Laplacian", \
    "hex_snes__jst.summary.txt" u (dx/(2**($1-1))):($4*1000) w lp pt 9 ps 1 lw 1.2 lc rgb "#fdae61" t "JST", \
    "hex_snes__evenlap_m0.summary.txt" u (dx/(2**($1-1))):($4*1000) w lp pt 11 ps 1 lw 1.2 lc rgb "#abd9e9" t "EvenLap m0", \
    "hex_snes__evenlap_m1.summary.txt" u (dx/(2**($1-1))):($4*1000) w lp pt 13 ps 1 lw 1.2 lc rgb "#2ca25f" t "EvenLap m1", \
    "hex_snes__evenlap_m2.summary.txt" u (dx/(2**($1-1))):($4*1000) w lp pt 15 ps 1 lw 1.2 lc rgb "#756bb1" t "EvenLap m2", \
    "deal.II.dat" u (dxZT/(2**($0))):($2) w lp pt 8 ps 1 lw 1.2 lc rgb "gray" t "Pelteret and McBride (2016) - Q1", \
    "deal.II.dat" u (dxZT/(2**($0))):($3) w lp pt 4 ps 1 lw 1.2 lc rgb "black" t "Pelteret and McBride (2016) - Q2", \
    "abaqus.dat" u 2:4 w lp pt 4 ps 1 lw 1.2 lc rgb "purple" t "Abaqus (CPE4H)"
