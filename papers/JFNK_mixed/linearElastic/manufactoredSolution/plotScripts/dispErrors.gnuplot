set term pdfcairo dashed enhanced
set datafile separator " "

set output "mms_dispErrors.pdf"

set grid
set xrange [1:50]
set yrange [1e-6:10]
set xtics
set xtics add (5, 25, 50)
set ytics
set logscale x
set logscale y
set format y "10^{%L}"
set xlabel "Average cell spacing (in mm)"
set ylabel "Error (in um)"
set key right bottom

set label "1^{st} order" at graph 0.5,0.80 center rotate by 10
set label "2^{nd} order" at graph 0.5,0.313 center rotate by 25

# Average mesh spacing of mesh1
dx=0.04

dataDir = system("if test -f poly.hypre.summary.txt; then printf './'; else printf '../'; fi")
slopeDir = system("if test -f orderOfAccuracySlopesDisp.dat; then printf './'; else printf 'plotScripts/'; fi")

# Assume the mesh spacing is being halved for each successive mesh
plot \
    dataDir."poly.hypre.summary.txt" u (1e3*dx/(2**($1-1))):(1e6*$4) w lp pt 5 lc rgb "#d7191c" t "L_2 - poly", \
    dataDir."poly.hypre.summary.txt" u (1e3*dx/(2**($1-1))):(1e6*$5) w lp pt 4 lc rgb "#d7191c" t "L_inf - poly", \
    dataDir."hex.hypre.summary.txt" u (1e3*dx/(2**($1-1))):(1e6*$4) w lp pt 7 lc rgb "#2c7bb6" t "L_2 - hex", \
    dataDir."hex.hypre.summary.txt" u (1e3*dx/(2**($1-1))):(1e6*$5) w lp pt 6 lc rgb "#2c7bb6" t "L_inf - hex", \
    dataDir."distHex.hypre.summary.txt" u (1e3*dx/(2**($1-1))):(1e6*$4) w lp pt 9 lc rgb "#fdae61" t "L_2 - distHex", \
    dataDir."distHex.hypre.summary.txt" u (1e3*dx/(2**($1-1))):(1e6*$5) w lp pt 8 lc rgb "#fdae61" t "L_inf - distHex", \
    slopeDir."orderOfAccuracySlopesDisp.dat" u 1:(7.0*$2) w l lw 2 lc "black" notitle, \
    slopeDir."orderOfAccuracySlopesDisp.dat" u 1:3 w l lw 2 lc "black" notitle
