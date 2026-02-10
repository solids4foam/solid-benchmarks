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
set xrange [0:20]
set yrange [1.2:1.4]
#set xtics add (25, 50, 100, 200)
set ytics
#set logscale x
#set logscale y
#set format y "10^{%L}"
#set ytics 0.002
set xlabel "Time (in s)"
set ylabel "Force (in N)"
set key right top

# 15,14 - upturned solid penta
# 5,4 - square

plot for [c in cases] \
    sprintf("%s/postProcessing/fluid/forces/0/force.dat", c) \
    u 1:2 w lp lw 2 title c, \
    1.33 w l lw 2 dt 2 lc rgb "black" title "Richter (2012)"
