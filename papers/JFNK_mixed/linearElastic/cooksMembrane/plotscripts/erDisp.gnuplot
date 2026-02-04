# ============================================================
# Oosterlee Accuracy — Absolute Difference Plot (Correct Bijelona value)
# ============================================================

set terminal pngcairo enhanced size 1000,700 font "Helvetica,14"
set output "Disp_Accuracy_AbsDiff.png"

set title "Displacement Approach Accuracy — Absolute Difference"
set xlabel "Number of cells per side"
set ylabel "Absolute difference relative to Bijelona finest mesh"
set grid
set logscale y
set key outside top center horizontal

# --- Read last Bijelona displacement from column 1 ---
bijelona_last = real(system("tail -n1 Data/Bijelona.csv | awk -F',' '{print $1}'"))

# --- Plot absolute differences ---
plot \
    "Data/Disp/preprocessed/lu_disp_data_plot.dat" using ($1<192?$1:1/0):(abs($2-bijelona_last)) \
        with linespoints lw 2 lc rgb "blue" pt 7 title "LuFd AbsDiff", \
    "Data/Disp/preprocessed/no_fd_disp_data_plot.dat" using ($1<192?$1:1/0):(abs($2-bijelona_last)) \
        with linespoints lw 2 lc rgb "green" pt 9 title "LuNoFd AbsDiff", \
    "Data/Disp/preprocessed/split_rc_data_plot.dat" using ($1<192?$1:1/0):(abs($2-bijelona_last)) \
        with linespoints lw 2 lc rgb "orange" pt 11 title "Split AbsDiff"

unset output
