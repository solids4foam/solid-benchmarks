# campaignSummary.gp
#
# Usage:
#   gnuplot campaignSummary.gnuplot
#
# Input:
#   campaignSummary.tsv
#
# Output:
#   PDF plots in the current directory, one set per (Method, Variant)
#   combination found in the input file. New simulation types are picked up
#   automatically.

datafile = "campaignSummary.tsv"

set datafile separator whitespace

# PDF output
set terminal pdfcairo enhanced color font "Helvetica,10" size 5.2in,3.5in

# Clean style
set border linewidth 1.2
set grid back lc rgb "#dddddd" lw 0.8
set tics out nomirror
set key left top spacing 1.0 font ",9" opaque
set pointsize 0.8

# Smooth blue-to-red progression for increasing DeltaT (7 levels: 0.5..40)
set style line 1 lc rgb "#2166ac" lw 2.2 pt 7  ps 0.7   # blue
set style line 2 lc rgb "#4393c3" lw 2.2 pt 5  ps 0.7
set style line 3 lc rgb "#92c5de" lw 2.2 pt 9  ps 0.7
set style line 4 lc rgb "#cccccc" lw 2.2 pt 2  ps 0.7
set style line 5 lc rgb "#f4a582" lw 2.2 pt 13 ps 0.7
set style line 6 lc rgb "#d6604d" lw 2.2 pt 11 ps 0.7
set style line 7 lc rgb "#b2182b" lw 2.2 pt 3  ps 0.7   # red

# Mesh styles (4 meshes: m1..m4)
set style line 11 lc rgb "#2166ac" lw 2.2 pt 7  ps 0.7   # blue   (m1, coarsest)
set style line 12 lc rgb "#92c5de" lw 2.2 pt 5  ps 0.7   #         (m2)
set style line 13 lc rgb "#f4a582" lw 2.2 pt 9  ps 0.7   #         (m3)
set style line 14 lc rgb "#b2182b" lw 2.2 pt 13 ps 0.7   # red    (m4, finest)

# Column numbers in campaignSummary.tsv
#  1 Study
#  2 Method
#  3 Variant
#  4 Case
#  5 Mesh
#  6 DeltaX
#  7 DeltaT
#  8 Status
#  9 CellsFluid
# 10 CellsSolid
# 11 WallTime
# 12 MaxMemoryMb
# 13 SteadyTime
# 14 Uy
# 15 Fy
# 16 DisplacementRelChange
# 17 ForceRelChange
# 18 Consecutive

steady = "steady"

# Generic tick formatting
set format x "%.3g"
set format y "%.4g"

# ============================================================
# Discover all (Method, Variant) combinations present in the data.
# Each entry is encoded as "Method|Variant" so we can split safely
# even if either field contains an underscore.
# ============================================================

combos = system("awk 'NR>1 && NF>=3 {print $2\"|\"$3}' " . datafile . " | sort -u")

# ============================================================
# Loop over each (Method, Variant) and emit the full set of plots.
# ============================================================

