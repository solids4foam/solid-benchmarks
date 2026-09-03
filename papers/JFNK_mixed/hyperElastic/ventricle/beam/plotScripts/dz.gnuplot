# Land problem 1: Even-Laplacian m=3 deformed tip-coordinate convergence.
# Run from the beam case directory with: gnuplot plotScripts/dz.gnuplot

system "mkdir -p plots"

set terminal pdfcairo enhanced color size 7.5,4.8 font "Helvetica,10"
set output "plots/land_problem1_m3_verticalDisplacement_vs_cellSize.pdf"
set datafile separator whitespace
set datafile commentschars "#"

unset title
set border lw 1.2
set grid back dt 2 lw 0.50 lc rgb "#d9d9d9"
set logscale x
set xrange [0.012:1.1]
set yrange [0.8:4.5]
set xtics ("0.0139" 0.0138888889, "0.03125" 0.03125, "0.0625" 0.0625, "0.125" 0.125, "0.25" 0.25, "0.5" 0.5, "1" 1.0)
set format y "%g"
set tics nomirror out scale 0.75
set xtics font "Helvetica,16"
set ytics font "Helvetica,16"

set xlabel "Cell size [mm]" font "Helvetica,19" offset 0,-0.8
set ylabel "Deformed tip coordinate, z_{tip} [mm]" font "Helvetica,19" offset -2.0,0
set key inside bottom left vertical Left reverse samplen 2.0 spacing 1.00 width 0 maxrows 2 nobox opaque font "Helvetica,19"

set lmargin 12.0
set rmargin 2.0
set tmargin 1.2
set bmargin 5.5

referenceZmm = 4.2
initialTipZmm = 1.0

set style line 1 lc rgb "#7A2738" pt 2 ps 0.80 lw 2.2
set style line 99 lc rgb "#111111" dt 2 lw 2.2

plot \
    referenceZmm with lines ls 99 title "Land et al. ≈ 4.2 mm", \
    "runs/beam.summary.txt" using 2:(initialTipZmm + 1e3*$4) with linespoints ls 1 title "Even Laplacian, m=3"
