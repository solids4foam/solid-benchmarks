set term pdfcairo dashed enhanced size 3.25, 2
set datafile separator " "

if (ARGC < 1) {
    print "Usage: gnuplot -c dispErrors_movingVskExact.gnuplot <movingLeastSquares-results-directory>"
    exit
}

movingResults = ARG1
movingFile(fileName) = sprintf("%s/%s", movingResults, fileName)

set grid
set xrange [25:500]
set yrange [1e-7:1]
set xtics
set xtics add (5, 25, 50, 500)
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

# Moving-least-squares data use the same colours with 50% transparency
set style line 111 lc rgb "#80ff0000" pt 7 ps 0.5 lw 1
set style line 112 lc rgb "#80ff0000" pt 6 ps 0.5 lw 1
set style line 121 lc rgb "#800000ff" pt 5 ps 0.5 lw 1
set style line 122 lc rgb "#800000ff" pt 4 ps 0.5 lw 1
set style line 131 lc rgb "#80ee82ee" pt 9 ps 0.5 lw 1
set style line 132 lc rgb "#80ee82ee" pt 8 ps 0.5 lw 1

set output "mms_2D_dispErrors_hex_struct_movingVskExact.pdf"
plot \
    (3e-6 * x**2)         w l ls 1 title "2^{nd} order", \
    (0.15e-08 * x**3)     w l ls 2 title "3^{rd} order", \
    (0.8e-12 * x**4)      w l ls 3 title "4^{th} order", \
    "hex.struct.ho.N1.summary.txt" u ((1/$4)**0.5*1e3):($5) w lp ls 11  title "{/Times-Italic L}_{ 2} ({/Times-Italic p}_{ }=1)", \
    "hex.struct.ho.N1.summary.txt" u ((1/$4)**0.5*1e3):($6) w lp ls 12  title "{/Times-Italic L}_{ ∞} ({/Times-Italic p}_{ }=1)", \
    "hex.struct.ho.N2.summary.txt" u ((1/$4)**0.5*1e3):($5) w lp ls 21  title "{/Times-Italic L}_{ 2} ({/Times-Italic p}_{ }=2)", \
    "hex.struct.ho.N2.summary.txt" u ((1/$4)**0.5*1e3):($6) w lp ls 22  title "{/Times-Italic L}_{ ∞} ({/Times-Italic p}_{ }=2)", \
    "hex.struct.ho.N3.summary.txt" u ((1/$4)**0.5*1e3):($5) w lp ls 31  title "{/Times-Italic L}_{ 2} ({/Times-Italic p}_{ }=3)" , \
    "hex.struct.ho.N3.summary.txt" u ((1/$4)**0.5*1e3):($6) w lp ls 32  title "{/Times-Italic L}_{ ∞} ({/Times-Italic p}_{ }=3)", \
    movingFile("hex.struct.ho.N1.summary.txt") u ((1/$4)**0.5*1e3):($5) w lp ls 111 notitle, \
    movingFile("hex.struct.ho.N1.summary.txt") u ((1/$4)**0.5*1e3):($6) w lp ls 112 notitle, \
    movingFile("hex.struct.ho.N2.summary.txt") u ((1/$4)**0.5*1e3):($5) w lp ls 121 notitle, \
    movingFile("hex.struct.ho.N2.summary.txt") u ((1/$4)**0.5*1e3):($6) w lp ls 122 notitle, \
    movingFile("hex.struct.ho.N3.summary.txt") u ((1/$4)**0.5*1e3):($5) w lp ls 131 notitle, \
    movingFile("hex.struct.ho.N3.summary.txt") u ((1/$4)**0.5*1e3):($6) w lp ls 132 notitle

