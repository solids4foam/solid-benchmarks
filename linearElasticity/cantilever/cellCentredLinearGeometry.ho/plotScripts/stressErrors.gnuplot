set term pdfcairo dashed enhanced
set datafile separator " "

#set size ratio 1

set grid
set xrange [25:1000]
set yrange [1e-5:5]
set xtics
set xtics add (5, 25, 50)
set ytics
set logscale x
set logscale y
set format y "10^{%L}"
#set ytics 0.002
set xlabel "Average cell edge (in mm)"
set ylabel "Error (in Pa)"
#set key left top;
set key right bottom;

#set label "1^{st} order" at graph 0.5,0.86 center rotate by 10
#set label "2^{nd} order" at graph 0.5,0.37 center rotate by 25


set output "mms_stressErrors_ho-hex.pdf"
set title "Hexahedral structured mesh"
plot \
    (2e-3 * x) w l lw 2 dt 2 lc "red" notitle,\
    (0.15e-5 * x**2) w l lw 2 dt 2 lc "blue" notitle,\
    (0.1e-8 * x**3) w l lw 2 dt 2 lc "violet" notitle,\
    "hex.struct.hypre-snes.summary.txt" u ((1/$4)**0.5*1e3):($7) w lp ps 0.5 pt 5 lc "slategrey" t "L_2 - S4F (SNES)", \
    "hex.struct.hypre-snes.summary.txt" u ((1/$4)**0.5*1e3):($8) w lp ps 0.5 pt 4 lc "slategrey" t "L_∞ - S4F (SNES)", \
    "hex.struct.seg.summary.txt" u ((1/$4)**0.5*1e3):($7) w lp ps 0.5 pt 5 lc "black" t "L_2 - S4F (SEG)", \
    "hex.struct.seg.summary.txt" u ((1/$4)**0.5*1e3):($8) w lp ps 0.5 pt 4 lc  "black" t "L_∞ - S4F (SEG)", \
    "hex.struct.ho.N1.summary.txt" u ((1/$4)**0.5*1e3):($7) w lp ps 0.5 pt 5 lc "red" t "L_2 - N1", \
    "hex.struct.ho.N1.summary.txt" u ((1/$4)**0.5*1e3):($8) w lp ps 0.5 pt 4 lc "red" t "L_∞ - N1", \
    "hex.struct.ho.N2.summary.txt" u ((1/$4)**0.5*1e3):($7) w lp ps 0.5 pt 5 lc "blue" t "L_2 - N2", \
    "hex.struct.ho.N2.summary.txt" u ((1/$4)**0.5*1e3):($8) w lp ps 0.5 pt 4 lc "blue" t "L_∞ - N2", \
    "hex.struct.ho.N3.summary.txt" u ((1/$4)**0.5*1e3):($7) w lp ps 0.5 pt 5 lc "violet" t "L_2 - N3", \
    "hex.struct.ho.N3.summary.txt" u ((1/$4)**0.5*1e3):($8) w lp ps 0.5 pt 4 lc "violet" t "L_∞ - N3"

set output "mms_stressErrors_ho-tet-struct.pdf"
set title "Tetrahedral structured mesh"
plot \
    (2e-3 * x) w l lw 2 dt 2 lc "red" notitle,\
    (0.15e-5 * x**2) w l lw 2 dt 2 lc "blue" notitle,\
    (0.1e-8 * x**3) w l lw 2 dt 2 lc "violet" notitle,\
    "tet.struct.hypre-snes.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($7) w lp ps 0.5 pt 7 lc "slategrey" t "L_2 - S4F (SNES)", \
    "tet.struct.hypre-snes.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($8) w lp ps 0.5 pt 6 lc "slategrey" t "L_∞ - S4F (SNES)", \
    "tet.struct.seg.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($7) w lp ps 0.5 pt 7 lc "black" t "L_2 - S4F (SEG)", \
    "tet.struct.seg.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($8) w lp ps 0.5 pt 6 lc "black" t "L_∞ - S4F (SEG)", \
    "tet.struct.ho.N1.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($7) w lp ps 0.5 pt 7 lc "red" t "L_2 - N1", \
    "tet.struct.ho.N1.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($8) w lp ps 0.5 pt 6 lc "red" t "L_∞ - N1", \
    "tet.struct.ho.N2.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($7) w lp ps 0.5 pt 7 lc "blue" t "L_2 - N2", \
    "tet.struct.ho.N2.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($8) w lp ps 0.5 pt 6 lc "blue" t "L_∞ - N2", \
    "tet.struct.ho.N3.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($7) w lp ps 0.5 pt 7 lc "violet" t "L_2 - N3", \
    "tet.struct.ho.N3.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($8) w lp ps 0.5 pt 6 lc "violet" t "L_∞ - N3"

