# campaignSummary.gp
#
# Usage:
#   gnuplot campaignSummary.gp
#
# Input:
#   campaignSummary.tsv
#
# Output:
#   PDF plots in the current directory

datafile = "campaignSummary.tsv"

set datafile separator whitespace

# PDF output
set terminal pdfcairo enhanced color font "Helvetica,10" size 5.2in,3.5in

# Clean style
set border linewidth 1.2
set grid back lc rgb "#dddddd" lw 0.8
set tics out nomirror
#set key outside right center spacing 1.1
set key left top spacing 1.0 font ",9" opaque
set pointsize 0.8

# Smooth blue-to-red progression for increasing DeltaT
set style line 1 lc rgb "#2166ac" lw 2.2 pt 7  ps 0.7   # blue
set style line 2 lc rgb "#4393c3" lw 2.2 pt 5  ps 0.7
set style line 3 lc rgb "#92c5de" lw 2.2 pt 9  ps 0.7
set style line 4 lc rgb "#f4a582" lw 2.2 pt 13 ps 0.7
set style line 5 lc rgb "#d6604d" lw 2.2 pt 11 ps 0.7
set style line 6 lc rgb "#b2182b" lw 2.2 pt 3  ps 0.7   # red

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
# 1. Uy versus DeltaX, curves for each DeltaT
# ============================================================

set output "Uy_vs_DeltaX.pdf"

set title "Displacement sensitivity to mesh size"
set xlabel "{/Symbol D}x [m]"
set ylabel "U_y [m]"

set logscale x 2
set xrange [0.02:0.12]
set xtics ("0.025" 0.025, "0.05" 0.05, "0.1" 0.1)
set format x "%.3g"
set format y "%.4g"

plot \
    "< awk 'NR==1 || ($8==\"steady\" && $7==0.5)'  campaignSummary.tsv | sort -k6,6g" using 6:14 with linespoints ls 1 title "{/Symbol D}t = 0.5 s", \
    "< awk 'NR==1 || ($8==\"steady\" && $7==1)'    campaignSummary.tsv | sort -k6,6g" using 6:14 with linespoints ls 2 title "{/Symbol D}t = 1 s", \
    "< awk 'NR==1 || ($8==\"steady\" && $7==2.5)'  campaignSummary.tsv | sort -k6,6g" using 6:14 with linespoints ls 3 title "{/Symbol D}t = 2.5 s", \
    "< awk 'NR==1 || ($8==\"steady\" && $7==5)'    campaignSummary.tsv | sort -k6,6g" using 6:14 with linespoints ls 4 title "{/Symbol D}t = 5 s", \
    "< awk 'NR==1 || ($8==\"steady\" && $7==10)'   campaignSummary.tsv | sort -k6,6g" using 6:14 with linespoints ls 5 title "{/Symbol D}t = 10 s", \
    "< awk 'NR==1 || ($8==\"steady\" && $7==20)'   campaignSummary.tsv | sort -k6,6g" using 6:14 with linespoints ls 6 title "{/Symbol D}t = 20 s"


unset logscale x


# ============================================================
# 2. Fy versus DeltaX, curves for each DeltaT
# ============================================================

set output "Fy_vs_DeltaX.pdf"

set title "Force sensitivity to mesh size"
set xlabel "{/Symbol D}x [m]"
set ylabel "F_y [N]"

set logscale x 2
set xrange [0.02:0.12]
set xtics ("0.025" 0.025, "0.05" 0.05, "0.1" 0.1)
set format x "%.3g"
set format y "%.4g"

plot \
    "< awk 'NR==1 || ($8==\"steady\" && $7==0.5)'  campaignSummary.tsv | sort -k6,6g" using 6:15 with linespoints ls 1 title "{/Symbol D}t = 0.5 s", \
    "< awk 'NR==1 || ($8==\"steady\" && $7==1)'    campaignSummary.tsv | sort -k6,6g" using 6:15 with linespoints ls 2 title "{/Symbol D}t = 1 s", \
    "< awk 'NR==1 || ($8==\"steady\" && $7==2.5)'  campaignSummary.tsv | sort -k6,6g" using 6:15 with linespoints ls 3 title "{/Symbol D}t = 2.5 s", \
    "< awk 'NR==1 || ($8==\"steady\" && $7==5)'    campaignSummary.tsv | sort -k6,6g" using 6:15 with linespoints ls 4 title "{/Symbol D}t = 5 s", \
    "< awk 'NR==1 || ($8==\"steady\" && $7==10)'   campaignSummary.tsv | sort -k6,6g" using 6:15 with linespoints ls 5 title "{/Symbol D}t = 10 s", \
    "< awk 'NR==1 || ($8==\"steady\" && $7==20)'   campaignSummary.tsv | sort -k6,6g" using 6:15 with linespoints ls 6 title "{/Symbol D}t = 20 s"