set output "mms_2D_dispErrors_ho-tet_struct_movingVskExact.pdf"
plot \
    (3e-6 * x**2)         w l ls 1 title "2^{nd} order", \
    (0.15e-08 * x**3)     w l ls 2 title "3^{rd} order", \
    (0.8e-12 * x**4)      w l ls 3 title "4^{th} order", \
    "tet.struct.ho.N1.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($5) w lp ls 11  title "{/Times-Italic L}_{ 2} ({/Times-Italic p}_{ }=1)", \
    "tet.struct.ho.N1.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($6) w lp ls 12  title "{/Times-Italic L}_{ ∞} ({/Times-Italic p}_{ }=1)", \
    "tet.struct.ho.N2.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($5) w lp ls 21  title "{/Times-Italic L}_{ 2} ({/Times-Italic p}_{ }=2)", \
    "tet.struct.ho.N2.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($6) w lp ls 22  title "{/Times-Italic L}_{ ∞} ({/Times-Italic p}_{ }=2)", \
    "tet.struct.ho.N3.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($5) w lp ls 31  title "{/Times-Italic L}_{ 2} ({/Times-Italic p}_{ }=3)", \
    "tet.struct.ho.N3.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($6) w lp ls 32  title "{/Times-Italic L}_{ ∞} ({/Times-Italic p}_{ }=3)", \
    movingFile("tet.struct.ho.N1.summary.txt") u ((4*(1/$4)/3**0.5)**0.5*1e3):($5) w lp ls 111 notitle, \
    movingFile("tet.struct.ho.N1.summary.txt") u ((4*(1/$4)/3**0.5)**0.5*1e3):($6) w lp ls 112 notitle, \
    movingFile("tet.struct.ho.N2.summary.txt") u ((4*(1/$4)/3**0.5)**0.5*1e3):($5) w lp ls 121 notitle, \
    movingFile("tet.struct.ho.N2.summary.txt") u ((4*(1/$4)/3**0.5)**0.5*1e3):($6) w lp ls 122 notitle, \
    movingFile("tet.struct.ho.N3.summary.txt") u ((4*(1/$4)/3**0.5)**0.5*1e3):($5) w lp ls 131 notitle, \
    movingFile("tet.struct.ho.N3.summary.txt") u ((4*(1/$4)/3**0.5)**0.5*1e3):($6) w lp ls 132 notitle

set output "mms_2D_dispErrors_ho-tet_unstruct_v1_movingVskExact.pdf"
plot \
    (3e-6 * x**2)         w l ls 1 title "2^{nd} order", \
    (0.15e-08 * x**3)     w l ls 2 title "3^{rd} order", \
    (0.8e-12 * x**4)      w l ls 3 title "4^{th} order", \
    "tet.unstruct_v1.ho.N1.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($5) w lp ls 11  title "{/Times-Italic L}_{ 2} ({/Times-Italic p}_{ }=1)", \
    "tet.unstruct_v1.ho.N1.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($6) w lp ls 12  title "{/Times-Italic L}_{ ∞} ({/Times-Italic p}_{ }=1)", \
    "tet.unstruct_v1.ho.N2.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($5) w lp ls 21  title "{/Times-Italic L}_{ 2} ({/Times-Italic p}_{ }=2)", \
    "tet.unstruct_v1.ho.N2.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($6) w lp ls 22  title "{/Times-Italic L}_{ ∞} ({/Times-Italic p}_{ }=2)", \
    "tet.unstruct_v1.ho.N3.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($5) w lp ls 31  title "{/Times-Italic L}_{ 2} ({/Times-Italic p}_{ }=3)", \
    "tet.unstruct_v1.ho.N3.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($6) w lp ls 32  title "{/Times-Italic L}_{ ∞} ({/Times-Italic p}_{ }=3)", \
    movingFile("tet.unstruct_v1.ho.N1.summary.txt") u ((4*(1/$4)/3**0.5)**0.5*1e3):($5) w lp ls 111 notitle, \
    movingFile("tet.unstruct_v1.ho.N1.summary.txt") u ((4*(1/$4)/3**0.5)**0.5*1e3):($6) w lp ls 112 notitle, \
    movingFile("tet.unstruct_v1.ho.N2.summary.txt") u ((4*(1/$4)/3**0.5)**0.5*1e3):($5) w lp ls 121 notitle, \
    movingFile("tet.unstruct_v1.ho.N2.summary.txt") u ((4*(1/$4)/3**0.5)**0.5*1e3):($6) w lp ls 122 notitle, \
    movingFile("tet.unstruct_v1.ho.N3.summary.txt") u ((4*(1/$4)/3**0.5)**0.5*1e3):($5) w lp ls 131 notitle, \
    movingFile("tet.unstruct_v1.ho.N3.summary.txt") u ((4*(1/$4)/3**0.5)**0.5*1e3):($6) w lp ls 132 notitle

