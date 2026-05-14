set term pdfcairo dashed enhanced
set datafile separator " "

set output "mms_stress_orderOfAccuracy_v2.pdf"

set grid
set xrange [1:50]
set yrange [0:3]
set xtics
set xtics add (5, 25, 50)
set ytics
set logscale x
set xlabel "Average cell spacing (in mm)"
set ylabel "Order of accuracy"
set key bottom right

# Average mesh spacing of mesh1
dx=0.04

# Assume the mesh spacing is being halved for each successive mesh
plot \
    "rhiechow/hex.hypre.orderOfAccuracy.txt" u (1e3*dx/(2**($1))):4 w lp pt 5 lc rgb "#d7191c" t "L_2 - RhieChow", \
    "rhiechow/hex.hypre.orderOfAccuracy.txt" u (1e3*dx/(2**($1))):5 w lp pt 4 lc rgb "#d7191c" t "L_inf - RhieChow", \
    "laplacian/hex.hypre.orderOfAccuracy.txt" u (1e3*dx/(2**($1))):4 w lp pt 7 lc rgb "#2c7bb6" t "L_2 - Laplacian", \
    "laplacian/hex.hypre.orderOfAccuracy.txt" u (1e3*dx/(2**($1))):5 w lp pt 6 lc rgb "#2c7bb6" t "L_inf - Laplacian", \
    "jst/hex.hypre.orderOfAccuracy.txt" u (1e3*dx/(2**($1))):4 w lp pt 9 lc rgb "#fdae61" t "L_2 - JST", \
    "jst/hex.hypre.orderOfAccuracy.txt" u (1e3*dx/(2**($1))):5 w lp pt 8 lc rgb "#fdae61" t "L_inf - JST", \
    "evenlap_m0/hex.hypre.orderOfAccuracy.txt" u (1e3*dx/(2**($1))):4 w lp pt 11 lc rgb "#abd9e9" t "L_2 - EvenLap m0", \
    "evenlap_m0/hex.hypre.orderOfAccuracy.txt" u (1e3*dx/(2**($1))):5 w lp pt 10 lc rgb "#abd9e9" t "L_inf - EvenLap m0", \
    "evenlap_m1/hex.hypre.orderOfAccuracy.txt" u (1e3*dx/(2**($1))):4 w lp pt 13 lc rgb "#2ca25f" t "L_2 - EvenLap m1", \
    "evenlap_m1/hex.hypre.orderOfAccuracy.txt" u (1e3*dx/(2**($1))):5 w lp pt 12 lc rgb "#2ca25f" t "L_inf - EvenLap m1", \
    "evenlap_m2/hex.hypre.orderOfAccuracy.txt" u (1e3*dx/(2**($1))):4 w lp pt 15 lc rgb "#756bb1" t "L_2 - EvenLap m2", \
    "evenlap_m2/hex.hypre.orderOfAccuracy.txt" u (1e3*dx/(2**($1))):5 w lp pt 14 lc rgb "#756bb1" t "L_inf - EvenLap m2"