set output "mms_stressErrors_ho-tet-unstruct_v1.pdf"
set title"Tetrahedral unstructured-v1 mesh"
plot \
    (2e-3 * x) w l lw 2 dt 2 lc "red" notitle,\
    (0.15e-5 * x**2) w l lw 2 dt 2 lc "blue" notitle,\
    (0.1e-8 * x**3) w l lw 2 dt 2 lc "violet" notitle,\
    "tet.unstruct_v1.hypre-snes.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($7) w lp ps 0.5 pt 9 lc "slategrey" t "L_2 - S4F (SNES)", \
    "tet.unstruct_v1.hypre-snes.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($8) w lp ps 0.5 pt 8 lc "slategrey" t "L_∞ - S4F (SNES)", \
    "tet.unstruct_v1.seg.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($7) w lp ps 0.5 pt 9 lc "black" t "L_2 - S4F (SEG)", \
    "tet.unstruct_v1.seg.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($8) w lp ps 0.5 pt 8 lc "black" t "L_∞ - S4F (SEG)", \
    "tet.unstruct_v1.ho.N1.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($7) w lp ps 0.5 pt 9 lc "red" t "L_2 - N1", \
    "tet.unstruct_v1.ho.N1.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($8) w lp ps 0.5 pt 8 lc "red" t "L_∞ - N1", \
    "tet.unstruct_v1.ho.N2.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($7) w lp ps 0.5 pt 9 lc "blue" t "L_2 - N2", \
    "tet.unstruct_v1.ho.N2.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($8) w lp ps 0.5 pt 8 lc "blue" t "L_∞ - N2", \
    "tet.unstruct_v1.ho.N3.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($7) w lp ps 0.5 pt 9 lc "violet" t "L_2 - N3", \
    "tet.unstruct_v1.ho.N3.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($8) w lp ps 0.5 pt 8 lc "violet" t "L_∞ - N3"

set output "mms_stressErrors_ho-tet-unstruct_v2.pdf"
set title"Tetrahedral unstructured-v2 mesh"
plot \
    (2e-3 * x) w l lw 2 dt 2 lc "red" notitle,\
    (0.15e-5 * x**2) w l lw 2 dt 2 lc "blue" notitle,\
    (0.1e-8 * x**3) w l lw 2 dt 2 lc "violet" notitle,\
    "tet.unstruct_v2.hypre-snes.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($7) w lp ps 0.5 pt 9 lc "slategrey" t "L_2 - S4F (SNES)", \
    "tet.unstruct_v2.hypre-snes.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($8) w lp ps 0.5 pt 8 lc "slategrey" t "L_∞ - S4F (SNES)", \
    "tet.unstruct_v2.seg.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($7) w lp ps 0.5 pt 9 lc "black" t "L_2 - S4F (SEG)", \
    "tet.unstruct_v2.seg.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($8) w lp ps 0.5 pt 8 lc "black" t "L_∞ - S4F (SEG)", \
    "tet.unstruct_v2.ho.N1.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($7) w lp ps 0.5 pt 9 lc "red" t "L_2 - N1", \
    "tet.unstruct_v2.ho.N1.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($8) w lp ps 0.5 pt 8 lc "red" t "L_∞ - N1", \
    "tet.unstruct_v2.ho.N2.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($7) w lp ps 0.5 pt 9 lc "blue" t "L_2 - N2", \
    "tet.unstruct_v2.ho.N2.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($8) w lp ps 0.5 pt 8 lc "blue" t "L_∞ - N2", \
    "tet.unstruct_v2.ho.N3.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($7) w lp ps 0.5 pt 9 lc "violet" t "L_2 - N3", \
    "tet.unstruct_v2.ho.N3.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($8) w lp ps 0.5 pt 8 lc "violet" t "L_∞ - N3"
