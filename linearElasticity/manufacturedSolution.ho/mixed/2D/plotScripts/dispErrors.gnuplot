set term pdfcairo dashed enhanced size 3.25, 2
set datafile separator " "

set grid
set xrange [25:400]
set yrange [1e-7:1]
set xtics
set xtics add (5, 25, 50)
set ytics
set logscale x
set logscale y
set format y "10^{%L}"
#set ytics 0.002
set xlabel "Average cell edge (in mm)"
set ylabel "Error (in m)"
set key right bottom outside;
set rmargin 16
set key spacing 1.2

# Polynomial guide lines (no title)
set style line 1 lc rgb "red"    lt 2 lw 2 dt 2
set style line 2 lc rgb "blue"   lt 2 lw 2 dt 2
set style line 3 lc rgb "violet" lt 2 lw 2 dt 2

# Data lines for each p-order (with titles)
set style line 11 lc rgb "red"    pt 7 ps 0.5 lw 1
set style line 12 lc rgb "red"    pt 6 ps 0.5 lw 1
set style line 21 lc rgb "blue"   pt 5 ps 0.5 lw 1
set style line 22 lc rgb "blue"   pt 4 ps 0.5 lw 1
set style line 31 lc rgb "violet" pt 9 ps 0.5 lw 1
set style line 32 lc rgb "violet" pt 8 ps 0.5 lw 1

set output "mms_2D_dispErrors_hex_struct.pdf"
plot \
    (3e-6 * x**2)         w l ls 1 title "2^{nd} order", \
    (0.15e-08 * x**3)     w l ls 2 title "3^{rd} order", \
    (0.8e-12 * x**4)      w l ls 3 title "4^{th} order", \
    "hex.struct.ho.N1.summary.txt" u ((1/$4)**0.5*1e3):($5) w lp ls 11  title "{/Times-Italic L}_{ 2} ({/Times-Italic p}_{ }=1)", \
    "hex.struct.ho.N1.summary.txt" u ((1/$4)**0.5*1e3):($6) w lp ls 12  title "{/Times-Italic L}_{ ∞} ({/Times-Italic p}_{ }=1)", \
    "hex.struct.ho.N2.summary.txt" u ((1/$4)**0.5*1e3):($5) w lp ls 21  title "{/Times-Italic L}_{ 2} ({/Times-Italic p}_{ }=2)", \
    "hex.struct.ho.N2.summary.txt" u ((1/$4)**0.5*1e3):($6) w lp ls 22  title "{/Times-Italic L}_{ ∞} ({/Times-Italic p}_{ }=2)", \
    "hex.struct.ho.N3.summary.txt" u ((1/$4)**0.5*1e3):($5) w lp ls 31  title "{/Times-Italic L}_{ 2} ({/Times-Italic p}_{ }=3)" , \
    "hex.struct.ho.N3.summary.txt" u ((1/$4)**0.5*1e3):($6) w lp ls 32  title "{/Times-Italic L}_{ ∞} ({/Times-Italic p}_{ }=3)"

set output "mms_2D_dispErrors_ho-tet_struct.pdf"
plot \
    (3e-6 * x**2)         w l ls 1 title "2^{nd} order", \
    (0.15e-08 * x**3)     w l ls 2 title "3^{rd} order", \
    (0.8e-12 * x**4)      w l ls 3 title "4^{th} order", \
    "tet.struct.ho.N1.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($5) w lp ls 11  title "{/Times-Italic L}_{ 2} ({/Times-Italic p}_{ }=1)", \
    "tet.struct.ho.N1.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($6) w lp ls 12  title "{/Times-Italic L}_{ ∞} ({/Times-Italic p}_{ }=1)", \
    "tet.struct.ho.N2.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($5) w lp ls 21  title "{/Times-Italic L}_{ 2} ({/Times-Italic p}_{ }=2)", \
    "tet.struct.ho.N2.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($6) w lp ls 22  title "{/Times-Italic L}_{ ∞} ({/Times-Italic p}_{ }=2)", \
    "tet.struct.ho.N3.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($5) w lp ls 31  title "{/Times-Italic L}_{ 2} ({/Times-Italic p}_{ }=3)", \
    "tet.struct.ho.N3.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($6) w lp ls 32  title "{/Times-Italic L}_{ ∞} ({/Times-Italic p}_{ }=3)"