do for [combo in combos] {

    method  = system(sprintf("echo '%s' | awk -F'|' '{print $1}'", combo))
    variant = system(sprintf("echo '%s' | awk -F'|' '{print $2}'", combo))
    tag     = method . "_" . variant
    title_suffix = sprintf(" (%s, %s)", method, variant)

    # Awk filter clause for the current method/variant in shell-piped commands.
    # Single-quoted inside awk, so embed the variables via sprintf.
    mv_filter = sprintf("$2==\"%s\" && $3==\"%s\"", method, variant)


    # --------------------------------------------------------
    # 1. Uy versus DeltaX, curves for each DeltaT
    # --------------------------------------------------------

    set output "Uy_vs_DeltaX_" . tag . ".pdf"

    set title "Displacement sensitivity to mesh size" . title_suffix
    set xlabel "{/Symbol D}x [m]"
    set ylabel "U_y [m]"

    set logscale x 2
    set xrange [0.01:0.12]
    set xtics ("0.0125" 0.0125, "0.025" 0.025, "0.05" 0.05, "0.1" 0.1)
    set format x "%.3g"
    set format y "%.4g"

    plot \
        sprintf("< awk 'NR==1 || (%s && $8==\"steady\" && $7==0.5)' %s | sort -k6,6g", mv_filter, datafile) using 6:14 with linespoints ls 1 title "{/Symbol D}t = 0.5 s", \
        sprintf("< awk 'NR==1 || (%s && $8==\"steady\" && $7==1)'   %s | sort -k6,6g", mv_filter, datafile) using 6:14 with linespoints ls 2 title "{/Symbol D}t = 1 s", \
        sprintf("< awk 'NR==1 || (%s && $8==\"steady\" && $7==2.5)' %s | sort -k6,6g", mv_filter, datafile) using 6:14 with linespoints ls 3 title "{/Symbol D}t = 2.5 s", \
        sprintf("< awk 'NR==1 || (%s && $8==\"steady\" && $7==5)'   %s | sort -k6,6g", mv_filter, datafile) using 6:14 with linespoints ls 4 title "{/Symbol D}t = 5 s", \
        sprintf("< awk 'NR==1 || (%s && $8==\"steady\" && $7==10)'  %s | sort -k6,6g", mv_filter, datafile) using 6:14 with linespoints ls 5 title "{/Symbol D}t = 10 s", \
        sprintf("< awk 'NR==1 || (%s && $8==\"steady\" && $7==20)'  %s | sort -k6,6g", mv_filter, datafile) using 6:14 with linespoints ls 6 title "{/Symbol D}t = 20 s", \
        sprintf("< awk 'NR==1 || (%s && $8==\"steady\" && $7==40)'  %s | sort -k6,6g", mv_filter, datafile) using 6:14 with linespoints ls 7 title "{/Symbol D}t = 40 s"

    unset logscale x


    # --------------------------------------------------------
    # 2. Fy versus DeltaX, curves for each DeltaT
    # --------------------------------------------------------

    set output "Fy_vs_DeltaX_" . tag . ".pdf"

    set title "Force sensitivity to mesh size" . title_suffix
    set xlabel "{/Symbol D}x [m]"
    set ylabel "F_y [N]"

    set logscale x 2
    set xrange [0.01:0.12]
    set xtics ("0.0125" 0.0125, "0.025" 0.025, "0.05" 0.05, "0.1" 0.1)
    set format x "%.3g"
    set format y "%.4g"

    plot \
        sprintf("< awk 'NR==1 || (%s && $8==\"steady\" && $7==0.5)' %s | sort -k6,6g", mv_filter, datafile) using 6:15 with linespoints ls 1 title "{/Symbol D}t = 0.5 s", \
        sprintf("< awk 'NR==1 || (%s && $8==\"steady\" && $7==1)'   %s | sort -k6,6g", mv_filter, datafile) using 6:15 with linespoints ls 2 title "{/Symbol D}t = 1 s", \
        sprintf("< awk 'NR==1 || (%s && $8==\"steady\" && $7==2.5)' %s | sort -k6,6g", mv_filter, datafile) using 6:15 with linespoints ls 3 title "{/Symbol D}t = 2.5 s", \
        sprintf("< awk 'NR==1 || (%s && $8==\"steady\" && $7==5)'   %s | sort -k6,6g", mv_filter, datafile) using 6:15 with linespoints ls 4 title "{/Symbol D}t = 5 s", \
        sprintf("< awk 'NR==1 || (%s && $8==\"steady\" && $7==10)'  %s | sort -k6,6g", mv_filter, datafile) using 6:15 with linespoints ls 5 title "{/Symbol D}t = 10 s", \
        sprintf("< awk 'NR==1 || (%s && $8==\"steady\" && $7==20)'  %s | sort -k6,6g", mv_filter, datafile) using 6:15 with linespoints ls 6 title "{/Symbol D}t = 20 s", \
        sprintf("< awk 'NR==1 || (%s && $8==\"steady\" && $7==40)'  %s | sort -k6,6g", mv_filter, datafile) using 6:15 with linespoints ls 7 title "{/Symbol D}t = 40 s"

    unset logscale x


    # --------------------------------------------------------
    # 3. Uy versus DeltaT, curves for each mesh
    # --------------------------------------------------------

    set output "Uy_vs_DeltaT_" . tag . ".pdf"

    set title "Displacement sensitivity to time step" . title_suffix
    set xlabel "{/Symbol D}t [s]"
    set ylabel "U_y [m]"

    set logscale x 2
    set xrange [0.4:45]
    set xtics ("0.5" 0.5, "1" 1, "2.5" 2.5, "5" 5, "10" 10, "20" 20, "40" 40)
    set format x "%.3g"
    set format y "%.4g"

    plot \
        datafile using (strcol(2) eq method && strcol(3) eq variant && strcol(8) eq steady && $5 == 1 ? $7 : 1/0):($14) with linespoints ls 11 title "{/Symbol D}x = 0.1 m", \
        datafile using (strcol(2) eq method && strcol(3) eq variant && strcol(8) eq steady && $5 == 2 ? $7 : 1/0):($14) with linespoints ls 12 title "{/Symbol D}x = 0.05 m", \
        datafile using (strcol(2) eq method && strcol(3) eq variant && strcol(8) eq steady && $5 == 3 ? $7 : 1/0):($14) with linespoints ls 13 title "{/Symbol D}x = 0.025 m", \
        datafile using (strcol(2) eq method && strcol(3) eq variant && strcol(8) eq steady && $5 == 4 ? $7 : 1/0):($14) with linespoints ls 14 title "{/Symbol D}x = 0.0125 m"

    unset logscale x


    # --------------------------------------------------------
    # 4. Fy versus DeltaT, curves for each mesh
    # --------------------------------------------------------

    set output "Fy_vs_DeltaT_" . tag . ".pdf"

    set title "Force sensitivity to time step" . title_suffix
    set xlabel "{/Symbol D}t [s]"
    set ylabel "F_y [N]"

    set logscale x 2
    set xrange [0.4:45]
    set xtics ("0.5" 0.5, "1" 1, "2.5" 2.5, "5" 5, "10" 10, "20" 20, "40" 40)
    set format x "%.3g"
    set format y "%.4g"

    plot \
        datafile using (strcol(2) eq method && strcol(3) eq variant && strcol(8) eq steady && $5 == 1 ? $7 : 1/0):($15) with linespoints ls 11 title "{/Symbol D}x = 0.1 m", \
        datafile using (strcol(2) eq method && strcol(3) eq variant && strcol(8) eq steady && $5 == 2 ? $7 : 1/0):($15) with linespoints ls 12 title "{/Symbol D}x = 0.05 m", \
        datafile using (strcol(2) eq method && strcol(3) eq variant && strcol(8) eq steady && $5 == 3 ? $7 : 1/0):($15) with linespoints ls 13 title "{/Symbol D}x = 0.025 m", \
        datafile using (strcol(2) eq method && strcol(3) eq variant && strcol(8) eq steady && $5 == 4 ? $7 : 1/0):($15) with linespoints ls 14 title "{/Symbol D}x = 0.0125 m"

    unset logscale x


    # --------------------------------------------------------
    # 5. Wall time versus DeltaT
    # Includes hitEndTime cases because they are useful for performance.
    # --------------------------------------------------------

    set output "WallTime_vs_DeltaT_" . tag . ".pdf"

    set title "Wall-time sensitivity to time step" . title_suffix
    set xlabel "{/Symbol D}t [s]"
    set ylabel "Wall time [s]"

    set logscale x 2
    set logscale y 10
    set xrange [0.4:45]
    set xtics ("0.5" 0.5, "1" 1, "2.5" 2.5, "5" 5, "10" 10, "20" 20, "40" 40)
    set format x "%.3g"
    set format y "10^{%T}"

    plot \
        datafile using (strcol(2) eq method && strcol(3) eq variant && $5 == 1 ? $7 : 1/0):($11) with linespoints ls 11 title "{/Symbol D}x = 0.1 m", \
        datafile using (strcol(2) eq method && strcol(3) eq variant && $5 == 2 ? $7 : 1/0):($11) with linespoints ls 12 title "{/Symbol D}x = 0.05 m", \
        datafile using (strcol(2) eq method && strcol(3) eq variant && $5 == 3 ? $7 : 1/0):($11) with linespoints ls 13 title "{/Symbol D}x = 0.025 m", \
        datafile using (strcol(2) eq method && strcol(3) eq variant && $5 == 4 ? $7 : 1/0):($11) with linespoints ls 14 title "{/Symbol D}x = 0.0125 m"

    unset logscale x
    unset logscale y


    # --------------------------------------------------------
    # 6. Steady-state time versus DeltaT
    # Includes hitEndTime cases, where SteadyTime is effectively EndTime.
    # --------------------------------------------------------

    set output "SteadyTime_vs_DeltaT_" . tag . ".pdf"

    set title "Pseudo-time required to reach steady state" . title_suffix
    set xlabel "{/Symbol D}t [s]"
    set ylabel "Steady-state time [s]"

    set logscale x 2
    set logscale y 10
    set xrange [0.4:45]
    set xtics ("0.5" 0.5, "1" 1, "2.5" 2.5, "5" 5, "10" 10, "20" 20, "40" 40)
    set format x "%.3g"
    set format y "10^{%T}"

    plot \
        datafile using (strcol(2) eq method && strcol(3) eq variant && $5 == 1 ? $7 : 1/0):($13) with linespoints ls 11 title "{/Symbol D}x = 0.1 m", \
        datafile using (strcol(2) eq method && strcol(3) eq variant && $5 == 2 ? $7 : 1/0):($13) with linespoints ls 12 title "{/Symbol D}x = 0.05 m", \
        datafile using (strcol(2) eq method && strcol(3) eq variant && $5 == 3 ? $7 : 1/0):($13) with linespoints ls 13 title "{/Symbol D}x = 0.025 m", \
        datafile using (strcol(2) eq method && strcol(3) eq variant && $5 == 4 ? $7 : 1/0):($13) with linespoints ls 14 title "{/Symbol D}x = 0.0125 m"

    unset logscale x
    unset logscale y


    # --------------------------------------------------------
    # 7. Maximum memory versus total cell count
    # --------------------------------------------------------

    set output "Memory_vs_Cells_" . tag . ".pdf"

    set title "Memory usage versus problem size" . title_suffix
    set xlabel "Total cells"
    set ylabel "Maximum memory [MB]"

    unset logscale x
    set logscale x 10
    set xrange [1e3:2e5]
    set format x "10^{%T}"
    set format y "%.4g"
    set grid

    plot \
        datafile using (strcol(2) eq method && strcol(3) eq variant ? ($9 + $10) : 1/0):($12) with points ls 11 notitle

    unset logscale x


    # --------------------------------------------------------
    # 8. Wall time versus total cell count
    # --------------------------------------------------------

    set output "WallTime_vs_Cells_" . tag . ".pdf"

    set title "Wall time versus problem size" . title_suffix
    set xlabel "Total cells"
    set ylabel "Wall time [s]"

    set logscale x 10
    set logscale y 10
    set xrange [1e3:2e5]
    set format x "10^{%T}"
    set format y "10^{%T}"

    plot \
        sprintf("< awk 'NR==1 || (%s && $7==0.5)  {print $9+$10, $11}' %s | sort -k1,1g", mv_filter, datafile) using 1:2 with linespoints ls 1 title "{/Symbol D}t = 0.5 s", \
        sprintf("< awk 'NR==1 || (%s && $7==1.0)  {print $9+$10, $11}' %s | sort -k1,1g", mv_filter, datafile) using 1:2 with linespoints ls 2 title "{/Symbol D}t = 1 s", \
        sprintf("< awk 'NR==1 || (%s && $7==2.5)  {print $9+$10, $11}' %s | sort -k1,1g", mv_filter, datafile) using 1:2 with linespoints ls 3 title "{/Symbol D}t = 2.5 s", \
        sprintf("< awk 'NR==1 || (%s && $7==5.0)  {print $9+$10, $11}' %s | sort -k1,1g", mv_filter, datafile) using 1:2 with linespoints ls 4 title "{/Symbol D}t = 5 s", \
        sprintf("< awk 'NR==1 || (%s && $7==10.0) {print $9+$10, $11}' %s | sort -k1,1g", mv_filter, datafile) using 1:2 with linespoints ls 5 title "{/Symbol D}t = 10 s", \
        sprintf("< awk 'NR==1 || (%s && $7==20.0) {print $9+$10, $11}' %s | sort -k1,1g", mv_filter, datafile) using 1:2 with linespoints ls 6 title "{/Symbol D}t = 20 s", \
        sprintf("< awk 'NR==1 || (%s && $7==40.0) {print $9+$10, $11}' %s | sort -k1,1g", mv_filter, datafile) using 1:2 with linespoints ls 7 title "{/Symbol D}t = 40 s"

    unset logscale x
    unset logscale y


    # --------------------------------------------------------
    # 9. Relative displacement change versus DeltaT
    # --------------------------------------------------------

    set output "DisplacementRelChange_vs_DeltaT_" . tag . ".pdf"

    set title "Steady-state displacement convergence" . title_suffix
    set xlabel "{/Symbol D}t [s]"
    set ylabel "Relative change in displacement"

    set logscale x 2
    set logscale y 10
    set xrange [0.4:45]
    set xtics ("0.5" 0.5, "1" 1, "2.5" 2.5, "5" 5, "10" 10, "20" 20, "40" 40)
    set format x "%.3g"
    set format y "10^{%T}"

    plot \
        datafile using (strcol(2) eq method && strcol(3) eq variant && strcol(8) eq steady && $5 == 1 ? $7 : 1/0):($16) with linespoints ls 11 title "{/Symbol D}x = 0.1 m", \
        datafile using (strcol(2) eq method && strcol(3) eq variant && strcol(8) eq steady && $5 == 2 ? $7 : 1/0):($16) with linespoints ls 12 title "{/Symbol D}x = 0.05 m", \
        datafile using (strcol(2) eq method && strcol(3) eq variant && strcol(8) eq steady && $5 == 3 ? $7 : 1/0):($16) with linespoints ls 13 title "{/Symbol D}x = 0.025 m", \
        datafile using (strcol(2) eq method && strcol(3) eq variant && strcol(8) eq steady && $5 == 4 ? $7 : 1/0):($16) with linespoints ls 14 title "{/Symbol D}x = 0.0125 m"

    unset logscale x
    unset logscale y


    # --------------------------------------------------------
    # 10. Relative force change versus DeltaT
    # --------------------------------------------------------

    set output "ForceRelChange_vs_DeltaT_" . tag . ".pdf"

    set title "Steady-state force convergence" . title_suffix
    set xlabel "{/Symbol D}t [s]"
    set ylabel "Relative change in force"

    set logscale x 2
    set logscale y 10
    set xrange [0.4:45]
    set xtics ("0.5" 0.5, "1" 1, "2.5" 2.5, "5" 5, "10" 10, "20" 20, "40" 40)
    set format x "%.3g"
    set format y "10^{%T}"

    plot \
        datafile using (strcol(2) eq method && strcol(3) eq variant && strcol(8) eq steady && $5 == 1 ? $7 : 1/0):($17) with linespoints ls 11 title "{/Symbol D}x = 0.1 m", \
        datafile using (strcol(2) eq method && strcol(3) eq variant && strcol(8) eq steady && $5 == 2 ? $7 : 1/0):($17) with linespoints ls 12 title "{/Symbol D}x = 0.05 m", \
        datafile using (strcol(2) eq method && strcol(3) eq variant && strcol(8) eq steady && $5 == 3 ? $7 : 1/0):($17) with linespoints ls 13 title "{/Symbol D}x = 0.025 m", \
        datafile using (strcol(2) eq method && strcol(3) eq variant && strcol(8) eq steady && $5 == 4 ? $7 : 1/0):($17) with linespoints ls 14 title "{/Symbol D}x = 0.0125 m"

    unset logscale x
    unset logscale y

}


