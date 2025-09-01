set term pdfcairo dashed enhanced size 3.5,2

set datafile separator " "

beamArea = 0.2

#set size ratio 1

set grid
set xrange [5:55]
set yrange [1e-14:1e-2]
set xtics
set xtics add (5, 25, 50)
set ytics
set logscale x
set logscale y
set format y "10^{%L}"
#set ytics 0.002
set xlabel "Average cell edge (in mm)"
set ylabel "Error (in m)"
#set key left top;
set key right bottom;

#set label "1^{st} order" at graph 0.5,0.86 center rotate by 10
#set label "2^{nd} order" at graph 0.5,0.37 center rotate by 25

set output "dispErrors_hex.pdf"
#set title "Hexahedral structured mesh"
plot \
    (2e-6 * x**2) w l lw 2 dt 2 lc "red" notitle,\
    (4e-8 * x**3) w l lw 2 dt 2 lc "blue" notitle,\
    (8e-10 * x**4) w l lw 2 dt 2 lc "violet" notitle,\
    "hex.struct.hypre-snes.summary.txt" u ((beamArea/$4)**0.5*1e3):($5) w lp ps 0.5 pt 5 lc "slategrey" t "L_2 - S4F (SNES)", \
    "hex.struct.hypre-snes.summary.txt" u ((beamArea/$4)**0.5*1e3):($6) w lp ps 0.5 pt 4 lc "slategrey" t "L_∞ - S4F (SNES)", \
    "hex.struct.seg.summary.txt" u ((beamArea/$4)**0.5*1e3):($5) w lp ps 0.5 pt 5 lc "black" t "L_2 - S4F (SEG)", \
    "hex.struct.seg.summary.txt" u ((beamArea/$4)**0.5*1e3):($6) w lp ps 0.5 pt 4 lc  "black" t "L_∞ - S4F (SEG)", \
    "hex.struct.ho.N1.summary.txt" u ((beamArea/$4)**0.5*1e3):($5) w lp ps 0.5 pt 5 lc "red" t "L_2 - N1", \
    "hex.struct.ho.N1.summary.txt" u ((beamArea/$4)**0.5*1e3):($6) w lp ps 0.5 pt 4 lc "red" t "L_∞ - N1", \
    "hex.struct.ho.N2.summary.txt" u ((beamArea/$4)**0.5*1e3):($5) w lp ps 0.5 pt 5 lc "blue" t "L_2 - N2", \
    "hex.struct.ho.N2.summary.txt" u ((beamArea/$4)**0.5*1e3):($6) w lp ps 0.5 pt 4 lc "blue" t "L_∞ - N2", \
    "hex.struct.ho.N3.summary.txt" u ((beamArea/$4)**0.5*1e3):($5) w lp ps 0.5 pt 5 lc "violet" t "L_2 - N3", \
    "hex.struct.ho.N3.summary.txt" u ((beamArea/$4)**0.5*1e3):($6) w lp ps 0.5 pt 4 lc "violet" t "L_∞ - N3"

