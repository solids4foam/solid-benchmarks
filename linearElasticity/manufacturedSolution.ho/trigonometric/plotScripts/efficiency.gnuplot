set term pdfcairo dashed enhanced size 3.25, 2
set datafile separator " "

volume = 0.2**3

set grid
set xrange [0:1000]
#set yrange [1e-9:0.2]
set xtics
#set xtics add (5, 25, 50)
set ytics
set logscale x
set logscale y
set format y "10^{%L}"
#set ytics 0.002
set xlabel "Time (in s)"
set ylabel "{/Times-Italic L}_{ 2} error (in μm)"
set key right bottom outside;
set rmargin 15
set key spacing 1.2

# Polynomial guide lines (no title)
set style line 1 lc rgb "red"    lt 2 lw 2 dt 2
set style line 2 lc rgb "blue"   lt 2 lw 2 dt 2
set style line 3 lc rgb "violet" lt 2 lw 2 dt 2

# Data lines for each p-order (with titles)
set style line 01 lc rgb "black"    pt 7 ps 0.5 lw 1
set style line 02 lc rgb "slategrey"    pt 7 ps 0.5 lw 1
set style line 11 lc rgb "red"    pt 7 ps 0.5 lw 1
set style line 12 lc rgb "red"    pt 6 ps 0.5 lw 1
set style line 21 lc rgb "blue"   pt 5 ps 0.5 lw 1
set style line 22 lc rgb "blue"   pt 4 ps 0.5 lw 1
set style line 31 lc rgb "violet" pt 9 ps 0.5 lw 1
set style line 32 lc rgb "violet" pt 8 ps 0.5 lw 1

set output "mms_3D_dispEfficiency_hex_struct.pdf"
plot \
    "hex.struct.seg.summary.txt" u  2:($5*1e6) w lp ls 01 title"S4F_{seg}", \
    "hex.struct.hypre-snes.summary.txt" u 2:($5*1e6) w lp ls 02 title "S4F_{snes}", \
    "hex.struct.ho.N1.summary.txt" u 2:($5*1e6) w lp ls 11  title "{/Times-Italic p}_{ }=1", \
    "hex.struct.ho.N2.summary.txt" u 2:($5*1e6) w lp ls 21  title "{/Times-Italic p}_{ }=2", \
    "hex.struct.ho.N3.summary.txt" u 2:($5*1e6) w lp ls 31  title "{/Times-Italic p}_{ }=3"

set output "mms_3D_dispEfficiency_tet_struct.pdf"
plot \
    "tet.struct.seg.summary.txt" u  2:($5*1e6) w lp ls 01 title"S4F_{seg}", \
    "tet.struct.hypre-snes.summary.txt" u 2:($5*1e6) w lp ls 02 title "S4F_{snes}", \
    "tet.struct.ho.N1.summary.txt" u 2:($5*1e6) w lp ls 11  title "{/Times-Italic p}_{ }=1", \
    "tet.struct.ho.N2.summary.txt" u 2:($5*1e6) w lp ls 21  title "{/Times-Italic p}_{ }=2", \
    "tet.struct.ho.N3.summary.txt" u 2:($5*1e6) w lp ls 31  title "{/Times-Italic p}_{ }=3"

set output "mms_3D_dispEfficiency_tet_unstruct.pdf"
plot \
    "tet.unstruct.seg.summary.txt" u  2:($5*1e6) w lp ls 01 title"S4F_{seg}", \
    "tet.unstruct.hypre-snes.summary.txt" u 2:($5*1e6) w lp ls 02 title "S4F_{snes}", \
    "tet.unstruct.ho.N1.summary.txt" u 2:($5*1e6) w lp ls 11  title "{/Times-Italic p}_{ }=1", \
    "tet.unstruct.ho.N2.summary.txt" u 2:($5*1e6) w lp ls 21  title "{/Times-Italic p}_{ }=2", \
    "tet.unstruct.ho.N3.summary.txt" u 2:($5*1e6) w lp ls 31  title "{/Times-Italic p}_{ }=3"

