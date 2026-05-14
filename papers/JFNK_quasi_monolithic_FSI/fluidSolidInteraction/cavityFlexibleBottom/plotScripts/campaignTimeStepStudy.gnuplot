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

set output "campaignTimeStepDisplacement.pdf"
set ylabel "Steady vertical displacement (m)"
plot for [m in methods] summary \
        u ((strcol(2).".".strcol(3) eq m && strcol(8) ne "failed") ? $7 : 1/0):14 \
        w lp lw 2 ps 0.5 title m

set output "campaignTimeStepForce.pdf"
set ylabel "Steady vertical interface force (N/m)"
plot for [m in methods] summary \
        u ((strcol(2).".".strcol(3) eq m && strcol(8) ne "failed") ? $7 : 1/0):15 \
        w lp lw 2 ps 0.5 title m

set output "campaignTimeStepCost.pdf"
set ylabel "Wall time (s)"
plot for [m in methods] summary \
        u ((strcol(2).".".strcol(3) eq m && strcol(8) ne "failed") ? $7 : 1/0):11 \
        w lp lw 2 ps 0.5 title m