set output "dispErrors_tet-struct.pdf"
#set title "Tetrahedral structured mesh"
plot \
    (2e-6 * x**2) w l lw 2 dt 2 lc "red" notitle,\
    (4e-8 * x**3) w l lw 2 dt 2 lc "blue" notitle,\
    (8e-10 * x**4) w l lw 2 dt 2 lc "violet" notitle,\
    "tet.struct.hypre-snes.summary.txt" u ((4*(beamArea/$4)/3**0.5)**0.5*1e3):($5) w lp ps 0.5 pt 7 lc "slategrey" t "L_2 - S4F (SNES)", \
    "tet.struct.hypre-snes.summary.txt" u ((4*(beamArea/$4)/3**0.5)**0.5*1e3):($6) w lp ps 0.5 pt 6 lc "slategrey" t "L_∞ - S4F (SNES)", \
    "tet.struct.seg.summary.txt" u ((4*(beamArea/$4)/3**0.5)**0.5*1e3):($5) w lp ps 0.5 pt 7 lc "black" t "L_2 - S4F (SEG)", \
    "tet.struct.seg.summary.txt" u ((4*(beamArea/$4)/3**0.5)**0.5*1e3):($6) w lp ps 0.5 pt 6 lc "black" t "L_∞ - S4F (SEG)", \
    "tet.struct.ho.N1.summary.txt" u ((4*(beamArea/$4)/3**0.5)**0.5*1e3):($5) w lp ps 0.5 pt 7 lc "red" t "L_2 - N1", \
    "tet.struct.ho.N1.summary.txt" u ((4*(beamArea/$4)/3**0.5)**0.5*1e3):($6) w lp ps 0.5 pt 6 lc "red" t "L_∞ - N1", \
    "tet.struct.ho.N2.summary.txt" u ((4*(beamArea/$4)/3**0.5)**0.5*1e3):($5) w lp ps 0.5 pt 7 lc "blue" t "L_2 - N2", \
    "tet.struct.ho.N2.summary.txt" u ((4*(beamArea/$4)/3**0.5)**0.5*1e3):($6) w lp ps 0.5 pt 6 lc "blue" t "L_∞ - N2", \
    "tet.struct.ho.N3.summary.txt" u ((4*(beamArea/$4)/3**0.5)**0.5*1e3):($5) w lp ps 0.5 pt 7 lc "violet" t "L_2 - N3", \
    "tet.struct.ho.N3.summary.txt" u ((4*(beamArea/$4)/3**0.5)**0.5*1e3):($6) w lp ps 0.5 pt 6 lc "violet" t "L_∞ - N3"

set output "dispErrors_tet-unstruct.pdf"
#set title"Tetrahedral unstructured mesh"
plot \
    (2e-6 * x**2) w l lw 2 dt 2 lc "red" notitle,\
    (4e-8 * x**3) w l lw 2 dt 2 lc "blue" notitle,\
    (8e-10 * x**4) w l lw 2 dt 2 lc "violet" notitle,\
    "tet.unstruct.hypre-snes.summary.txt" u ((4*(beamArea/$4)/3**0.5)**0.5*1e3):($5) w lp ps 0.5 pt 9 lc "slategrey" t "L_2 - S4F (SNES)", \
    "tet.unstruct.hypre-snes.summary.txt" u ((4*(beamArea/$4)/3**0.5)**0.5*1e3):($6) w lp ps 0.5 pt 8 lc "slategrey" t "L_∞ - S4F (SNES)", \
    "tet.unstruct.seg.summary.txt" u ((4*(beamArea/$4)/3**0.5)**0.5*1e3):($5) w lp ps 0.5 pt 9 lc "black" t "L_2 - S4F (SEG)", \
    "tet.unstruct.seg.summary.txt" u ((4*(beamArea/$4)/3**0.5)**0.5*1e3):($6) w lp ps 0.5 pt 8 lc "black" t "L_∞ - S4F (SEG)", \
    "tet.unstruct.ho.N1.summary.txt" u ((4*(beamArea/$4)/3**0.5)**0.5*1e3):($5) w lp ps 0.5 pt 9 lc "red" t "L_2 - N1", \
    "tet.unstruct.ho.N1.summary.txt" u ((4*(beamArea/$4)/3**0.5)**0.5*1e3):($6) w lp ps 0.5 pt 8 lc "red" t "L_∞ - N1", \
    "tet.unstruct.ho.N2.summary.txt" u ((4*(beamArea/$4)/3**0.5)**0.5*1e3):($5) w lp ps 0.5 pt 9 lc "blue" t "L_2 - N2", \
    "tet.unstruct.ho.N2.summary.txt" u ((4*(beamArea/$4)/3**0.5)**0.5*1e3):($6) w lp ps 0.5 pt 8 lc "blue" t "L_∞ - N2", \
    "tet.unstruct.ho.N3.summary.txt" u ((4*(beamArea/$4)/3**0.5)**0.5*1e3):($5) w lp ps 0.5 pt 9 lc "violet" t "L_2 - N3", \
    "tet.unstruct.ho.N3.summary.txt" u ((4*(beamArea/$4)/3**0.5)**0.5*1e3):($6) w lp ps 0.5 pt 8 lc "violet" t "L_∞ - N3"