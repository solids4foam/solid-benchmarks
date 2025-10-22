set term pdfcairo dashed enhanced size 3.5,2

set datafile separator " "

area = 233.9627498

#set size ratio 1

set grid
set xrange [0.05:3]
set yrange [1e-11:1e-3]
set xtics
set xtics add (0.1, 1, 2)
set ytics
set key r bottom
set logscale x
set logscale y
set format y "10^{%L}"
#set ytics 0.002
set xlabel "Average cell edge (in m)"
set ylabel "Error (in m)"
set key right bottom outside;
set rmargin 18

#set label "1^{st} order" at graph 0.5,0.86 center rotate by 10
#set label "2^{nd} order" at graph 0.5,0.37 center rotate by 25

set output "pressurisedCylinder-dispErrors_hex.pdf"
#set title "Hexahedral structured mesh"
plot \
    (2e-5 * x**2) w l lw 2 dt 2 lc "red" notitle,\
    (4e-6 * x**3) w l lw 2 dt 2 lc "blue" notitle,\
    (6e-7 * x**4) w l lw 2 dt 2 lc "violet" notitle,\
    "hex.struct.hypre-snes.summary.txt" u ((area/$4)**0.5):($5) w lp ps 0.5 pt 4 lc "slategrey" t "L_2 - S4F_{SNES}", \
    "hex.struct.hypre-snes.summary.txt" u ((area/$4)**0.5):($6) w lp ps 0.5 pt 5 lc "slategrey" t "L_∞ - S4F_{SNES}", \
    "hex.struct.seg.summary.txt" u ((area/$4)**0.5):($5) w lp ps 0.5 pt 4 lc "black" t "L_2 - S4F_{SEG}", \
    "hex.struct.seg.summary.txt" u ((area/$4)**0.5):($6) w lp ps 0.5 pt 5 lc  "black" t "L_∞ - S4F_{SEG}", \
    "hex.struct.ho.N1.summary.txt" u ((area/$4)**0.5):($5) w lp ps 0.5 pt 4 lc "red" t "L_2 - N1", \
    "hex.struct.ho.N1.summary.txt" u ((area/$4)**0.5):($6) w lp ps 0.5 pt 5 lc "red" t "L_∞ - N1", \
    "hex.struct.ho.N2.summary.txt" u ((area/$4)**0.5):($5) w lp ps 0.5 pt 4 lc "blue" t "L_2 - N2", \
    "hex.struct.ho.N2.summary.txt" u ((area/$4)**0.5):($6) w lp ps 0.5 pt 5 lc "blue" t "L_∞ - N2", \
    "hex.struct.ho.N3.summary.txt" u ((area/$4)**0.5):($5) w lp ps 0.5 pt 4 lc "violet" t "L_2 - N3", \
    "hex.struct.ho.N3.summary.txt" u ((area/$4)**0.5):($6) w lp ps 0.5 pt 5 lc "violet" t "L_∞ - N3"

set output "pressurisedCylinder-dispErrors_tet.pdf"
#set title"Tetrahedral unstructured mesh"
plot \
    (2e-5 * x**2) w l lw 2 dt 2 lc "red" notitle,\
    (4e-6 * x**3) w l lw 2 dt 2 lc "blue" notitle,\
    (6e-7 * x**4) w l lw 2 dt 2 lc "violet" notitle,\
    "tet.unstruct.hypre-snes.summary.txt" u ((4*(area/$4)/3**0.5)**0.5):($5) w lp ps 0.5 pt 9 lc "slategrey" t "L_2 - S4F_{SNES}", \
    "tet.unstruct.hypre-snes.summary.txt" u ((4*(area/$4)/3**0.5)**0.5):($6) w lp ps 0.5 pt 8 lc "slategrey" t "L_∞ - S4F_{SNES}", \
    "tet.unstruct.seg.summary.txt" u ((4*(area/$4)/3**0.5)**0.5):($5) w lp ps 0.5 pt 9 lc "black" t "L_2 - S4F_{SEG}", \
    "tet.unstruct.seg.summary.txt" u ((4*(area/$4)/3**0.5)**0.5):($6) w lp ps 0.5 pt 8 lc "black" t "L_∞ - S4F_{SEG}", \
    "tet.unstruct.ho.N1.summary.txt" u ((4*(area/$4)/3**0.5)**0.5):($5) w lp ps 0.5 pt 9 lc "red" t "L_2 - N1", \
    "tet.unstruct.ho.N1.summary.txt" u ((4*(area/$4)/3**0.5)**0.5):($6) w lp ps 0.5 pt 8 lc "red" t "L_∞ - N1", \
    "tet.unstruct.ho.N2.summary.txt" u ((4*(area/$4)/3**0.5)**0.5):($5) w lp ps 0.5 pt 9 lc "blue" t "L_2 - N2", \
    "tet.unstruct.ho.N2.summary.txt" u ((4*(area/$4)/3**0.5)**0.5):($6) w lp ps 0.5 pt 8 lc "blue" t "L_∞ - N2", \
    "tet.unstruct.ho.N3.summary.txt" u ((4*(area/$4)/3**0.5)**0.5):($5) w lp ps 0.5 pt 9 lc "violet" t "L_2 - N3", \
    "tet.unstruct.ho.N3.summary.txt" u ((4*(area/$4)/3**0.5)**0.5):($6) w lp ps 0.5 pt 8 lc "violet" t "L_∞ - N3"