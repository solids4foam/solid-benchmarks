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
set xlabel "Plate-thickness cell size (mm)"
set format x "%g"

methods = "monolithic.default monolithic.schurTuned monolithic.physicsPC partitioned.IQNILS partitioned.Aitken"

# Reference values (mm, N)
ux_mean_th = -2.69; ux_amp_th = 2.53
uy_mean_th =  1.48; uy_amp_th = 34.38
fx_mean_th = 457.3; fx_amp_th = 22.66
fy_mean_th =  2.22; fy_amp_th = 149.78

ux_mean_tu = -2.72; ux_amp_tu = 2.58
uy_mean_tu =  1.67; uy_amp_tu = 33.84
fx_mean_tu = 459.18; fx_amp_tu = 24.86
fy_mean_tu =  1.59;  fy_amp_tu = 155.9

# Status filter: only keep ranToEnd
ok(s) = (s eq "ranToEnd")

# Helper plot for a given metric (mm or N) - column index into TSV.
# 13:UxMean 14:UxAmp 15:UxFreq 16:UyMean 17:UyAmp 18:UyFreq
# 19:FxMean 20:FxAmp 21:FxFreq 22:FyMean 23:FyAmp 24:FyFreq

set output "campaignMeshUyMean.pdf"
set ylabel "u_y mean (mm)"
plot uy_mean_th lc rgb "black" dt 3 title "Turek-Hron", \
     uy_mean_tu lc rgb "gray"  dt 4 title "Tukovic", \
     for [m in methods] summary \
        u ((strcol(2).".".strcol(3) eq m && ok(strcol(8))) ? $6 : 1/0) \
        :($16*1000) \
        w lp lw 2 ps 0.5 title m

set output "campaignMeshUyAmp.pdf"
set ylabel "u_y half-amplitude (mm)"
plot uy_amp_th lc rgb "black" dt 3 title "Turek-Hron", \
     uy_amp_tu lc rgb "gray"  dt 4 title "Tukovic", \
     for [m in methods] summary \
        u ((strcol(2).".".strcol(3) eq m && ok(strcol(8))) ? $6 : 1/0) \
        :($17*1000) \
        w lp lw 2 ps 0.5 title m

set output "campaignMeshUyFreq.pdf"
set ylabel "u_y frequency (Hz)"
plot 5.3 lc rgb "black" dt 3 title "Turek-Hron", \
     5.53 lc rgb "gray" dt 4 title "Tukovic", \
     for [m in methods] summary \
        u ((strcol(2).".".strcol(3) eq m && ok(strcol(8))) ? $6 : 1/0):18 \
        w lp lw 2 ps 0.5 title m

set output "campaignMeshFxMean.pdf"
set ylabel "F_x mean (N)"
plot fx_mean_th lc rgb "black" dt 3 title "Turek-Hron", \
     fx_mean_tu lc rgb "gray"  dt 4 title "Tukovic", \
     for [m in methods] summary \
        u ((strcol(2).".".strcol(3) eq m && ok(strcol(8))) ? $6 : 1/0):19 \
        w lp lw 2 ps 0.5 title m

set output "campaignMeshFyAmp.pdf"
set ylabel "F_y half-amplitude (N)"
plot fy_amp_th lc rgb "black" dt 3 title "Turek-Hron", \
     fy_amp_tu lc rgb "gray"  dt 4 title "Tukovic", \
     for [m in methods] summary \
        u ((strcol(2).".".strcol(3) eq m && ok(strcol(8))) ? $6 : 1/0):23 \
        w lp lw 2 ps 0.5 title m
