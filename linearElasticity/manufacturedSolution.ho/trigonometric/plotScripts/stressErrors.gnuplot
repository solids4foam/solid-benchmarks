set term pdfcairo dashed enhanced size 3.25, 2
set datafile separator " "

volume = 0.2**3

set grid
set xrange [5:60]
set yrange [1e-8:10]
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

set output "mms_3D_stressErrors_hex_struct.pdf"
plot \
    (2e-2 * x)  w l ls 1 title "1^{st} order", \
    (0.15e-3 * x**2) w l ls 2 title "2^{nd} order", \
    (0.4e-6 * x**3) w l ls 3 title "3^{rd} order", \
    "hex.struct.ho.N1.summary.txt" u ((volume/$4)**(1.0/3.0)*1e3):($7*1e-6) w lp ls 11  title "{/Times-Italic L}_{ 2} ({/Times-Italic p}_{ }=1)", \
    "hex.struct.ho.N1.summary.txt" u ((volume/$4)**(1.0/3.0)*1e3):($8*1e-6) w lp ls 12  title "{/Times-Italic L}_{ ∞} ({/Times-Italic p}_{ }=1)", \
    "hex.struct.ho.N2.summary.txt" u ((volume/$4)**(1.0/3.0)*1e3):($7*1e-6) w lp ls 21  title "{/Times-Italic L}_{ 2} ({/Times-Italic p}_{ }=2)", \
    "hex.struct.ho.N2.summary.txt" u ((volume/$4)**(1.0/3.0)*1e3):($8*1e-6) w lp ls 22  title "{/Times-Italic L}_{ ∞} ({/Times-Italic p}_{ }=2)", \
    "hex.struct.ho.N3.summary.txt" u ((volume/$4)**(1.0/3.0)*1e3):($7*1e-6) w lp ls 31  title "{/Times-Italic L}_{ 2} ({/Times-Italic p}_{ }=3)", \
    "hex.struct.ho.N3.summary.txt" u ((volume/$4)**(1.0/3.0)*1e3):($8*1e-6) w lp ls 32  title "{/Times-Italic L}_{ ∞} ({/Times-Italic p}_{ }=3)"

set output "mms_3D_stressErrors_ho-tet_struct.pdf"
plot \
    (2e-2 * x)  w l ls 1 title "1^{st} order", \
    (0.15e-3 * x**2) w l ls 2 title "2^{nd} order", \
    (0.4e-6 * x**3) w l ls 3 title "3^{rd} order", \
    "tet.struct.ho.N1.summary.txt" u ((8.48528*(volume/$4))**(1.0/3.0)*1e3):($7*1e-6) w lp ls 11  title "{/Times-Italic L}_{ 2} ({/Times-Italic p}_{ }=1)", \
    "tet.struct.ho.N1.summary.txt" u ((8.48528*(volume/$4))**(1.0/3.0)*1e3):($8*1e-6) w lp ls 12  title "{/Times-Italic L}_{ ∞} ({/Times-Italic p}_{ }=1)", \
    "tet.struct.ho.N2.summary.txt" u ((8.48528*(volume/$4))**(1.0/3.0)*1e3):($7*1e-6) w lp ls 21  title "{/Times-Italic L}_{ 2} ({/Times-Italic p}_{ }=2)", \
    "tet.struct.ho.N2.summary.txt" u ((8.48528*(volume/$4))**(1.0/3.0)*1e3):($8*1e-6) w lp ls 22  title "{/Times-Italic L}_{ ∞} ({/Times-Italic p}_{ }=2)", \
    "tet.struct.ho.N3.summary.txt" u ((8.48528*(volume/$4))**(1.0/3.0)*1e3):($7*1e-6) w lp ls 31  title "{/Times-Italic L}_{ 2} ({/Times-Italic p}_{ }=3)", \
    "tet.struct.ho.N3.summary.txt" u ((8.48528*(volume/$4))**(1.0/3.0)*1e3):($8*1e-6) w lp ls 32  title "{/Times-Italic L}_{ ∞} ({/Times-Italic p}_{ }=3)"

