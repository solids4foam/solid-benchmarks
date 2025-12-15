set term pdfcairo dashed enhanced size 3.25, 2
set datafile separator " "

volume = 0.2**3

set grid
set xrange [3:60]
set yrange [5e-7:0.2]
set xtics
set xtics add (5, 25, 50)
set ytics
set logscale x
set logscale y
set format y "10^{%L}"
#set ytics 0.002
set xlabel "Average cell edge (in mm)"
set ylabel "{/Times-Italic L}_{ 2} error (in μm)"
set key right bottom outside;
set rmargin 18
set key spacing 1.2
set key font ",10"

set datafile missing ""

# Polynomial guide lines (no title)
#set style line 10 lc rgb "red"    lt 2 lw 2 dt 2
#set style line 20 lc rgb "blue"   lt 2 lw 2 dt 2
#set style line 30 lc rgb "violet" lt 2 lw 2 dt 2

# Data lines for each p-order (with titles)
set style line 10 lc rgb "red"  lt 1  pt 6 ps 0.2 lw 1
set style line 1 lc rgb "red"   lt 1  pt 6 ps 0.4 lw 1
set style line 11 lc rgb "red"  lt 1  pt 6 ps 0.6 lw 2
set style line 111 lc rgb "red" lt 1  pt 6 ps 0.8 lw 1

set style line 20 lc rgb "blue"  lt 1 pt 4 ps 0.2 lw 1
set style line 2 lc rgb "blue"   lt 1 pt 4 ps 0.4 lw 1
set style line 22 lc rgb "blue"  lt 1 pt 4 ps 0.6 lw 2
set style line 222 lc rgb "blue" lt 1  pt 4 ps 0.8 lw 1

set style line 30 lc rgb "violet"  lt 1 pt 8 ps 0.2 lw 1
set style line 3 lc rgb "violet"   lt 1 pt 8 ps 0.4 lw 1
set style line 33 lc rgb "violet"  lt 1 pt 8 ps 0.6 lw 2
set style line 333 lc rgb "violet" lt 1 pt 8 ps 0.8 lw 1

#    (1e-4 * x**2)  w l ls 10 title "2^{nd} order", \
#    (4e-07 * x**3) w l ls 20 title "3^{rd} order", \
#    (5e-10 * x**4) w l ls 30 title "4^{th} order", \

set output "mms_3D_alpha_disp_hex_struct.pdf"
plot \
    "hex.struct.ho.N1.alpha.0.001.summary.txt" u ((volume/$4)**(1.0/3.0)*1e3):($5*1e6) w lp ls 10  title "{/Symbol a}=0.001 ({/Times-Italic p}_{ }=1)", \
    "hex.struct.ho.N1.alpha.0.01.summary.txt" u ((volume/$4)**(1.0/3.0)*1e3):($5*1e6) w lp ls 1  title "{/Symbol a}=0.01 ({/Times-Italic p}_{ }=1)", \
    "hex.struct.ho.N1.alpha.0.1.summary.txt" u ((volume/$4)**(1.0/3.0)*1e3):($5*1e6) w lp ls 11  title "{/Symbol a}=0.1 ({/Times-Italic p}_{ }=1)", \
    "hex.struct.ho.N1.alpha.1.summary.txt" u ((volume/$4)**(1.0/3.0)*1e3):($5*1e6) w lp ls 111  title "{/Symbol a}=1 ({/Times-Italic p}_{ }=1)", \
    "hex.struct.ho.N2.alpha.0.001.summary.txt" u ((volume/$4)**(1.0/3.0)*1e3):($5*1e6) w lp ls 20  title "{/Symbol a}=0.001 ({/Times-Italic p}_{ }=2)", \
    "hex.struct.ho.N2.alpha.0.01.summary.txt" u ((volume/$4)**(1.0/3.0)*1e3):($5*1e6) w lp ls 2  title "{/Symbol a}=0.01 ({/Times-Italic p}_{ }=2)", \
    "hex.struct.ho.N2.alpha.0.1.summary.txt" u ((volume/$4)**(1.0/3.0)*1e3):($5*1e6) w lp ls 22  title "{/Symbol a}=0.1 ({/Times-Italic p}_{ }=2)", \
    "hex.struct.ho.N2.alpha.1.summary.txt" u ((volume/$4)**(1.0/3.0)*1e3):($5*1e6) w lp ls 222  title "{/Symbol a}=1 ({/Times-Italic p}_{ }=2)", \
    "hex.struct.ho.N3.alpha.0.001.summary.txt" u ((volume/$4)**(1.0/3.0)*1e3):($5*1e6) w lp ls 30  title "{/Symbol a}=0.001 ({/Times-Italic p}_{ }=3)", \
    "hex.struct.ho.N3.alpha.0.01.summary.txt" u ((volume/$4)**(1.0/3.0)*1e3):($5*1e6) w lp ls 3  title "{/Symbol a}=0.01 ({/Times-Italic p}_{ }=3)", \
    "hex.struct.ho.N3.alpha.0.1.summary.txt" u ((volume/$4)**(1.0/3.0)*1e3):($5*1e6) w lp ls 33  title "{/Symbol a}=0.1 ({/Times-Italic p}_{ }=3)", \
    "hex.struct.ho.N3.alpha.1.summary.txt" u ((volume/$4)**(1.0/3.0)*1e3):($5*1e6) w lp ls 333  title "{/Symbol a}=1 ({/Times-Italic p}_{ }=3)"


