set term pdfcairo dashed enhanced

if (ARGC < 1) {
    print "usage: ", ARG0, " <campaignSummary.tsv>"
    exit
}
summary = ARG1

set datafile commentschars "#"
set key left top
set grid
set logscale x
set xlabel "{/Symbol D}t (s)"
set format x "%g"

methods = "monolithic.default monolithic.schurTuned monolithic.physicsPC partitioned.IQNILS partitioned.Aitken"

ok(s) = (s eq "ranToEnd")

set output "campaignTimeStepUyAmp.pdf"
set ylabel "u_y half-amplitude (mm)"
plot 34.38 lc rgb "black" dt 3 title "Turek-Hron", \
     33.84 lc rgb "gray" dt 4 title "Tukovic", \
     for [m in methods] summary \
        u ((strcol(2).".".strcol(3) eq m && ok(strcol(8))) ? $7 : 1/0):($17*1000) \
        w lp lw 2 ps 0.5 title m

set output "campaignTimeStepUyFreq.pdf"
set ylabel "u_y frequency (Hz)"
plot 5.3 lc rgb "black" dt 3 title "Turek-Hron", \
     5.53 lc rgb "gray" dt 4 title "Tukovic", \
     for [m in methods] summary \
        u ((strcol(2).".".strcol(3) eq m && ok(strcol(8))) ? $7 : 1/0):18 \
        w lp lw 2 ps 0.5 title m

set output "campaignTimeStepFyAmp.pdf"
set ylabel "F_y half-amplitude (N)"
plot 149.78 lc rgb "black" dt 3 title "Turek-Hron", \
     155.9  lc rgb "gray" dt 4 title "Tukovic", \
     for [m in methods] summary \
        u ((strcol(2).".".strcol(3) eq m && ok(strcol(8))) ? $7 : 1/0):23 \
        w lp lw 2 ps 0.5 title m

set output "campaignTimeStepCost.pdf"
set ylabel "Wall time (s)"
plot for [m in methods] summary \
        u ((strcol(2).".".strcol(3) eq m && ok(strcol(8))) ? $7 : 1/0):11 \
        w lp lw 2 ps 0.5 title m
