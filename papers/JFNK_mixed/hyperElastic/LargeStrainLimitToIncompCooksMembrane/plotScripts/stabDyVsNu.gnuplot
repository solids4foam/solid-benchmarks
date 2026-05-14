set term pdfcairo dashed enhanced
set datafile separator ","

set output "largeStrainLimitToIncompCooksMembrane-stabDyVsNu.pdf"

set size ratio 0.7
set grid
set xrange [0.29:0.501]
set xtics
set xlabel "Poisson ratio"
set ylabel "Reference point vertical displacement (mm)"
set key left top

mesh=2
file="all_results.csv"

plot \
    file u (strcol(2) eq "disp" && $4 == mesh ? $3 : 1/0):($7*1000) w lp pt 3 ps 1 lw 1.2 lc rgb "black" t "Displacement", \
    file u (strcol(2) eq "rhiechow" && $4 == mesh ? $3 : 1/0):($7*1000) w lp pt 5 ps 1 lw 1.2 lc rgb "#d7191c" t "RhieChow", \
    file u (strcol(2) eq "laplacian" && $4 == mesh ? $3 : 1/0):($7*1000) w lp pt 7 ps 1 lw 1.2 lc rgb "#2c7bb6" t "Laplacian", \
    file u (strcol(2) eq "jst" && $4 == mesh ? $3 : 1/0):($7*1000) w lp pt 9 ps 1 lw 1.2 lc rgb "#fdae61" t "JST", \
    file u (strcol(2) eq "evenlap_m0" && $4 == mesh ? $3 : 1/0):($7*1000) w lp pt 11 ps 1 lw 1.2 lc rgb "#abd9e9" t "EvenLap m0", \
    file u (strcol(2) eq "evenlap_m1" && $4 == mesh ? $3 : 1/0):($7*1000) w lp pt 13 ps 1 lw 1.2 lc rgb "#2ca25f" t "EvenLap m1", \
    file u (strcol(2) eq "evenlap_m2" && $4 == mesh ? $3 : 1/0):($7*1000) w lp pt 15 ps 1 lw 1.2 lc rgb "#756bb1" t "EvenLap m2"
