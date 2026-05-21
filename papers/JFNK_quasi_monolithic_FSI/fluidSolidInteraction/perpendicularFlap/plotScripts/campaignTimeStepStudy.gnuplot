set term pdfcairo dashed enhanced

if (ARGC < 1) {
    print "usage: ", ARG0, " <campaignSummary.tsv>"
    exit
}
summary = ARG1

set datafile commentschars "#"
set key outside
set grid
set logscale x
set xlabel "{/Symbol D}t (s)"
set xrange [0.001:*]
set format x "%g"

methods = "monolithic.default monolithic.schurTuned monolithic.physicsPC partitioned.IQNILS partitioned.Aitken"
ok(s) = (s eq "completed")

set output "campaignTimeStepUyExtrema.pdf"
set ylabel "Tip U_y extrema (m)"
plot for [m in methods] summary \
        u ((strcol(2).".".strcol(3) eq m && ok(strcol(7))) ? $6 : 1/0):16 \
        w lp lw 2 ps 0.5 title m." min", \
     for [m in methods] summary \
        u ((strcol(2).".".strcol(3) eq m && ok(strcol(7))) ? $6 : 1/0):17 \
        w lp lw 2 ps 0.5 dt 2 title m." max"

set output "campaignTimeStepFluidFyExtrema.pdf"
set ylabel "Fluid F_y extrema (N)"
plot for [m in methods] summary \
        u ((strcol(2).".".strcol(3) eq m && ok(strcol(7))) ? $6 : 1/0):23 \
        w lp lw 2 ps 0.5 title m." min", \
     for [m in methods] summary \
        u ((strcol(2).".".strcol(3) eq m && ok(strcol(7))) ? $6 : 1/0):24 \
        w lp lw 2 ps 0.5 dt 2 title m." max"

set output "campaignTimeStepCost.pdf"
set ylabel "Wall time (s)"
plot for [m in methods] summary \
        u ((strcol(2).".".strcol(3) eq m && ok(strcol(7))) ? $6 : 1/0):10 \
        w lp lw 2 ps 0.5 title m
