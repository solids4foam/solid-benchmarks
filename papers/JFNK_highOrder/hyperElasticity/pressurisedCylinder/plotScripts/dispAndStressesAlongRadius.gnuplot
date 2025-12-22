set term pdfcairo dashed enhanced size 3.25, 2
set datafile separator " "

set grid
set xrange [7:18.625]
set xtics
set ytics
#set logscale x
#set logscale y
#set format y "10^{%L}"
#set ytics 0.002
set xlabel "Radius (in m)"

#set key left top;
#set key right bottom;
set key right bottom outside;
set rmargin 13
set key spacing 1.2


set style line 1 lc rgb "red"    pt 7 ps 0.4 lw 1
set style line 2 lc rgb "blue"   pt 5 ps 0.4 lw 1
set style line 3 lc rgb "violet" pt 9 ps 0.6 lw 1
set style line 4 lc rgb "black" pt 4 ps 0.5 lw 1 dt "......."
set style line 5 lc rgb "grey" pt 8 ps 0.5 lw 1

set arrow from graph 0, first 0 to graph 1, first 0 nohead lc rgb "black" lw 1
set label 2 "Hoop stress" at graph 0.6, 0.6 rotate by 0
set label 3 "Radial stress" at graph 0.6, 0.2 rotate by 0
set ylabel "Stress (in MPa)"

set yrange [-110:250]
set rmargin 16
set output "pressurisedCylinder_stress.pdf"
plot \
     "hoop_stress_Bijelonja.dat" u 1:2 w l ls 4 title "Analytical",\
     "radial_stress_Bijelonja.dat" u 1:2 w l ls 4 notitle,\
     "filteredSigmaTransformed_p1.3.dat" u (sqrt($1**2+$2**2)):($10*1e-6) w lp ls 1 pointinterval 7 title "{/Times-Italic p}_{ }=1",\
     "filteredSigmaTransformed_p1.3.dat" u (sqrt($1**2+$2**2)):($7*1e-6) w lp ls 1  pointinterval 7 notitle,\
     "filteredSigmaTransformed_p2.3.dat" u (sqrt($1**2+$2**2)):($10*1e-6)  w lp ls 2  pointinterval 7 title "{/Times-Italic p}_{ }=2",\
     "filteredSigmaTransformed_p2.3.dat" u (sqrt($1**2+$2**2)):($7*1e-6) w lp ls 2  pointinterval 7 notitle,\
     "filteredSigmaTransformed_p3.3.dat" u (sqrt($1**2+$2**2)):($10*1e-6)  w lp ls 3  pointinterval 7 title "{/Times-Italic p}_{ }=3",\
     "filteredSigmaTransformed_p3.3.dat" u (sqrt($1**2+$2**2)):($7*1e-6)  w lp ls 3  pointinterval 7 notitle

set output


set ylabel "Displacement (in m)"

set style line 11 lc rgb "red"    pt 6 ps 0.5 lw 1
set style line 111 lc rgb "red"    pt 6 ps 0.35 lw 1
set style line 1111 lc rgb "red"    pt 6 ps 0.3 lw 1

set style line 21 lc rgb "blue"   pt 4 ps 0.5 lw 1
set style line 221 lc rgb "blue"   pt 4 ps 0.35 lw 1
set style line 2221 lc rgb "blue"   pt 4 ps 0.3 lw 1

set style line 31 lc rgb "violet" pt 8 ps 0.5 lw 1
set style line 331 lc rgb "violet" pt 8 ps 0.35 lw 1
set style line 3331 lc rgb "violet" pt 8 ps 0.3 lw 1

set style line 12 lc rgb "red"    pt 6 ps 0.4 lw 1
set style line 22 lc rgb "blue"   pt 4 ps 0.4 lw 1
set style line 32 lc rgb "violet" pt 8 ps 0.6 lw 1



set output "pressurisedCylinder_disp.pdf"
unset label 2
unset label 3
set multiplot
set origin 0,0
set yrange [2:4]
set object 10 rect from 10,2.6 to 12,3.4 fc rgb "red" fs empty border lw 1 lc rgb "red"

