set term pdfcairo dashed enhanced
set datafile separator " "

if (ARGC < 1) {
    print "Error: No input configuration name provided."
    print "usage: ", ARG0, " <caseBaseName>"
    exit
} else {
    base = ARG1
}

cases = system(sprintf("ls -d %s.*/ 2>/dev/null", base))

# Turek-Hron reference for u_y (mm, last period before t=20 s)
uy_mean = 1.48e-3
uy_amp  = 34.38e-3
uy_lo   = uy_mean - uy_amp
uy_hi   = uy_mean + uy_amp

ux_mean = -2.69e-3
ux_amp  = 2.53e-3
ux_lo   = ux_mean - ux_amp
ux_hi   = ux_mean + ux_amp

set grid
set xlabel "Time (s)"
set key right bottom

set output base.".uyVsTime.pdf"
set ylabel "Plate-tip y-displacement (m)"
plot uy_lo lc rgb "gray" dt 2 notitle, \
     uy_hi lc rgb "gray" dt 2 title "Turek-Hron range", \
     uy_mean lc rgb "gray" dt 3 title "Turek-Hron mean", \
     for [c in cases] \
        sprintf("%s/postProcessing/0/solidPointDisplacement_pointDisp.dat", c) \
        u 1:3 w l lw 1.5 title c

set output base.".uxVsTime.pdf"
set ylabel "Plate-tip x-displacement (m)"
plot ux_lo lc rgb "gray" dt 2 notitle, \
     ux_hi lc rgb "gray" dt 2 title "Turek-Hron range", \
     ux_mean lc rgb "gray" dt 3 title "Turek-Hron mean", \
     for [c in cases] \
        sprintf("%s/postProcessing/0/solidPointDisplacement_pointDisp.dat", c) \
        u 1:2 w l lw 1.5 title c
