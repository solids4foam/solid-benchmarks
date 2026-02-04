# ============================================================
# Oosterlee Accuracy Plot — Full, filtered version
# Ignore mesh 7 (number of cells per side = 192)
# ============================================================

set terminal pngcairo enhanced size 1000,700 font "Helvetica,14"
set output "RC_Accuracy.png"

set title "Rhie Chow Accuracy"
set xlabel "Number of cells per side"
set ylabel "Vertical corner displacement"
set grid
set key outside top center horizontal

# --- Plot all datasets with filter ---
plot \
    "Data/Bijelona.csv" using 2:1 with linespoints lw 2 lc rgb "red" pt 7 title "Bijelona Benchmark", \
    "Data/RC/preprocessed/lu_rc_data_plot.dat" using ($1<192?$1:1/0):($1<192?$2:1/0) with linespoints lw 2 lc rgb "blue" pt 7 title "LuFd", \
    "Data/RC/preprocessed/no_fd_rc_data_plot.dat" using ($1<192?$1:1/0):($1<192?$2:1/0) with linespoints lw 2 lc rgb "green" pt 9 title "LuNoFd", \
    "Data/RC/preprocessed/split_rc_data_plot.dat" using ($1<192?$1:1/0):($1<192?$2:1/0) with linespoints lw 2 lc rgb "orange" pt 11 title "Split"

unset output