unset logscale x


# ============================================================
# 3. Uy versus DeltaT, curves for each mesh
# ============================================================

set output "Uy_vs_DeltaT.pdf"

set title "Displacement sensitivity to time step"
set xlabel "{/Symbol D}t [s]"
set ylabel "U_y [m]"

set logscale x 2
set xrange [0.4:25]
set xtics ("0.5" 0.5, "1" 1, "2.5" 2.5, "5" 5, "10" 10, "20" 20)
set format x "%.3g"
set format y "%.4g"

plot \
    datafile using (strcol(8) eq steady && $5 == 1 ? $7 : 1/0):($14) with linespoints ls 1 title "{/Symbol D}x = 0.1 m", \
    datafile using (strcol(8) eq steady && $5 == 2 ? $7 : 1/0):($14) with linespoints ls 2 title "{/Symbol D}x = 0.05 m", \
    datafile using (strcol(8) eq steady && $5 == 3 ? $7 : 1/0):($14) with linespoints ls 3 title "{/Symbol D}x = 0.025 m"

unset logscale x


# ============================================================
# 4. Fy versus DeltaT, curves for each mesh
# ============================================================

set output "Fy_vs_DeltaT.pdf"

set title "Force sensitivity to time step"
set xlabel "{/Symbol D}t [s]"
set ylabel "F_y [N]"

set logscale x 2
set xrange [0.4:25]
set xtics ("0.5" 0.5, "1" 1, "2.5" 2.5, "5" 5, "10" 10, "20" 20)
set format x "%.3g"
set format y "%.4g"

plot \
    datafile using (strcol(8) eq steady && $5 == 1 ? $7 : 1/0):($15) with linespoints ls 1 title "{/Symbol D}x = 0.1 m", \
    datafile using (strcol(8) eq steady && $5 == 2 ? $7 : 1/0):($15) with linespoints ls 2 title "{/Symbol D}x = 0.05 m", \
    datafile using (strcol(8) eq steady && $5 == 3 ? $7 : 1/0):($15) with linespoints ls 3 title "{/Symbol D}x = 0.025 m"

unset logscale x


# ============================================================
# 5. Wall time versus DeltaT
# Includes hitEndTime cases because they are useful for performance.
# ============================================================

set output "WallTime_vs_DeltaT.pdf"

set title "Wall-time sensitivity to time step"
set xlabel "{/Symbol D}t [s]"
set ylabel "Wall time [s]"

set logscale x 2
set logscale y 10
set xrange [0.4:45]
set xtics ("0.5" 0.5, "1" 1, "2.5" 2.5, "5" 5, "10" 10, "20" 20, "40" 40)
set format x "%.3g"
set format y "10^{%T}"

plot \
    datafile using ($5 == 1 ? $7 : 1/0):($11) with linespoints ls 1 title "{/Symbol D}x = 0.1 m", \
    datafile using ($5 == 2 ? $7 : 1/0):($11) with linespoints ls 2 title "{/Symbol D}x = 0.05 m", \
    datafile using ($5 == 3 ? $7 : 1/0):($11) with linespoints ls 3 title "{/Symbol D}x = 0.025 m"

unset logscale x
unset logscale y


# ============================================================
# 6. Steady-state time versus DeltaT
# Includes hitEndTime cases, where SteadyTime is effectively EndTime.
# ============================================================

set output "SteadyTime_vs_DeltaT.pdf"

set title "Pseudo-time required to reach steady state"
set xlabel "{/Symbol D}t [s]"
set ylabel "Steady-state time [s]"

set logscale x 2
set logscale y 10
set xrange [0.4:45]
set xtics ("0.5" 0.5, "1" 1, "2.5" 2.5, "5" 5, "10" 10, "20" 20, "40" 40)
set format x "%.3g"
set format y "10^{%T}"

plot \
    datafile using ($5 == 1 ? $7 : 1/0):($13) with linespoints ls 1 title "{/Symbol D}x = 0.1 m", \
    datafile using ($5 == 2 ? $7 : 1/0):($13) with linespoints ls 2 title "{/Symbol D}x = 0.05 m", \
    datafile using ($5 == 3 ? $7 : 1/0):($13) with linespoints ls 3 title "{/Symbol D}x = 0.025 m"

