set term pdfcairo dashed enhanced

summary = "campaignSummary.tsv"

set datafile commentschars "#"
set grid
set key left top
set xtics rotate by -45
set xlabel "Case"

ok(s) = (s eq "completed")

set output "campaignSummaryFinalUy.pdf"
set ylabel "Final tip U_y (m)"
plot summary \
    u 0:(ok(strcol(7)) ? $14 : 1/0):xtic(4) \
    w p pt 7 ps 0.7 title "Final U_y"

set output "campaignSummaryFinalFluidFy.pdf"
set ylabel "Final fluid F_y (N)"
plot summary \
    u 0:(ok(strcol(7)) ? $20 : 1/0):xtic(4) \
    w p pt 7 ps 0.7 title "Final fluid F_y"

set xtics norotate
set xlabel "Total cells"
set xrange [0:*]
set output "campaignSummaryMemory.pdf"
set ylabel "Maximum memory (MB)"
plot summary \
    u ((ok(strcol(7))) ? ($8 + $9) : 1/0):11 \
    w p pt 7 ps 0.7 title "Maximum memory"