set output "mms_2D_dispErrors_ho-tet_unstruct_v1.pdf"
plot \
    (3e-6 * x**2)         w l ls 1 title "2^{nd} order", \
    (0.15e-08 * x**3)     w l ls 2 title "3^{rd} order", \
    (0.8e-12 * x**4)      w l ls 3 title "4^{th} order", \
    "tet.unstruct_v1.ho.N1.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($5) w lp ls 11  title "{/Times-Italic L}_{ 2} ({/Times-Italic p}_{ }=1)", \
    "tet.unstruct_v1.ho.N1.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($6) w lp ls 12  title "{/Times-Italic L}_{ ∞} ({/Times-Italic p}_{ }=1)", \
    "tet.unstruct_v1.ho.N2.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($5) w lp ls 21  title "{/Times-Italic L}_{ 2} ({/Times-Italic p}_{ }=2)", \
    "tet.unstruct_v1.ho.N2.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($6) w lp ls 22  title "{/Times-Italic L}_{ ∞} ({/Times-Italic p}_{ }=2)", \
    "tet.unstruct_v1.ho.N3.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($5) w lp ls 31  title "{/Times-Italic L}_{ 2} ({/Times-Italic p}_{ }=3)", \
    "tet.unstruct_v1.ho.N3.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($6) w lp ls 32  title "{/Times-Italic L}_{ ∞} ({/Times-Italic p}_{ }=3)"

set output "mms_2D_dispErrors_ho-tet_unstruct_v2.pdf"
plot \
    (3e-6 * x**2)         w l ls 1 title "2^{nd} order", \
    (0.15e-08 * x**3)     w l ls 2 title "3^{rd} order", \
    (0.8e-12 * x**4)      w l ls 3 title "4^{th} order", \
    "tet.unstruct_v2.ho.N1.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($5) w lp ls 11  title "{/Times-Italic L}_{ 2} ({/Times-Italic p}_{ }=1)", \
    "tet.unstruct_v2.ho.N1.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($6) w lp ls 12  title "{/Times-Italic L}_{ ∞} ({/Times-Italic p}_{ }=1)", \
    "tet.unstruct_v2.ho.N2.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($5) w lp ls 21  title "{/Times-Italic L}_{ 2} ({/Times-Italic p}_{ }=2)", \
    "tet.unstruct_v2.ho.N2.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($6) w lp ls 22  title "{/Times-Italic L}_{ ∞} ({/Times-Italic p}_{ }=2)", \
    "tet.unstruct_v2.ho.N3.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($5) w lp ls 31  title "{/Times-Italic L}_{ 2} ({/Times-Italic p}_{ }=3)", \
    "tet.unstruct_v2.ho.N3.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($6) w lp ls 32  title "{/Times-Italic L}_{ ∞} ({/Times-Italic p}_{ }=3)"

set output "mms_2D_dispErrors_ho-poly_struct.pdf"
plot \
    (3e-6 * x**2)         w l ls 1 title "2^{nd} order", \
    (0.15e-08 * x**3)     w l ls 2 title "3^{rd} order", \
    (0.8e-12 * x**4)      w l ls 3 title "4^{th} order", \
    "poly.struct.ho.N1.summary.txt" u (1*(1/$4)**0.5*1e3):($5) w lp ls 11  title "{/Times-Italic L}_{ 2} ({/Times-Italic p}_{ }=1)", \
    "poly.struct.ho.N1.summary.txt" u (1*(1/$4)**0.5*1e3):($6) w lp ls 12  title "{/Times-Italic L}_{ ∞} ({/Times-Italic p}_{ }=1)", \
    "poly.struct.ho.N2.summary.txt" u (1*(1/$4)**0.5*1e3):($5) w lp ls 21  title "{/Times-Italic L}_{ 2} ({/Times-Italic p}_{ }=2)", \
    "poly.struct.ho.N2.summary.txt" u (1*(1/$4)**0.5*1e3):($6) w lp ls 22  title "{/Times-Italic L}_{ ∞} ({/Times-Italic p}_{ }=2)", \
    "poly.struct.ho.N3.summary.txt" u (1*(1/$4)**0.5*1e3):($5) w lp ls 31  title "{/Times-Italic L}_{ 2} ({/Times-Italic p}_{ }=3)", \
    "poly.struct.ho.N3.summary.txt" u (1*(1/$4)**0.5*1e3):($6) w lp ls 32  title "{/Times-Italic L}_{ ∞} ({/Times-Italic p}_{ }=3)"