unset logscale x
unset logscale y


# ============================================================
# 7. Maximum memory versus total cell count
# ============================================================

set output "Memory_vs_Cells.pdf"

set title "Memory usage versus problem size"
set xlabel "Total cells"
set ylabel "Maximum memory [MB]"

unset logscale x
set xrange [0:4.0e4]
set xtics ("0" 0, "10k" 1e4, "20k" 2e4, "30k" 3e4, "40k" 4e4)
set format y "%.4g"
set grid

plot \
    datafile using ($9 + $10):($12) with points ls 1 notitle

unset logscale x


# ============================================================
# 8. Wall time versus total cell count
# ============================================================

set output "WallTime_vs_Cells.pdf"

set title "Wall time versus problem size"
set xlabel "Total cells"
set ylabel "Wall time [s]"

set logscale x 10
set logscale y 10
set xrange [1e3:4e4]
set format x "10^{%T}"
set format y "10^{%T}"

plot \
    "< awk 'NR==1 || $7==0.5  {print $9+$10, $11}' campaignSummary.tsv | sort -k1,1g" using 1:2 with linespoints ls 1 title "{/Symbol D}t = 0.5 s", \
    "< awk 'NR==1 || $7==1.0  {print $9+$10, $11}' campaignSummary.tsv | sort -k1,1g" using 1:2 with linespoints ls 2 title "{/Symbol D}t = 1 s", \
    "< awk 'NR==1 || $7==2.5  {print $9+$10, $11}' campaignSummary.tsv | sort -k1,1g" using 1:2 with linespoints ls 3 title "{/Symbol D}t = 2.5 s", \
    "< awk 'NR==1 || $7==5.0  {print $9+$10, $11}' campaignSummary.tsv | sort -k1,1g" using 1:2 with linespoints ls 4 title "{/Symbol D}t = 5 s", \
    "< awk 'NR==1 || $7==10.0 {print $9+$10, $11}' campaignSummary.tsv | sort -k1,1g" using 1:2 with linespoints ls 5 title "{/Symbol D}t = 10 s", \
    "< awk 'NR==1 || $7==20.0 {print $9+$10, $11}' campaignSummary.tsv | sort -k1,1g" using 1:2 with linespoints ls 6 title "{/Symbol D}t = 20 s"
    
unset logscale x
unset logscale y


# ============================================================
# 9. Relative displacement change versus DeltaT
# ============================================================

set output "DisplacementRelChange_vs_DeltaT.pdf"

set title "Steady-state displacement convergence"
set xlabel "{/Symbol D}t [s]"
set ylabel "Relative change in displacement"

set logscale x 2
set logscale y 10
set xrange [0.4:45]
set xtics ("0.5" 0.5, "1" 1, "2.5" 2.5, "5" 5, "10" 10, "20" 20, "40" 40)
set format x "%.3g"
set format y "10^{%T}"

plot \
    datafile using ($5 == 1 ? $7 : 1/0):($16) with linespoints ls 1 title "{/Symbol D}x = 0.1 m", \
    datafile using ($5 == 2 ? $7 : 1/0):($16) with linespoints ls 2 title "{/Symbol D}x = 0.05 m", \
    datafile using ($5 == 3 ? $7 : 1/0):($16) with linespoints ls 3 title "{/Symbol D}x = 0.025 m"

unset logscale x
unset logscale y


# ============================================================
# 10. Relative force change versus DeltaT
# ============================================================

set output "ForceRelChange_vs_DeltaT.pdf"

set title "Steady-state force convergence"
set xlabel "{/Symbol D}t [s]"
set ylabel "Relative change in force"

set logscale x 2
set logscale y 10
set xrange [0.4:45]
set xtics ("0.5" 0.5, "1" 1, "2.5" 2.5, "5" 5, "10" 10, "20" 20, "40" 40)
set format x "%.3g"
set format y "10^{%T}"

plot \
    datafile using ($5 == 1 ? $7 : 1/0):($17) with linespoints ls 1 title "{/Symbol D}x = 0.1 m", \
    datafile using ($5 == 2 ? $7 : 1/0):($17) with linespoints ls 2 title "{/Symbol D}x = 0.05 m", \
    datafile using ($5 == 3 ? $7 : 1/0):($17) with linespoints ls 3 title "{/Symbol D}x = 0.025 m"

unset logscale x
unset logscale y


# Reset output
set output