set output "mms_3D_alpha_disp_ho-tet_unstruct.pdf"
plot \
    "tet.unstruct.ho.N1.alpha.0.001.summary.txt" u ((8.48528*(volume/$4))**(1.0/3.0)*1e3):($5*1e6) w lp ls 10  title "{/Symbol a}=0.001 ({/Times-Italic p}_{ }=1)", \
    "tet.unstruct.ho.N1.alpha.0.01.summary.txt" u ((8.48528*(volume/$4))**(1.0/3.0)*1e3):($5*1e6) w lp ls 1  title "{/Symbol a}=0.01 ({/Times-Italic p}_{ }=1)", \
    "tet.unstruct.ho.N1.alpha.0.1.summary.txt" u ((8.48528*(volume/$4))**(1.0/3.0)*1e3):($5*1e6) w lp ls 11  title "{/Symbol a}=0.1 ({/Times-Italic p}_{ }=1)", \
    "tet.unstruct.ho.N1.alpha.1.summary.txt" u ((8.48528*(volume/$4))**(1.0/3.0)*1e3):($5*1e6) w lp ls 111  title "{/Symbol a}=1 ({/Times-Italic p}_{ }=1)", \
    "tet.unstruct.ho.N2.alpha.0.001.summary.txt" u ((8.48528*(volume/$4))**(1.0/3.0)*1e3):($5*1e6) w lp ls 20  title "{/Symbol a}=0.001 ({/Times-Italic p}_{ }=2)", \
    "tet.unstruct.ho.N2.alpha.0.01.summary.txt" u ((8.48528*(volume/$4))**(1.0/3.0)*1e3):($5*1e6) w lp ls 2  title "{/Symbol a}=0.01 ({/Times-Italic p}_{ }=2)", \
    "tet.unstruct.ho.N2.alpha.0.1.summary.txt" u ((8.48528*(volume/$4))**(1.0/3.0)*1e3):($5*1e6) w lp ls 22  title "{/Symbol a}=0.1 ({/Times-Italic p}_{ }=2)", \
    "tet.unstruct.ho.N2.alpha.1.summary.txt" u ((8.48528*(volume/$4))**(1.0/3.0)*1e3):($5*1e6) w lp ls 222  title "{/Symbol a}=1 ({/Times-Italic p}_{ }=2)", \
    "tet.unstruct.ho.N3.alpha.0.001.summary.txt" u ((8.48528*(volume/$4))**(1.0/3.0)*1e3):($6*1e6) w lp ls 30  title "{/Symbol a}=0.01 ({/Times-Italic p}_{ }=3)" ,\
    "tet.unstruct.ho.N3.alpha.0.01.summary.txt" u ((8.48528*(volume/$4))**(1.0/3.0)*1e3):($6*1e6) w lp ls 3  title "{/Symbol a}=0.01 ({/Times-Italic p}_{ }=3)" ,\
    "tet.unstruct.ho.N3.alpha.0.1.summary.txt" u ((8.48528*(volume/$4))**(1.0/3.0)*1e3):($6*1e6) w lp ls 33  title "{/Symbol a}=0.1 ({/Times-Italic p}_{ }=3)" ,\
    "tet.unstruct.ho.N3.alpha.1.summary.txt" u ((8.48528*(volume/$4))**(1.0/3.0)*1e3):($6*1e6) w lp ls 333  title "{/Symbol a}=1 ({/Times-Italic p}_{ }=3)"


set grid
set xrange[0.3:1000]
set yrange [1e-7:0.1]
set xtics 10
set mxtics 10
set mxtics 5
set ytics
set logscale x
set logscale y
set format y "10^{%L}"
#set ytics 0.002
set xlabel "Time (in s)"
set ylabel "{/Times-Italic L}_{ 2} error (in μm)"