set output "mms_3D_stressErrors_ho-tet_unstruct.pdf"
plot \
    (2e-2 * x)  w l ls 1 title "1^{st} order", \
    (0.15e-3 * x**2) w l ls 2 title "2^{nd} order", \
    (0.4e-6 * x**3) w l ls 3 title "3^{rd} order", \
    "tet.unstruct.ho.N1.summary.txt" u ((8.48528*(volume/$4))**(1.0/3.0)*1e3):($7*1e-6) w lp ls 11  title "{/Times-Italic L}_{ 2} ({/Times-Italic p}_{ }=1)", \
    "tet.unstruct.ho.N1.summary.txt" u ((8.48528*(volume/$4))**(1.0/3.0)*1e3):($8*1e-6) w lp ls 12  title "{/Times-Italic L}_{ ∞} ({/Times-Italic p}_{ }=1)", \
    "tet.unstruct.ho.N2.summary.txt" u ((8.48528*(volume/$4))**(1.0/3.0)*1e3):($7*1e-6) w lp ls 21  title "{/Times-Italic L}_{ 2} ({/Times-Italic p}_{ }=2)", \
    "tet.unstruct.ho.N2.summary.txt" u ((8.48528*(volume/$4))**(1.0/3.0)*1e3):($8*1e-6) w lp ls 22  title "{/Times-Italic L}_{ ∞} ({/Times-Italic p}_{ }=2)", \
    "tet.unstruct.ho.N3.summary.txt" u ((8.48528*(volume/$4))**(1.0/3.0)*1e3):($7*1e-6) w lp ls 31  title "{/Times-Italic L}_{ 2} ({/Times-Italic p}_{ }=3)", \
    "tet.unstruct.ho.N3.summary.txt" u ((8.48528*(volume/$4))**(1.0/3.0)*1e3):($8*1e-6) w lp ls 32  title "{/Times-Italic L}_{ ∞} ({/Times-Italic p}_{ }=3)"

set output "mms_3D_stressErrors_ho-poly_struct.pdf"
plot \
    (2e-2 * x)  w l ls 1 title "1^{st} order", \
    (0.15e-3 * x**2) w l ls 2 title "2^{nd} order", \
    (0.4e-6 * x**3) w l ls 3 title "3^{rd} order", \
    "poly.struct.ho.N1.summary.txt" u ((6*(volume/$4)/pi)**(1.0/3.0)*1e3):($7*1e-6) w lp ls 11  title "{/Times-Italic L}_{ 2} ({/Times-Italic p}_{ }=1)", \
    "poly.struct.ho.N1.summary.txt" u ((6*(volume/$4)/pi)**(1.0/3.0)*1e3):($8*1e-6) w lp ls 12  title "{/Times-Italic L}_{ ∞} ({/Times-Italic p}_{ }=1)", \
    "poly.struct.ho.N2.summary.txt" u ((6*(volume/$4)/pi)**(1.0/3.0)*1e3):($7*1e-6) w lp ls 21  title "{/Times-Italic L}_{ 2} ({/Times-Italic p}_{ }=2)", \
    "poly.struct.ho.N2.summary.txt" u ((6*(volume/$4)/pi)**(1.0/3.0)*1e3):($8*1e-6) w lp ls 22  title "{/Times-Italic L}_{ ∞} ({/Times-Italic p}_{ }=2)", \
    "poly.struct.ho.N3.summary.txt" u ((6*(volume/$4)/pi)**(1.0/3.0)*1e3):($7*1e-6) w lp ls 31  title "{/Times-Italic L}_{ 2} ({/Times-Italic p}_{ }=3)", \
    "poly.struct.ho.N3.summary.txt" u ((6*(volume/$4)/pi)**(1.0/3.0)*1e3):($8*1e-6) w lp ls 32  title "{/Times-Italic L}_{ ∞} ({/Times-Italic p}_{ }=3)"