# ============================================================
# Cross-scheme comparison plots
#
# Overlays all (Method, Variant) combinations on one figure.
# Colour family encodes the scheme; shade encodes mesh size
# (m1 = coarsest = darkest; m4 = finest = lightest).
#
# Currently hard-codes the three known combinations:
#   monolithic / default   -> blues
#   partitioned / IQNILS   -> reds
#   partitioned / Aitken   -> greens
# Add more blocks below if new schemes appear.
# ============================================================

# Monolithic / default : blues (m1 darkest -> m4 lightest)
set style line 21 lc rgb "#08306b" lw 2.2 pt 7  ps 0.7   # m1
set style line 22 lc rgb "#2171b5" lw 2.2 pt 5  ps 0.7   # m2
set style line 23 lc rgb "#6baed6" lw 2.2 pt 9  ps 0.7   # m3
set style line 24 lc rgb "#c6dbef" lw 2.2 pt 13 ps 0.7   # m4

# Partitioned / IQNILS : reds
set style line 31 lc rgb "#67000d" lw 2.2 pt 7  ps 0.7   # m1
set style line 32 lc rgb "#cb181d" lw 2.2 pt 5  ps 0.7   # m2
set style line 33 lc rgb "#fb6a4a" lw 2.2 pt 9  ps 0.7   # m3
set style line 34 lc rgb "#fcae91" lw 2.2 pt 13 ps 0.7   # m4

