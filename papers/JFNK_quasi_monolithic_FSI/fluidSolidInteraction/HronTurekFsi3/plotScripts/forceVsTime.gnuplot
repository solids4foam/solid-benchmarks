set term pdfcairo dashed enhanced
set datafile separator " "
set datafile commentschars "#"

if (ARGC < 1) {
    print "usage: ", ARG0, " <caseBaseName>"
    exit
} else {
    base = ARG1
}

cases = system(sprintf("ls -d %s.*/ 2>/dev/null", base))

# Turek-Hron reference (N).
fx_mean = 457.3
fx_amp  = 22.66
fx_lo   = fx_mean - fx_amp
fx_hi   = fx_mean + fx_amp

fy_mean = 2.22
fy_amp  = 149.78
fy_lo   = fy_mean - fy_amp
fy_hi   = fy_mean + fy_amp

set grid
set xlabel "Time (s)"
set key right bottom

# OpenFOAM forces.dat columns: time (px py pz) (vx vy vz) (...)
# After parenthesis stripping, indices are: 1=t, 2:px, 3:py, 4:pz, 5:vx, 6:vy, 7:vz

set output base.".fxVsTime.pdf"
set ylabel "Plate F_x (N)"
plot fx_lo lc rgb "gray" dt 2 notitle, \
     fx_hi lc rgb "gray" dt 2 title "Turek-Hron range", \
     fx_mean lc rgb "gray" dt 3 title "Turek-Hron mean", \
     for [c in cases] \
        sprintf("< sed 's/[()]/ /g' %s/postProcessing/forces/0/force.dat", c) \
        u 1:($2+$5) w l lw 1.5 title c

set output base.".fyVsTime.pdf"
set ylabel "Plate F_y (N)"
plot fy_lo lc rgb "gray" dt 2 notitle, \
     fy_hi lc rgb "gray" dt 2 title "Turek-Hron range", \
     fy_mean lc rgb "gray" dt 3 title "Turek-Hron mean", \
     for [c in cases] \
        sprintf("< sed 's/[()]/ /g' %s/postProcessing/forces/0/force.dat", c) \
        u 1:($3+$6) w l lw 1.5 title c
