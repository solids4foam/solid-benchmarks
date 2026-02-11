set term pdfcairo dashed enhanced
set datafile separator " "

if (ARGC < 1) {
    print "Error: No input configuration name provided."
    print "usage: ", ARG0, " <caseBaseName>"
    exit
} else {
    base = ARG1
}

set output base.".displacementVsTime.pdf"

# Find matching case directories
cases = system(sprintf("ls -d %s.*/ 2>/dev/null", base))

#set size ratio 1

set grid
set xrange [0:200]
set yrange [-0.35:-0.15]
#set xtics add (25, 50, 100, 200)
set ytics
#set logscale x
#set logscale y
#set format y "10^{%L}"
#set ytics 0.002
set xlabel "Time (in s)"
set ylabel "Vertical displacement (in m)"
set key right bottom

plot for [c in cases] \
    sprintf("%s/postProcessing/0/solidPointDisplacement_pointDisp.dat", c) \
    u 1:($3) w lp lw 2 ps 0.2 title c