# Partitioned / Aitken : greens
set style line 41 lc rgb "#00441b" lw 2.2 pt 7  ps 0.7   # m1
set style line 42 lc rgb "#238b45" lw 2.2 pt 5  ps 0.7   # m2
set style line 43 lc rgb "#74c476" lw 2.2 pt 9  ps 0.7   # m3
set style line 44 lc rgb "#c7e9c0" lw 2.2 pt 13 ps 0.7   # m4

# Filter expressions are written inline below — gnuplot user-defined
# functions cannot return strings to substitute into `using` clauses.


# --------------------------------------------------------
# C1. Uy versus DeltaT, all schemes and all meshes
# --------------------------------------------------------

set output "Uy_vs_DeltaT_allSchemes.pdf"

set title "Displacement sensitivity to time step (all schemes)"
set xlabel "{/Symbol D}t [s]"
set ylabel "U_y [m]"

set logscale x 2
unset logscale y
set xrange [0.4:45]
set xtics ("0.5" 0.5, "1" 1, "2.5" 2.5, "5" 5, "10" 10, "20" 20, "40" 40)
set format x "%.3g"
set format y "%.4g"
set key outside right top spacing 1.0 font ",8" opaque

plot \
    datafile using ((strcol(2) eq "monolithic"  && strcol(3) eq "default" && $5==1 && strcol(8) eq "steady")   ? $7 : 1/0):14 with linespoints ls 21 title "mono m1", \
    datafile using ((strcol(2) eq "monolithic"  && strcol(3) eq "default" && $5==2 && strcol(8) eq "steady")   ? $7 : 1/0):14 with linespoints ls 22 title "mono m2", \
    datafile using ((strcol(2) eq "monolithic"  && strcol(3) eq "default" && $5==3 && strcol(8) eq "steady")   ? $7 : 1/0):14 with linespoints ls 23 title "mono m3", \
    datafile using ((strcol(2) eq "monolithic"  && strcol(3) eq "default" && $5==4 && strcol(8) eq "steady")   ? $7 : 1/0):14 with linespoints ls 24 title "mono m4", \
    datafile using ((strcol(2) eq "partitioned" && strcol(3) eq "IQNILS"  && $5==1 && strcol(8) eq "steady") ? $7 : 1/0):14 with linespoints ls 31 title "IQNILS m1", \
    datafile using ((strcol(2) eq "partitioned" && strcol(3) eq "IQNILS"  && $5==2 && strcol(8) eq "steady") ? $7 : 1/0):14 with linespoints ls 32 title "IQNILS m2", \
    datafile using ((strcol(2) eq "partitioned" && strcol(3) eq "IQNILS"  && $5==3 && strcol(8) eq "steady") ? $7 : 1/0):14 with linespoints ls 33 title "IQNILS m3", \
    datafile using ((strcol(2) eq "partitioned" && strcol(3) eq "IQNILS"  && $5==4 && strcol(8) eq "steady") ? $7 : 1/0):14 with linespoints ls 34 title "IQNILS m4", \
    datafile using ((strcol(2) eq "partitioned" && strcol(3) eq "Aitken"  && $5==1 && strcol(8) eq "steady") ? $7 : 1/0):14 with linespoints ls 41 title "Aitken m1", \
    datafile using ((strcol(2) eq "partitioned" && strcol(3) eq "Aitken"  && $5==2 && strcol(8) eq "steady") ? $7 : 1/0):14 with linespoints ls 42 title "Aitken m2", \
    datafile using ((strcol(2) eq "partitioned" && strcol(3) eq "Aitken"  && $5==3 && strcol(8) eq "steady") ? $7 : 1/0):14 with linespoints ls 43 title "Aitken m3", \
    datafile using ((strcol(2) eq "partitioned" && strcol(3) eq "Aitken"  && $5==4 && strcol(8) eq "steady") ? $7 : 1/0):14 with linespoints ls 44 title "Aitken m4"

