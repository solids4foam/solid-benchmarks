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
set xrange [0:0.08]
#set yrange [0.5:1.5]
set ytics
#set format y "10^{%L}"
set xlabel "Time (in s)"
set ylabel "Displacement (in mm)"
set key right bottom

# 15,14 - upturned solid penta
# 5,4 - square

plot for [c in cases] \
    sprintf("%s/postProcessing/0/solidPointDisplacement_displacement.dat", c) \
    u 1:(1e3*$2) w lp lw 2 title c, \
    1.016 w l lw 2 dt 2 lc rgb "black" title "Tukovic et al. (2018)"