plot "filteredSigmaTransformed_p1.1.dat" u (sqrt($1**2+$2**2)):(sqrt($4**2+$5**2)) w lp ls 11 title "{/Times-Italic p}_{ }=1, M1",\
     "filteredSigmaTransformed_p1.2.dat" u (sqrt($1**2+$2**2)):(sqrt($4**2+$5**2)) w lp ls 111 title "{/Times-Italic p}_{ }=1, M2",\
     "filteredSigmaTransformed_p1.3.dat" u (sqrt($1**2+$2**2)):(sqrt($4**2+$5**2)) w lp ls 1111 title "{/Times-Italic p}_{ }=1, M3",\
     "filteredSigmaTransformed_p2.1.dat" u (sqrt($1**2+$2**2)):(sqrt($4**2+$5**2)) w lp ls 21 title "{/Times-Italic p}_{ }=2, M1",\
     "filteredSigmaTransformed_p2.2.dat" u (sqrt($1**2+$2**2)):(sqrt($4**2+$5**2)) w lp ls 221 title "{/Times-Italic p}_{ }=2, M2",\
     "filteredSigmaTransformed_p2.3.dat" u (sqrt($1**2+$2**2)):(sqrt($4**2+$5**2)) w lp ls 2221 title "{/Times-Italic p}_{ }=2, M3",\
     "filteredSigmaTransformed_p3.1.dat" u (sqrt($1**2+$2**2)):(sqrt($4**2+$5**2)) w lp ls 31 title "{/Times-Italic p}_{ }=3, M1",\
     "filteredSigmaTransformed_p3.2.dat" u (sqrt($1**2+$2**2)):(sqrt($4**2+$5**2)) w lp ls 331 title "{/Times-Italic p}_{ }=3, M2",\
     "filteredSigmaTransformed_p3.3.dat" u (sqrt($1**2+$2**2)):(sqrt($4**2+$5**2)) w lp ls 3331 title "{/Times-Italic p}_{ }=3, M3"

set size 0.2,0.2
set origin 0.85,0.4

set lmargin at screen 0.5
set rmargin at screen 0.67
set bmargin at screen 0.6
set tmargin at screen 0.92

set ytics nomirror
unset y2tics
set ytics ("2.6" 2.6, "3.4" 3.4)

set xtics ("10" 10, "12" 12)
set yrange [2.6:3.4]
set grid
set xrange [10:12]
unset key
#set boxwidth 0.1
set border lw 1.5 lc rgb "red"
unset xlabel
unset ylabel
unset y2tics
unset y2label
set xtics textcolor rgb "black"
set ytics textcolor rgb "black"



plot "filteredSigmaTransformed_p1.1.dat" u (sqrt($1**2+$2**2)):(sqrt($4**2+$5**2)) w lp ls 11 title "{/Times-Italic p}_{ }=1",\
     "filteredSigmaTransformed_p1.2.dat" u (sqrt($1**2+$2**2)):(sqrt($4**2+$5**2)) w lp ls 111 title "{/Times-Italic p}_{ }=1",\
     "filteredSigmaTransformed_p1.3.dat" u (sqrt($1**2+$2**2)):(sqrt($4**2+$5**2)) w lp ls 1111 title "{/Times-Italic p}_{ }=1",\
     "filteredSigmaTransformed_p2.1.dat" u (sqrt($1**2+$2**2)):(sqrt($4**2+$5**2)) w lp ls 21 title "{/Times-Italic p}_{ }=2",\
     "filteredSigmaTransformed_p2.3.dat" u (sqrt($1**2+$2**2)):(sqrt($4**2+$5**2)) w lp ls 2221 title "{/Times-Italic p}_{ }=2",\
     "filteredSigmaTransformed_p2.2.dat" u (sqrt($1**2+$2**2)):(sqrt($4**2+$5**2)) w lp ls 221 title "{/Times-Italic p}_{ }=2",\
     "filteredSigmaTransformed_p3.1.dat" u (sqrt($1**2+$2**2)):(sqrt($4**2+$5**2)) w lp ls 31 title "{/Times-Italic p}_{ }=3",\
     "filteredSigmaTransformed_p3.2.dat" u (sqrt($1**2+$2**2)):(sqrt($4**2+$5**2)) w lp ls 331 title "{/Times-Italic p}_{ }=3",\
     "filteredSigmaTransformed_p3.3.dat" u (sqrt($1**2+$2**2)):(sqrt($4**2+$5**2)) w lp ls 3331 title "{/Times-Italic p}_{ }=3"