unset logscale x


# --------------------------------------------------------
# C2. Fy versus DeltaT, all schemes and all meshes
# --------------------------------------------------------

set output "Fy_vs_DeltaT_allSchemes.pdf"

set title "Force sensitivity to time step (all schemes)"
set xlabel "{/Symbol D}t [s]"
set ylabel "F_y [N]"

set logscale x 2
set xrange [0.4:45]
set xtics ("0.5" 0.5, "1" 1, "2.5" 2.5, "5" 5, "10" 10, "20" 20, "40" 40)
set format x "%.3g"
set format y "%.4g"

plot \
    datafile using ((strcol(2) eq "monolithic"  && strcol(3) eq "default" && $5==1 && strcol(8) eq "steady")   ? $7 : 1/0):15 with linespoints ls 21 title "mono m1", \
    datafile using ((strcol(2) eq "monolithic"  && strcol(3) eq "default" && $5==2 && strcol(8) eq "steady")   ? $7 : 1/0):15 with linespoints ls 22 title "mono m2", \
    datafile using ((strcol(2) eq "monolithic"  && strcol(3) eq "default" && $5==3 && strcol(8) eq "steady")   ? $7 : 1/0):15 with linespoints ls 23 title "mono m3", \
    datafile using ((strcol(2) eq "monolithic"  && strcol(3) eq "default" && $5==4 && strcol(8) eq "steady")   ? $7 : 1/0):15 with linespoints ls 24 title "mono m4", \
    datafile using ((strcol(2) eq "partitioned" && strcol(3) eq "IQNILS"  && $5==1 && strcol(8) eq "steady") ? $7 : 1/0):15 with linespoints ls 31 title "IQNILS m1", \
    datafile using ((strcol(2) eq "partitioned" && strcol(3) eq "IQNILS"  && $5==2 && strcol(8) eq "steady") ? $7 : 1/0):15 with linespoints ls 32 title "IQNILS m2", \
    datafile using ((strcol(2) eq "partitioned" && strcol(3) eq "IQNILS"  && $5==3 && strcol(8) eq "steady") ? $7 : 1/0):15 with linespoints ls 33 title "IQNILS m3", \
    datafile using ((strcol(2) eq "partitioned" && strcol(3) eq "IQNILS"  && $5==4 && strcol(8) eq "steady") ? $7 : 1/0):15 with linespoints ls 34 title "IQNILS m4", \
    datafile using ((strcol(2) eq "partitioned" && strcol(3) eq "Aitken"  && $5==1 && strcol(8) eq "steady") ? $7 : 1/0):15 with linespoints ls 41 title "Aitken m1", \
    datafile using ((strcol(2) eq "partitioned" && strcol(3) eq "Aitken"  && $5==2 && strcol(8) eq "steady") ? $7 : 1/0):15 with linespoints ls 42 title "Aitken m2", \
    datafile using ((strcol(2) eq "partitioned" && strcol(3) eq "Aitken"  && $5==3 && strcol(8) eq "steady") ? $7 : 1/0):15 with linespoints ls 43 title "Aitken m3", \
    datafile using ((strcol(2) eq "partitioned" && strcol(3) eq "Aitken"  && $5==4 && strcol(8) eq "steady") ? $7 : 1/0):15 with linespoints ls 44 title "Aitken m4"

