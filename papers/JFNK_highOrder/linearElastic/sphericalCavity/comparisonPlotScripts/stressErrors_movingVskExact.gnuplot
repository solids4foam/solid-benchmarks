set term pdfcairo dashed enhanced size 3.25, 2
set datafile separator " "

if (ARGC < 1) {
    print "Usage: gnuplot -c stressErrors_movingVskExact.gnuplot <movingLeastSquares-results-directory>"
    exit
}

movingResults = ARG1
movingFile(fileName) = sprintf("%s/%s", movingResults, fileName)

volume = 0.104056049

set grid
set xrange [20:80]
#set yrange [1e-3:100]
set xtics
set xtics add (5, 25, 50)
set ytics
set logscale x
set logscale y
set format y "10^{%L}"
#set ytics 0.002
set xlabel "Average cell edge (in mm)"
set ylabel "Error (in MPa)"
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
set style line 111 lc rgb "#B3ff0000" pt 7 ps 0.5 lw 1
set style line 112 lc rgb "#B3ff0000" pt 6 ps 0.5 lw 1
set style line 121 lc rgb "#B30000ff" pt 5 ps 0.5 lw 1
set style line 122 lc rgb "#B30000ff" pt 4 ps 0.5 lw 1
set style line 131 lc rgb "#B3ee82ee" pt 9 ps 0.5 lw 1
set style line 132 lc rgb "#B3ee82ee" pt 8 ps 0.5 lw 1

set style line 50 lc rgb "orange" pt 11 ps 0.5 lw 1

set output "sphericalCavity_stressErrors_tet_movingVskExact.pdf"
plot \
    (5e-4 * x)      w l ls 1 title "1^{st} order",\
    (11e-7 * x**2)  w l ls 2 title "2^{nd} order",\
    (1e-8 * x**3)   w l ls 3 title "3^{rd} order",\
    "tet.unstruct.ho.N1.summary.txt" u ((8.48528*(volume/$4))**(1.0/3.0)*1e3):($7*1e-6) w lp ls 11  title "{/Times-Italic L}_{ 2} ({/Times-Italic p}_{ }=1)", \
    "tet.unstruct.ho.N1.summary.txt" u ((8.48528*(volume/$4))**(1.0/3.0)*1e3):($8*1e-6) w lp ls 12  title "{/Times-Italic L}_{ ∞} ({/Times-Italic p}_{ }=1)", \
    "tet.unstruct.ho.N2.summary.txt" u ((8.48528*(volume/$4))**(1.0/3.0)*1e3):($7*1e-6) w lp ls 21  title "{/Times-Italic L}_{ 2} ({/Times-Italic p}_{ }=2)", \
    "tet.unstruct.ho.N2.summary.txt" u ((8.48528*(volume/$4))**(1.0/3.0)*1e3):($8*1e-6) w lp ls 22  title "{/Times-Italic L}_{ ∞} ({/Times-Italic p}_{ }=2)", \
    "tet.unstruct.ho.N3.summary.txt" u ((8.48528*(volume/$4))**(1.0/3.0)*1e3):($7*1e-6) w lp ls 31  title "{/Times-Italic L}_{ 2} ({/Times-Italic p}_{ }=3)", \
    "tet.unstruct.ho.N3.summary.txt" u ((8.48528*(volume/$4))**(1.0/3.0)*1e3):($8*1e-6) w lp ls 32  title "{/Times-Italic L}_{ ∞} ({/Times-Italic p}_{ }=3)", \
    NaN w l lc rgb "white" title " ", \
    "tet.unstruct.ho.N3.summary.zeroTraction.txt" u ((8.48528*(volume/$4))**(1.0/3.0)*1e3):($7*1e-6) w lp ls 50 title "{/Times-Italic L}_{ 2} ({/Times-Italic p}^{_*}_{ }=3)" , \
    movingFile("tet.unstruct.ho.N1.summary.txt") u ((8.48528*(volume/$4))**(1.0/3.0)*1e3):($7*1e-6) w lp ls 111 notitle , \
    movingFile("tet.unstruct.ho.N1.summary.txt") u ((8.48528*(volume/$4))**(1.0/3.0)*1e3):($8*1e-6) w lp ls 112 notitle , \
    movingFile("tet.unstruct.ho.N2.summary.txt") u ((8.48528*(volume/$4))**(1.0/3.0)*1e3):($7*1e-6) w lp ls 121 notitle , \
    movingFile("tet.unstruct.ho.N2.summary.txt") u ((8.48528*(volume/$4))**(1.0/3.0)*1e3):($8*1e-6) w lp ls 122 notitle , \
    movingFile("tet.unstruct.ho.N3.summary.txt") u ((8.48528*(volume/$4))**(1.0/3.0)*1e3):($7*1e-6) w lp ls 131 notitle , \
    movingFile("tet.unstruct.ho.N3.summary.txt") u ((8.48528*(volume/$4))**(1.0/3.0)*1e3):($8*1e-6) w lp ls 132 notitle

