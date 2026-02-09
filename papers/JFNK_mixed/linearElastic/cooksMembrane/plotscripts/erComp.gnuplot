# ============================================================
# Comparison Absolute Difference Plot — Mixed, Oosterlee, RC, Disp vs Bijelona
# ============================================================

set terminal pngcairo enhanced size 1200,800 font "Helvetica,14"
set output "Comparison_AbsDiff.png"

set title "Comparison of Geometries — Absolute Difference"
set xlabel "Number of cells per side"
set ylabel "Absolute difference relative to Bijelona finest mesh"
set grid
set logscale y
set key outside top center horizontal

# --- Read last Bijelona displacement from column 1 ---
bijelona_last = real(system("tail -n1 Data/Bijelona.csv | awk -F',' '{print $1}'"))

# --- Plot all datasets as absolute differences ---
plot \
    "Data/Mixed/preprocessed/lu_stab_data_plot.dat" using ($1<192?$1:1/0):(abs($2-bijelona_last)) with linespoints lw 2 lc rgb "#1f77b4" pt 7 title "Mixed LuFd", \
    "Data/Mixed/preprocessed/no_fd_stab_data_plot.dat" using ($1<192?$1:1/0):(abs($2-bijelona_last)) with linespoints lw 2 lc rgb "#2ca02c" pt 9 title "Mixed LuNoFd", \
    "Data/Mixed/preprocessed/split_stab_data_plot.dat" using ($1<192?$1:1/0):(abs($2-bijelona_last)) with linespoints lw 2 lc rgb "#ff7f0e" pt 11 title "Mixed Split", \
    "Data/Oosterlee_Data/preprocessed/lu_stab_data_plot.dat" using ($1<192?$1:1/0):(abs($2-bijelona_last)) with linespoints lw 2 lc rgb "#17becf" pt 7 title "Oosterlee LuFd", \
    "Data/Oosterlee_Data/preprocessed/no_fd_stab_data_plot.dat" using ($1<192?$1:1/0):(abs($2-bijelona_last)) with linespoints lw 2 lc rgb "#bcbd22" pt 9 title "Oosterlee LuNoFd", \
    "Data/Oosterlee_Data/preprocessed/split_stab_data_plot.dat" using ($1<192?$1:1/0):(abs($2-bijelona_last)) with linespoints lw 2 lc rgb "#d62728" pt 11 title "Oosterlee Split", \
    "Data/RC/preprocessed/lu_rc_data_plot.dat" using ($1<192?$1:1/0):(abs($2-bijelona_last)) with linespoints lw 2 lc rgb "#9467bd" pt 7 title "RC LuFd", \
    "Data/RC/preprocessed/no_fd_rc_data_plot.dat" using ($1<192?$1:1/0):(abs($2-bijelona_last)) with linespoints lw 2 lc rgb "#8c564b" pt 9 title "RC LuNoFd", \
    "Data/RC/preprocessed/split_rc_data_plot.dat" using ($1<192?$1:1/0):(abs($2-bijelona_last)) with linespoints lw 2 lc rgb "#e377c2" pt 11 title "RC Split", \
    "Data/Disp/preprocessed/lu_disp_data_plot.dat" using ($1<192?$1:1/0):(abs($2-bijelona_last)) with linespoints lw 2 lc rgb "#7f7f7f" pt 7 title "Disp LuFd", \
    "Data/Disp/preprocessed/no_fd_disp_data_plot.dat" using ($1<192?$1:1/0):(abs($2-bijelona_last)) with linespoints lw 2 lc rgb "#bc9f00" pt 9 title "Disp LuNoFd", \
    "Data/Disp/preprocessed/split_disp_data_plot.dat" using ($1<192?$1:1/0):(abs($2-bijelona_last)) with linespoints lw 2 lc rgb "#ff69b4" pt 11 title "Disp Split"

unset output