unset logscale x


# --------------------------------------------------------
# C3. Uy versus DeltaX, all schemes (one curve per scheme per DeltaT)
# To keep it readable, plot only the smallest and largest DeltaT.
# --------------------------------------------------------

set output "Uy_vs_DeltaX_allSchemes.pdf"

set title "Displacement sensitivity to mesh size (all schemes, {/Symbol D}t = 1 s)"
set xlabel "{/Symbol D}x [m]"
set ylabel "U_y [m]"

set logscale x 2
set xrange [0.01:0.12]
set xtics ("0.0125" 0.0125, "0.025" 0.025, "0.05" 0.05, "0.1" 0.1)
set format x "%.3g"
set format y "%.4g"

plot \
    "< awk 'NR==1 || ($2==\"monolithic\"  && $3==\"default\" && $8==\"steady\" && $7==1)' " . datafile . " | sort -k6,6g" using 6:14 with linespoints ls 22 title "monolithic", \
    "< awk 'NR==1 || ($2==\"partitioned\" && $3==\"IQNILS\"  && $8==\"steady\" && $7==1)' " . datafile . " | sort -k6,6g" using 6:14 with linespoints ls 32 title "partitioned IQNILS", \
    "< awk 'NR==1 || ($2==\"partitioned\" && $3==\"Aitken\"  && $8==\"steady\" && $7==1)' " . datafile . " | sort -k6,6g" using 6:14 with linespoints ls 42 title "partitioned Aitken"

