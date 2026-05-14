set term pdfcairo dashed enhanced
set datafile separator " "
set output "land_problem1_dz_comparison.pdf"

set grid
set xrange [0.03:0.6]
set yrange [*:*]
set logscale x
set xtics (0.5, 0.25, 0.125, 0.0625, 0.03125)

set xlabel "Cell size (in mm)"
set ylabel "Dz (in mm)"
set key outside right center

# Mesh 1 has 1 mm cells; each mesh level halves the cell size.
cellSize(mesh) = 1.0/(2**(mesh - 1))

plot \
    "displacement/beam.summary.txt" u (cellSize($1)):(1e3*$4) w lp pt 5 lc rgb "#222222" t "Displacement only", \
    "rhiechow/beam.summary.txt" u (cellSize($1)):(1e3*$4) w lp pt 7 lc rgb "#d7191c" t "RhieChow", \
    "laplacian/beam.summary.txt" u (cellSize($1)):(1e3*$4) w lp pt 9 lc rgb "#2c7bb6" t "Laplacian", \
    "jst/beam.summary.txt" u (cellSize($1)):(1e3*$4) w lp pt 11 lc rgb "#fdae61" t "JST", \
    "evenlap_m0/beam.summary.txt" u (cellSize($1)):(1e3*$4) w lp pt 13 lc rgb "#abd9e9" t "EvenLap m0", \
    "evenlap_m1/beam.summary.txt" u (cellSize($1)):(1e3*$4) w lp pt 15 lc rgb "#2ca25f" t "EvenLap m1", \
    "evenlap_m2/beam.summary.txt" u (cellSize($1)):(1e3*$4) w lp pt 17 lc rgb "#756bb1" t "EvenLap m2"