set output "mms_2D_dispErrors_ho-tet_unstruct_v2_movingVskExact.pdf"
plot \
    (3e-6 * x**2)         w l ls 1 title "2^{nd} order", \
    (0.15e-08 * x**3)     w l ls 2 title "3^{rd} order", \
    (0.8e-12 * x**4)      w l ls 3 title "4^{th} order", \
    "tet.unstruct_v2.ho.N1.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($5) w lp ls 11  title "{/Times-Italic L}_{ 2} ({/Times-Italic p}_{ }=1)", \
    "tet.unstruct_v2.ho.N1.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($6) w lp ls 12  title "{/Times-Italic L}_{ ∞} ({/Times-Italic p}_{ }=1)", \
    "tet.unstruct_v2.ho.N2.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($5) w lp ls 21  title "{/Times-Italic L}_{ 2} ({/Times-Italic p}_{ }=2)", \
    "tet.unstruct_v2.ho.N2.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($6) w lp ls 22  title "{/Times-Italic L}_{ ∞} ({/Times-Italic p}_{ }=2)", \
    "tet.unstruct_v2.ho.N3.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($5) w lp ls 31  title "{/Times-Italic L}_{ 2} ({/Times-Italic p}_{ }=3)", \
    "tet.unstruct_v2.ho.N3.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($6) w lp ls 32  title "{/Times-Italic L}_{ ∞} ({/Times-Italic p}_{ }=3)", \
    movingFile("tet.unstruct_v2.ho.N1.summary.txt") u ((4*(1/$4)/3**0.5)**0.5*1e3):($5) w lp ls 111 notitle, \
    movingFile("tet.unstruct_v2.ho.N1.summary.txt") u ((4*(1/$4)/3**0.5)**0.5*1e3):($6) w lp ls 112 notitle, \
    movingFile("tet.unstruct_v2.ho.N2.summary.txt") u ((4*(1/$4)/3**0.5)**0.5*1e3):($5) w lp ls 121 notitle, \
    movingFile("tet.unstruct_v2.ho.N2.summary.txt") u ((4*(1/$4)/3**0.5)**0.5*1e3):($6) w lp ls 122 notitle, \
    movingFile("tet.unstruct_v2.ho.N3.summary.txt") u ((4*(1/$4)/3**0.5)**0.5*1e3):($5) w lp ls 131 notitle, \
    movingFile("tet.unstruct_v2.ho.N3.summary.txt") u ((4*(1/$4)/3**0.5)**0.5*1e3):($6) w lp ls 132 notitle

set output "mms_2D_dispErrors_ho-poly_struct_movingVskExact.pdf"
plot \
    (3e-6 * x**2)         w l ls 1 title "2^{nd} order", \
    (0.15e-08 * x**3)     w l ls 2 title "3^{rd} order", \
    (0.8e-12 * x**4)      w l ls 3 title "4^{th} order", \
    "poly.struct.ho.N1.summary.txt" u ((4*(1/$4)/pi)**0.5*1e3):($5) w lp ls 11  title "{/Times-Italic L}_{ 2} ({/Times-Italic p}_{ }=1)", \
    "poly.struct.ho.N1.summary.txt" u ((4*(1/$4)/pi)**0.5*1e3):($6) w lp ls 12  title "{/Times-Italic L}_{ ∞} ({/Times-Italic p}_{ }=1)", \
    "poly.struct.ho.N2.summary.txt" u ((4*(1/$4)/pi)**0.5*1e3):($5) w lp ls 21  title "{/Times-Italic L}_{ 2} ({/Times-Italic p}_{ }=2)", \
    "poly.struct.ho.N2.summary.txt" u ((4*(1/$4)/pi)**0.5*1e3):($6) w lp ls 22  title "{/Times-Italic L}_{ ∞} ({/Times-Italic p}_{ }=2)", \
    "poly.struct.ho.N3.summary.txt" u ((4*(1/$4)/pi)**0.5*1e3):($5) w lp ls 31  title "{/Times-Italic L}_{ 2} ({/Times-Italic p}_{ }=3)", \
    "poly.struct.ho.N3.summary.txt" u ((4*(1/$4)/pi)**0.5*1e3):($6) w lp ls 32  title "{/Times-Italic L}_{ ∞} ({/Times-Italic p}_{ }=3)", \
    movingFile("poly.struct.ho.N1.summary.txt") u ((4*(1/$4)/pi)**0.5*1e3):($5) w lp ls 111 notitle, \
    movingFile("poly.struct.ho.N1.summary.txt") u ((4*(1/$4)/pi)**0.5*1e3):($6) w lp ls 112 notitle, \
    movingFile("poly.struct.ho.N2.summary.txt") u ((4*(1/$4)/pi)**0.5*1e3):($5) w lp ls 121 notitle, \
    movingFile("poly.struct.ho.N2.summary.txt") u ((4*(1/$4)/pi)**0.5*1e3):($6) w lp ls 122 notitle, \
    movingFile("poly.struct.ho.N3.summary.txt") u ((4*(1/$4)/pi)**0.5*1e3):($5) w lp ls 131 notitle, \
    movingFile("poly.struct.ho.N3.summary.txt") u ((4*(1/$4)/pi)**0.5*1e3):($6) w lp ls 132 notitle