unset logscale x


# --------------------------------------------------------
# C4. Fy versus DeltaX, all schemes at DeltaT = 1 s
# --------------------------------------------------------

set output "Fy_vs_DeltaX_allSchemes.pdf"

set title "Force sensitivity to mesh size (all schemes, {/Symbol D}t = 1 s)"
set xlabel "{/Symbol D}x [m]"
set ylabel "F_y [N]"

set logscale x 2
set xrange [0.01:0.12]
set xtics ("0.0125" 0.0125, "0.025" 0.025, "0.05" 0.05, "0.1" 0.1)
set format x "%.3g"
set format y "%.4g"

plot \
    "< awk 'NR==1 || ($2==\"monolithic\"  && $3==\"default\" && $8==\"steady\" && $7==1)' " . datafile . " | sort -k6,6g" using 6:15 with linespoints ls 22 title "monolithic", \
    "< awk 'NR==1 || ($2==\"partitioned\" && $3==\"IQNILS\"  && $8==\"steady\" && $7==1)' " . datafile . " | sort -k6,6g" using 6:15 with linespoints ls 32 title "partitioned IQNILS", \
    "< awk 'NR==1 || ($2==\"partitioned\" && $3==\"Aitken\"  && $8==\"steady\" && $7==1)' " . datafile . " | sort -k6,6g" using 6:15 with linespoints ls 42 title "partitioned Aitken"

unset logscale x


# --------------------------------------------------------
# C5. Wall time versus DeltaT, all schemes and all meshes
# --------------------------------------------------------

set output "WallTime_vs_DeltaT_allSchemes.pdf"

set title "Wall-time sensitivity to time step (all schemes)"
set xlabel "{/Symbol D}t [s]"
set ylabel "Wall time [s]"

set logscale x 2
set logscale y 10
set xrange [0.4:45]
set xtics ("0.5" 0.5, "1" 1, "2.5" 2.5, "5" 5, "10" 10, "20" 20, "40" 40)
set format x "%.3g"
set format y "10^{%T}"

plot \
    datafile using ((strcol(2) eq "monolithic"  && strcol(3) eq "default" && $5==1)   ? $7 : 1/0):11 with linespoints ls 21 title "mono m1", \
    datafile using ((strcol(2) eq "monolithic"  && strcol(3) eq "default" && $5==2)   ? $7 : 1/0):11 with linespoints ls 22 title "mono m2", \
    datafile using ((strcol(2) eq "monolithic"  && strcol(3) eq "default" && $5==3)   ? $7 : 1/0):11 with linespoints ls 23 title "mono m3", \
    datafile using ((strcol(2) eq "monolithic"  && strcol(3) eq "default" && $5==4)   ? $7 : 1/0):11 with linespoints ls 24 title "mono m4", \
    datafile using ((strcol(2) eq "partitioned" && strcol(3) eq "IQNILS"  && $5==1) ? $7 : 1/0):11 with linespoints ls 31 title "IQNILS m1", \
    datafile using ((strcol(2) eq "partitioned" && strcol(3) eq "IQNILS"  && $5==2) ? $7 : 1/0):11 with linespoints ls 32 title "IQNILS m2", \
    datafile using ((strcol(2) eq "partitioned" && strcol(3) eq "IQNILS"  && $5==3) ? $7 : 1/0):11 with linespoints ls 33 title "IQNILS m3", \
    datafile using ((strcol(2) eq "partitioned" && strcol(3) eq "IQNILS"  && $5==4) ? $7 : 1/0):11 with linespoints ls 34 title "IQNILS m4", \
    datafile using ((strcol(2) eq "partitioned" && strcol(3) eq "Aitken"  && $5==1) ? $7 : 1/0):11 with linespoints ls 41 title "Aitken m1", \
    datafile using ((strcol(2) eq "partitioned" && strcol(3) eq "Aitken"  && $5==2) ? $7 : 1/0):11 with linespoints ls 42 title "Aitken m2", \
    datafile using ((strcol(2) eq "partitioned" && strcol(3) eq "Aitken"  && $5==3) ? $7 : 1/0):11 with linespoints ls 43 title "Aitken m3", \
    datafile using ((strcol(2) eq "partitioned" && strcol(3) eq "Aitken"  && $5==4) ? $7 : 1/0):11 with linespoints ls 44 title "Aitken m4"