set output "mms_3D_dispeEfficiency_poly_struct.pdf"
plot \
    "poly.struct.seg.summary.txt" u  2:($5*1e6) w lp ls 01 title"S4F_{seg}", \
    "poly.struct.hypre-snes.summary.txt" u 2:($5*1e6) w lp ls 02 title "S4F_{snes}", \
    "poly.struct.ho.N1.summary.txt" u 2:($5*1e6) w lp ls 11  title "{/Times-Italic p}_{ }=1", \
    "poly.struct.ho.N2.summary.txt" u 2:($5*1e6) w lp ls 21  title "{/Times-Italic p}_{ }=2", \
    "poly.struct.ho.N3.summary.txt" u 2:($5*1e6) w lp ls 31  title "{/Times-Italic p}_{ }=3"

set output "mms_3D_stressEfficiency_hex_struct.pdf"
plot \
    "hex.struct.seg.summary.txt" u  2:($7*1e-6) w lp ls 01 title"S4F_{seg}", \
    "hex.struct.hypre-snes.summary.txt" u 2:($7*1e-6) w lp ls 02 title "S4F_{snes}", \
    "hex.struct.ho.N1.summary.txt" u 2:($7*1e-6) w lp ls 11  title "{/Times-Italic p}_{ }=1", \
    "hex.struct.ho.N2.summary.txt" u 2:($7*1e-6) w lp ls 21  title "{/Times-Italic p}_{ }=2", \
    "hex.struct.ho.N3.summary.txt" u 2:($7*1e-6) w lp ls 31  title "{/Times-Italic p}_{ }=3"

set output "mms_3D_stressEfficiency_tet_struct.pdf"
plot \
    "tet.struct.seg.summary.txt" u  2:($7*1e-6) w lp ls 01 title"S4F_{seg}", \
    "tet.struct.hypre-snes.summary.txt" u 2:($7*1e-6) w lp ls 02 title "S4F_{snes}", \
    "tet.struct.ho.N1.summary.txt" u 2:($7*1e-6) w lp ls 11  title "{/Times-Italic p}_{ }=1", \
    "tet.struct.ho.N2.summary.txt" u 2:($7*1e-6) w lp ls 21  title "{/Times-Italic p}_{ }=2", \
    "tet.struct.ho.N3.summary.txt" u 2:($7*1e-6) w lp ls 31  title "{/Times-Italic p}_{ }=3"

set output "mms_3D_stressEfficiency_tet_unstruct.pdf"
plot \
    "tet.unstruct.seg.summary.txt" u  2:($7*1e-6) w lp ls 01 title"S4F_{seg}", \
    "tet.unstruct.hypre-snes.summary.txt" u 2:($7*1e-6) w lp ls 02 title "S4F_{snes}", \
    "tet.unstruct.ho.N1.summary.txt" u 2:($7*1e-6) w lp ls 11  title "{/Times-Italic p}_{ }=1", \
    "tet.unstruct.ho.N2.summary.txt" u 2:($7*1e-6) w lp ls 21  title "{/Times-Italic p}_{ }=2", \
    "tet.unstruct.ho.N3.summary.txt" u 2:($7*1e-6) w lp ls 31  title "{/Times-Italic p}_{ }=3"

set output "mms_3D_stressEfficiency_poly_struct.pdf"
plot \
    "poly.struct.seg.summary.txt" u  2:($7*1e-6) w lp ls 01 title"S4F_{seg}", \
    "poly.struct.hypre-snes.summary.txt" u 2:($7*1e-6) w lp ls 02 title "S4F_{snes}", \
    "poly.struct.ho.N1.summary.txt" u 2:($7*1e-6) w lp ls 11  title "{/Times-Italic p}_{ }=1", \
    "poly.struct.ho.N2.summary.txt" u 2:($7*1e-6) w lp ls 21  title "{/Times-Italic p}_{ }=2", \
    "poly.struct.ho.N3.summary.txt" u 2:($7*1e-6) w lp ls 31  title "{/Times-Italic p}_{ }=3"
