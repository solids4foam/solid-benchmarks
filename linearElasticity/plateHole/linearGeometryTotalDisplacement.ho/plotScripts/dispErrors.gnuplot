set term pdfcairo dashed enhanced size 3.5,2

set datafile separator " "

area = 3.803650459

#set size ratio 1

set grid
set xrange [5:150]
set yrange [1e-8:1]
set xtics
set xtics add (5, 25, 50)
set ytics
set logscale x
set logscale y
set format y "10^{%L}"
#set ytics 0.002
set xlabel "Average cell edge (in mm)"
set ylabel "Error (in μm)"
#set key left top;
set key right bottom;

#set label "1^{st} order" at graph 0.5,0.86 center rotate by 10
#set label "2^{nd} order" at graph 0.5,0.37 center rotate by 25

set output "plateHole-dispErrors_hex.pdf"
#set title "Hexahedral structured mesh"
plot \
    (4e-6 * x**2) w l lw 2 dt 2 lc "red" notitle,\
    (2e-8 * x**3) w l lw 2 dt 2 lc "blue" notitle,\
    (8e-11 * x**4) w l lw 2 dt 2 lc "violet" notitle,\
    "hex.seg.summary.txt" u ((area/$4)**0.5*1e3):($5*1e6) w lp ps 0.5 pt 5 lc "black" t "L_2 - S4F", \
    "hex.seg.summary.txt" u ((area/$4)**0.5*1e3):($6*1e6) w lp ps 0.5 pt 4 lc  "black" t "L_∞ - S4F", \
    "hex.ho.N1.summary.txt" u ((area/$4)**0.5*1e3):($5*1e6) w lp ps 0.5 pt 5 lc "red" t "L_2 - N1", \
    "hex.ho.N1.summary.txt" u ((area/$4)**0.5*1e3):($6*1e6) w lp ps 0.5 pt 4 lc "red" t "L_∞ - N1", \
    "hex.ho.N2.summary.txt" u ((area/$4)**0.5*1e3):($5*1e6) w lp ps 0.5 pt 5 lc "blue" t "L_2 - N2", \
    "hex.ho.N2.summary.txt" u ((area/$4)**0.5*1e3):($6*1e6) w lp ps 0.5 pt 4 lc "blue" t "L_∞ - N2", \
    "hex.ho.N3.summary.txt" u ((area/$4)**0.5*1e3):($5*1e6) w lp ps 0.5 pt 5 lc "violet" t "L_2 - N3", \
    "hex.ho.N3.summary.txt" u ((area/$4)**0.5*1e3):($6*1e6) w lp ps 0.5 pt 4 lc "violet" t "L_∞ - N3"

set output "plateHole-dispErrors_tet-unstruct.pdf"
#set title"Tetrahedral unstructured mesh"
plot \
    (4e-6 * x**2) w l lw 2 dt 2 lc "red" notitle,\
    (2e-8 * x**3) w l lw 2 dt 2 lc "blue" notitle,\
    (8e-11 * x**4) w l lw 2 dt 2 lc "violet" notitle,\
    "tet.seg.summary.txt" u ((4*(area/$4)/3**0.5)**0.5*1e3):($5*1e6) w lp ps 0.5 pt 9 lc "black" t "L_2 - S4F", \
    "tet.seg.summary.txt" u ((4*(area/$4)/3**0.5)**0.5*1e3):($6*1e6) w lp ps 0.5 pt 8 lc "black" t "L_∞ - S4F", \
    "tet.ho.N1.summary.txt" u ((4*(area/$4)/3**0.5)**0.5*1e3):($5*1e6) w lp ps 0.5 pt 9 lc "red" t "L_2 - N1", \
    "tet.ho.N1.summary.txt" u ((4*(area/$4)/3**0.5)**0.5*1e3):($6*1e6) w lp ps 0.5 pt 8 lc "red" t "L_∞ - N1", \
    "tet.ho.N2.summary.txt" u ((4*(area/$4)/3**0.5)**0.5*1e3):($5*1e6) w lp ps 0.5 pt 9 lc "blue" t "L_2 - N2", \
    "tet.ho.N2.summary.txt" u ((4*(area/$4)/3**0.5)**0.5*1e3):($6*1e6) w lp ps 0.5 pt 8 lc "blue" t "L_∞ - N2", \
    "tet.ho.N3.summary.txt" u ((4*(area/$4)/3**0.5)**0.5*1e3):($5*1e6) w lp ps 0.5 pt 9 lc "violet" t "L_2 - N3", \
    "tet.ho.N3.summary.txt" u ((4*(area/$4)/3**0.5)**0.5*1e3):($6*1e6) w lp ps 0.5 pt 8 lc "violet" t "L_∞ - N3"