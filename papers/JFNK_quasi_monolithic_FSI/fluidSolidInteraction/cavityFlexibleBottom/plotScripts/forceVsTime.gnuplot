set term pdfcairo dashed enhanced
#set datafile separator " "

if (ARGC < 1) {
    print "Error: No input configuration name provided."
    print "usage: ", ARG0, " <caseBaseName>"
    exit
} else {
    base = ARG1
}

set output base.".forceVsTime.pdf"

# Find matching case directories
cases = system(sprintf("ls -d %s.*/ 2>/dev/null", base))

#set size ratio 1

set grid
set xrange [0:200]
set yrange [-6000:-4000]
#set xtics add (25, 50, 100, 200)
set ytics
#set logscale x
#set logscale y
#set format y "10^{%L}"
#set ytics 0.002
set xlabel "Time (in s)"
set ylabel "Force (in N)"
set key right top

plot for [c in cases] \
    sprintf("%s/postProcessing/fluid/forces/0/force.dat", c) \
    u 1:3 w lp lw 2 ps 0.2 title c