unset logscale x
unset logscale y


# --------------------------------------------------------
# C6. Steady-state time versus DeltaT, all schemes
# --------------------------------------------------------

set output "SteadyTime_vs_DeltaT_allSchemes.pdf"

set title "Pseudo-time required to reach steady state (all schemes)"
set xlabel "{/Symbol D}t [s]"
set ylabel "Steady-state time [s]"

set logscale x 2
set logscale y 10
set xrange [0.4:45]
set xtics ("0.5" 0.5, "1" 1, "2.5" 2.5, "5" 5, "10" 10, "20" 20, "40" 40)
set format x "%.3g"
set format y "10^{%T}"

plot \
    datafile using ((strcol(2) eq "monolithic"  && strcol(3) eq "default" && $5==1 && strcol(8) eq "steady")   ? $7 : 1/0):13 with linespoints ls 21 title "mono m1", \
    datafile using ((strcol(2) eq "monolithic"  && strcol(3) eq "default" && $5==2 && strcol(8) eq "steady")   ? $7 : 1/0):13 with linespoints ls 22 title "mono m2", \
    datafile using ((strcol(2) eq "monolithic"  && strcol(3) eq "default" && $5==3 && strcol(8) eq "steady")   ? $7 : 1/0):13 with linespoints ls 23 title "mono m3", \
    datafile using ((strcol(2) eq "monolithic"  && strcol(3) eq "default" && $5==4 && strcol(8) eq "steady")   ? $7 : 1/0):13 with linespoints ls 24 title "mono m4", \
    datafile using ((strcol(2) eq "partitioned" && strcol(3) eq "IQNILS"  && $5==1 && strcol(8) eq "steady") ? $7 : 1/0):13 with linespoints ls 31 title "IQNILS m1", \
    datafile using ((strcol(2) eq "partitioned" && strcol(3) eq "IQNILS"  && $5==2 && strcol(8) eq "steady") ? $7 : 1/0):13 with linespoints ls 32 title "IQNILS m2", \
    datafile using ((strcol(2) eq "partitioned" && strcol(3) eq "IQNILS"  && $5==3 && strcol(8) eq "steady") ? $7 : 1/0):13 with linespoints ls 33 title "IQNILS m3", \
    datafile using ((strcol(2) eq "partitioned" && strcol(3) eq "IQNILS"  && $5==4 && strcol(8) eq "steady") ? $7 : 1/0):13 with linespoints ls 34 title "IQNILS m4", \
    datafile using ((strcol(2) eq "partitioned" && strcol(3) eq "Aitken"  && $5==1 && strcol(8) eq "steady") ? $7 : 1/0):13 with linespoints ls 41 title "Aitken m1", \
    datafile using ((strcol(2) eq "partitioned" && strcol(3) eq "Aitken"  && $5==2 && strcol(8) eq "steady") ? $7 : 1/0):13 with linespoints ls 42 title "Aitken m2", \
    datafile using ((strcol(2) eq "partitioned" && strcol(3) eq "Aitken"  && $5==3 && strcol(8) eq "steady") ? $7 : 1/0):13 with linespoints ls 43 title "Aitken m3", \
    datafile using ((strcol(2) eq "partitioned" && strcol(3) eq "Aitken"  && $5==4 && strcol(8) eq "steady") ? $7 : 1/0):13 with linespoints ls 44 title "Aitken m4"

unset logscale x
unset logscale y


# --------------------------------------------------------
# C7. Wall time versus total cell count, all schemes at DeltaT = 1 s
# --------------------------------------------------------

set output "WallTime_vs_Cells_allSchemes.pdf"

set title "Wall time versus problem size (all schemes, {/Symbol D}t = 1 s)"
set xlabel "Total cells"
set ylabel "Wall time [s]"

set logscale x 10
set logscale y 10
set xrange [1e3:2e5]
set format x "10^{%T}"
set format y "10^{%T}"

plot \
    "< awk 'NR==1 || ($2==\"monolithic\"  && $3==\"default\" && $7==1) {print $9+$10, $11}' " . datafile . " | sort -k1,1g" using 1:2 with linespoints ls 22 title "monolithic", \
    "< awk 'NR==1 || ($2==\"partitioned\" && $3==\"IQNILS\"  && $7==1) {print $9+$10, $11}' " . datafile . " | sort -k1,1g" using 1:2 with linespoints ls 32 title "partitioned IQNILS", \
    "< awk 'NR==1 || ($2==\"partitioned\" && $3==\"Aitken\"  && $7==1) {print $9+$10, $11}' " . datafile . " | sort -k1,1g" using 1:2 with linespoints ls 42 title "partitioned Aitken"

unset logscale x
unset logscale y


# Restore default key position for subsequent runs/users.
set key left top spacing 1.0 font ",9" opaque

# Reset output
set output
