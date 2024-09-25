set term pdfcairo dashed enhanced
set datafile separator " "

load 'USER_VARIABLE_NAMES'

# Remove "base/" from BASE and concatenate with MACHINE variable
index = strstrt(BASE, "/") + 1
trimmed_BASE = substr(BASE, index, strlen(BASE))
filename = sprintf("disp.%s.%s.%s.pdf", trimmed_BASE, MACHINE, SETTINGS)

set output filename

#set size ratio 1

set grid
#set xrange [1:50]
#set yrange [1e-5:0.2]
set xtics
#set xtics add (5, 25, 50)
set ytics
#set y2tics
set logscale x
#set logscale y
#set format y "10^{%L}"
set ytics 1
set xlabel "Average cell spacing (in mm)"
set ylabel "Vertical Displacement (in mm)"
set key right top;

# Average mesh spacing of mesh1
dx=0.012649

legendCurveName = sprintf("U_2 - %s", trimmed_BASE)
timesFile = "times.".MACHINE.".".SETTINGS.".txt"

# Assume the mesh spacing is being halved for each succesive mesh
plot timesFile u (dx/(2**($0))):($4*1000) w lp pt 6 ps 1.5 lc "red" t legendCurveName
