set term pdfcairo dashed enhanced
set datafile separator " "

load 'USER_VARIABLE_NAMES'

# Remove "base/" from BASE and concatenate with MACHINE variable
index = strstrt(BASE, "/") + 1
trimmed_BASE = substr(BASE, index, strlen(BASE))
filename = sprintf("times.%s.%s.%s.pdf", trimmed_BASE, MACHINE, SETTINGS)

set output filename

#set size ratio 1

set grid
#set xrange [1:50]
#set yrange [1e-5:0.2]
set xtics
#set xtics add (5, 25, 50)
set ytics
set y2tics
set logscale x
#set logscale y2
#set format y2 "10^{%L}"
#set ytics 0.002
set xlabel "Average cell spacing (in mm)"
set ylabel "Time (in s)"
set y2label "Memory (in kB)"
set key right top;

# Average mesh spacing of mesh1
dx=14.6666666667

legendCurveTime = sprintf("Time - %s", trimmed_BASE)
legendCurveMem = sprintf("Memory - %s", trimmed_BASE)
timesFile = "times.".MACHINE.".".SETTINGS.".txt"

# Assume the mesh spacing is being halved for each succesive mesh
plot timesFile u (dx/(2**($0))):($2) axes x1y1 w lp pt 5 lc "red" t legendCurveTime,\
     timesFile u (dx/(2**($0))):($3) axes x1y2 w lp pt 5 lc "blue" t legendCurveMem
