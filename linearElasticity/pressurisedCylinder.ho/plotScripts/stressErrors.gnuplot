set term pdfcairo dashed enhanced size 3.5,2
set datafile separator " "

#set size ratio 1
area = 233.9627498

set grid
set xrange [0.05:2]
set yrange [1e-6:10]
set xtics
set xtics add (1, 2, 3)
set ytics
set logscale x
set logscale y
set format y "10^{%L}"
#set ytics 0.002
set xlabel "Average cell edge (in m)"
set ylabel "Error (in MPa)"
#set key r b;
set key right bottom outside;
set rmargin 18

#set label "1^{st} order" at graph 0.5,0.86 center rotate by 10
#set label "2^{nd} order" at graph 0.5,0.37 center rotate by 25


set output "pressurisedCylinder-stressErrors_hex.pdf"
#set title "Hexahedral structured mesh"
plot \
    (0.2 * x**1) w l lw 2 dt 2 lc "red" notitle,\
    (2e-5 * x**2) w l lw 2 dt 2 lc "blue" notitle,\
    "hex.struct.hypre-snes.summary.txt" u ((area/$4)**0.5):($7*1e-6) w lp ps 0.5 pt 5 lc "slategrey" t "L_2 - S4F_{SNES}", \
    "hex.struct.hypre-snes.summary.txt" u ((area/$4)**0.5):($8*1e-6) w lp ps 0.5 pt 4 dt 8 lc "slategrey" t "L_∞ - S4F_{SNES}", \
    "hex.struct.ho.N1.summary.txt" u ((area/$4)**0.5):($7*1e-6) w lp ps 0.5 pt 5 lc "red" t "L_2 - N1", \
    "hex.struct.ho.N1.summary.txt" u ((area/$4)**0.5):($8*1e-6) w lp ps 0.5 pt 4 dt 8 lc "red" t "L_∞ - N1", \
    "hex.struct.ho.N2.summary.txt" u ((area/$4)**0.5):($7*1e-6) w lp ps 0.5 pt 5 lc "blue" t "L_2 - N2", \
    "hex.struct.ho.N2.summary.txt" u ((area/$4)**0.5):($8*1e-6) w lp ps 0.5 pt 4 dt 8 lc "blue" t "L_∞  - N2", \
    "hex.struct.ho.N3.summary.txt" u ((area/$4)**0.5):($7*1e-6) w lp ps 0.2 pt 5 lc "violet" t "L_2 - N3", \
    "hex.struct.ho.N3.summary.txt" u ((area/$4)**0.5):($8*1e-6) w lp ps 0.2 pt 4 lc "violet" t "L_∞ - N3"

set output "pressurisedCylinder-stressErrors_tet.pdf"
# set title"Tetrahedral unstructured mesh"
plot \
    (0.2 * x**1) w l lw 2 dt 2 lc "red" notitle,\
    (2e-2 * x**2) w l lw 2 dt 2 lc "blue" notitle,\
    (1e-2 * x**3) w l lw 2 dt 2 lc "violet" notitle,\
    "tet.unstruct.seg.summary.txt" u ((4*(area/$4)/3**0.5)**0.5):($7*1e-6) w lp ps 0.5 pt 9 lc "black" t "L_2 - S4F_{SEG}", \
    "tet.unstruct.seg.summary.txt" u ((4*(area/$4)/3**0.5)**0.5):($8*1e-6) w lp ps 0.5 pt 8 lc "black" t "L_∞ - S4F_{SEG}", \
    "tet.unstruct.ho.N1.summary.txt" u ((4*(area/$4)/3**0.5)**0.5):($7*1e-6) w lp ps 0.5 pt 9 lc "red" t "L_2 - N1", \
    "tet.unstruct.ho.N1.summary.txt" u ((4*(area/$4)/3**0.5)**0.5):($8*1e-6) w lp ps 0.5 pt 8 dt 8 lc "red" t "L_∞  - N1", \
    "tet.unstruct.ho.N2.summary.txt" u ((4*(area/$4)/3**0.5)**0.5):($7*1e-6) w lp ps 0.5 pt 9 lc "blue" t "L_2 - N2", \
    "tet.unstruct.ho.N2.summary.txt" u ((4*(area/$4)/3**0.5)**0.5):($8*1e-6) w lp ps 0.5 pt 8 dt 8 lc "blue" t "L_∞  - N2", \
    "tet.unstruct.ho.N3.summary.txt" u ((4*(area/$4)/3**0.5)**0.5):($7*1e-6) w lp ps 0.5 pt 9 lc "violet" t "L_2 - N3", \
    "tet.unstruct.ho.N3.summary.txt" u ((4*(area/$4)/3**0.5)**0.5):($8*1e-6) w lp ps 0.5 pt 8 dt 8 lc "violet" t "L_∞  - N3"