set output "mms_3D_alpha_efficiency_hex_struct.pdf"
plot \
    "hex.struct.ho.N1.alpha.0.001.summary.txt" u 2:($5*1e6) w lp ls 10  title "{/Symbol a}=0.001 ({/Times-Italic p}_{ }=1)", \
    "hex.struct.ho.N1.alpha.0.01.summary.txt" u 2:($5*1e6) w lp ls 1  title "{/Symbol a}=0.01 ({/Times-Italic p}_{ }=1)", \
    "hex.struct.ho.N1.alpha.0.1.summary.txt" u 2:($5*1e6) w lp ls 11  title "{/Symbol a}=0.1 ({/Times-Italic p}_{ }=1)", \
    "hex.struct.ho.N1.alpha.1.summary.txt" u 2:($5*1e6) w lp ls 111  title "{/Symbol a}=1 ({/Times-Italic p}_{ }=1)", \
    "hex.struct.ho.N2.alpha.0.001.summary.txt" u 2:($5*1e6) w lp ls 20  title "{/Symbol a}=0.001 ({/Times-Italic p}_{ }=2)", \
    "hex.struct.ho.N2.alpha.0.01.summary.txt" u 2:($5*1e6) w lp ls 2  title "{/Symbol a}=0.01 ({/Times-Italic p}_{ }=2)", \
    "hex.struct.ho.N2.alpha.0.1.summary.txt" u 2:($5*1e6) w lp ls 22  title "{/Symbol a}=0.1 ({/Times-Italic p}_{ }=2)", \
    "hex.struct.ho.N2.alpha.1.summary.txt" u 2:($5*1e6) w lp ls 222  title "{/Symbol a}=1 ({/Times-Italic p}_{ }=2)", \
    "hex.struct.ho.N3.alpha.0.001.summary.txt" u 2:($5*1e6) w lp ls 30 title "{/Symbol a}=0.001 ({/Times-Italic p}_{ }=3)",\
    "hex.struct.ho.N3.alpha.0.01.summary.txt" u 2:($5*1e6) w lp ls 3  title "{/Symbol a}=0.01 ({/Times-Italic p}_{ }=3)",\
    "hex.struct.ho.N3.alpha.0.1.summary.txt" u 2:($5*1e6) w lp ls 33  title "{/Symbol a}=0.1 ({/Times-Italic p}_{ }=3)",\
    "hex.struct.ho.N3.alpha.1.summary.txt" u 2:($5*1e6) w lp ls 333  title "{/Symbol a}1 ({/Times-Italic p}_{ }=3)"

set output "mms_3D_alpha_efficiency_tet_unstruct.pdf"
set yrange [8e-8:0.1]
set xrange[0.3:10000]
plot \
    "tet.unstruct.ho.N1.alpha.0.001.summary.txt" u 2:($5*1e6) w lp ls 10  title "{/Symbol a}=0.001 ({/Times-Italic p}_{ }=1)", \
    "tet.unstruct.ho.N1.alpha.0.01.summary.txt" u 2:($5*1e6) w lp ls 1  title "{/Symbol a}=0.01 ({/Times-Italic p}_{ }=1)", \
    "tet.unstruct.ho.N1.alpha.0.1.summary.txt" u 2:($5*1e6) w lp ls 11  title "{/Symbol a}=0.1 ({/Times-Italic p}_{ }=1)", \
    "tet.unstruct.ho.N1.alpha.1.summary.txt" u 2:($5*1e6) w lp ls 111  title "{/Symbol a}=1 ({/Times-Italic p}_{ }=1)", \
    "tet.unstruct.ho.N2.alpha.0.001.summary.txt" u 2:($5*1e6) w lp ls 20  title "{/Symbol a}=0.001 ({/Times-Italic p}_{ }=2)", \
    "tet.unstruct.ho.N2.alpha.0.01.summary.txt" u 2:($5*1e6) w lp ls 2  title "{/Symbol a}=0.01 ({/Times-Italic p}_{ }=2)", \
    "tet.unstruct.ho.N2.alpha.0.1.summary.txt" u 2:($5*1e6) w lp ls 22  title "{/Symbol a}=0.1 ({/Times-Italic p}_{ }=2)", \
    "tet.unstruct.ho.N2.alpha.1.summary.txt" u 2:($5*1e6) w lp ls 222  title "{/Symbol a}=1 ({/Times-Italic p}_{ }=2)", \
    "tet.unstruct.ho.N3.alpha.0.001.summary.txt" u 2:($5*1e6) w lp ls 30  title "{/Symbol a}=0.001 ({/Times-Italic p}_{ }=3)",\
    "tet.unstruct.ho.N3.alpha.0.01.summary.txt" u 2:($5*1e6) w lp ls 3  title "{/Symbol a}=0.01 ({/Times-Italic p}_{ }=3)",\
    "tet.unstruct.ho.N3.alpha.0.1.summary.txt" u 2:($5*1e6) w lp ls 33  title "{/Symbol a}=0.1 ({/Times-Italic p}_{ }=3)",\
    "tet.unstruct.ho.N3.alpha.1.summary.txt" u 2:($5*1e6) w lp ls 333  title "{/Symbol a}1 ({/Times-Italic p}_{ }=3)"