set output "sphericalCavity_stressErrors_poly_movingVskExact.pdf"
set xrange [15:80]
plot \
    (5e-4 * x)      w l ls 1 title "1^{st} order",\
    (11e-7 * x**2)  w l ls 2 title "2^{nd} order",\
    (1e-8 * x**3)   w l ls 3 title "3^{rd} order",\
    "poly.unstruct.ho.N1.summary.txt" u ((6*(volume/$4)/pi)**(1.0/3.0)*1e3):($7*1e-6) w lp ls 11  title "{/Times-Italic L}_{ 2} ({/Times-Italic p}_{ }=1)", \
    "poly.unstruct.ho.N1.summary.txt" u ((6*(volume/$4)/pi)**(1.0/3.0)*1e3):($8*1e-6) w lp ls 12  title "{/Times-Italic L}_{ ∞} ({/Times-Italic p}_{ }=1)", \
    "poly.unstruct.ho.N2.summary.txt" u ((6*(volume/$4)/pi)**(1.0/3.0)*1e3):($7*1e-6) w lp ls 21  title "{/Times-Italic L}_{ 2} ({/Times-Italic p}_{ }=2)", \
    "poly.unstruct.ho.N2.summary.txt" u ((6*(volume/$4)/pi)**(1.0/3.0)*1e3):($8*1e-6) w lp ls 22  title "{/Times-Italic L}_{ ∞} ({/Times-Italic p}_{ }=2)", \
    "poly.unstruct.ho.N3.summary.txt" u ((6*(volume/$4)/pi)**(1.0/3.0)*1e3):($7*1e-6) w lp ls 31  title "{/Times-Italic L}_{ 2} ({/Times-Italic p}_{ }=3)", \
    "poly.unstruct.ho.N3.summary.txt" u ((6*(volume/$4)/pi)**(1.0/3.0)*1e3):($8*1e-6) w lp ls 32  title "{/Times-Italic L}_{ ∞} ({/Times-Italic p}_{ }=3)" , \
    movingFile("poly.unstruct.ho.N1.summary.txt") u ((6*(volume/$4)/pi)**(1.0/3.0)*1e3):($7*1e-6) w lp ls 111 notitle , \
    movingFile("poly.unstruct.ho.N1.summary.txt") u ((6*(volume/$4)/pi)**(1.0/3.0)*1e3):($8*1e-6) w lp ls 112 notitle , \
    movingFile("poly.unstruct.ho.N2.summary.txt") u ((6*(volume/$4)/pi)**(1.0/3.0)*1e3):($7*1e-6) w lp ls 121 notitle , \
    movingFile("poly.unstruct.ho.N2.summary.txt") u ((6*(volume/$4)/pi)**(1.0/3.0)*1e3):($8*1e-6) w lp ls 122 notitle , \
    movingFile("poly.unstruct.ho.N3.summary.txt") u ((6*(volume/$4)/pi)**(1.0/3.0)*1e3):($7*1e-6) w lp ls 131 notitle , \
    movingFile("poly.unstruct.ho.N3.summary.txt") u ((6*(volume/$4)/pi)**(1.0/3.0)*1e3):($8*1e-6) w lp ls 132 notitle
