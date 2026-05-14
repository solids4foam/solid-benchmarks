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
set xlabel "{/Symbol D}x (m)"
set xrange [0.009:0.12]
set format x "%g"

methods = "monolithic.default monolithic.schurTuned monolithic.physicsPC partitioned.IQNILS partitioned.Aitken"

set output "campaignMeshDisplacement.pdf"
set ylabel "Steady vertical displacement (m)"
plot "../TukovicDisplacements.csv" u 1:2 w p pt 7 ps 0.8 lc rgb "black" title "Tukovic", \
    for [m in methods] summary \
        u ((strcol(2).".".strcol(3) eq m && strcol(8) ne "failed") ? $6 : 1/0):14 \
        w lp lw 2 ps 0.5 title m

set output "campaignMeshForce.pdf"
set ylabel "Steady vertical interface force (N/m)"
plot "../TukovicForces.csv" u 1:($2*20.0) w p pt 7 ps 0.8 lc rgb "black" title "Tukovic x 20", \
    for [m in methods] summary \
        u ((strcol(2).".".strcol(3) eq m && strcol(8) ne "failed") ? $6 : 1/0):15 \
        w lp lw 2 ps 0.5 title m
