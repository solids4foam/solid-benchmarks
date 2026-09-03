
set term pdfcairo dashed enhanced
set datafile separator " "

set output "largeStrainIncompCooksMembrane-neoHookeanTipDispConvergenceStabCompatible.pdf"

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

plot \
    "hex_snes__evenlap_m2.summary.txt" u ($1 >= 2 ? dx/(2**($1-1)) : 1/0):($4*1000) w lp pt 6 ps 1 lw 1.2 lc rgb "red" t "Present work", \
    13.5843 w l dt 2 lw 1.8 lc rgb "black" t "Abaqus CPE4RH"
