set term pdfcairo dashed enhanced
set datafile separator " "


#set size ratio 1

set grid
set xrange [25:1000]
set yrange [1e-7:1]
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

# 15,14 - upturned solid penta
# 5,4 - square
# set output "mms_dispErrors-solid4foam-snes.pdf"
# plot \
#     (3e-9 * x**2) w l lw 2 lc "black" notitle,\
#     "hex.struct.hypre-snes.summary.txt" u ((1/$4)**0.5*1e3):($5) w lp ps 0.5 pt 5 lc "green" t "L_2 - Hex", \
#     "hex.struct.hypre-snes.summary.txt" u ((1/$4)**0.5*1e3):($6) w lp ps 0.5 pt 4 lc "green" t "L_∞ - Hex", \
#     "tet.struct.hypre-snes.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($5) w lp ps 0.5 pt 10 lc "green" t "L_2 - Tet-struct", \
#     "tet.struct.hypre-snes.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($6) w lp ps 0.5 pt 11 lc "green" t "L_∞ - Tet-struct", \
#     "tet.unstruct_v1.hypre-snes.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($5) w lp ps 0.5 pt 9 lc "orange" t "L_2 - Tet-unstruct-v1", \
#     "tet.unstruct_v1.hypre-snes.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($6) w lp ps 0.5 pt 8 lc "orange" t "L_∞ - Tet-unstruct-v1", \
#     "tet.unstruct_v2.hypre-snes.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($5) w lp ps 0.5 pt 9 lc "blue" t "L_2 - Tet-unstruct-v2", \
#     "tet.unstruct_v2.hypre-snes.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($6) w lp ps 0.5 pt 8 lc "blue" t "L_∞ - Tet-unstruct-v2"


set output "mms_dispErrors_ho-hex.pdf"
set title "Hexahedral structured mesh"
plot \
    (3e-6 * x**2) w l lw 2 dt 2 lc "red" notitle,\
    (0.15e-08 * x**3) w l lw 2 dt 2 lc "blue" notitle,\
    (0.8e-12 * x**4) w l lw 2 dt 2 lc "violet" notitle,\
    "hex.struct.hypre-snes.summary.txt" u ((1/$4)**0.5*1e3):($5) w lp ps 0.5 pt 5 lc "slategrey" t "L_2 - S4F (SNES)", \
    "hex.struct.hypre-snes.summary.txt" u ((1/$4)**0.5*1e3):($6) w lp ps 0.5 pt 4 lc "slategrey" t "L_∞ - S4F (SNES)", \
    "hex.struct.seg.summary.txt" u ((1/$4)**0.5*1e3):($5) w lp ps 0.5 pt 5 lc "black" t "L_2 - S4F (SEG)", \
    "hex.struct.seg.summary.txt" u ((1/$4)**0.5*1e3):($6) w lp ps 0.5 pt 4 lc  "black" t "L_∞ - S4F (SEG)", \
    "hex.struct.ho.N1.summary.txt" u ((1/$4)**0.5*1e3):($5) w lp ps 0.5 pt 5 lc "red" t "L_2 - N1", \
    "hex.struct.ho.N1.summary.txt" u ((1/$4)**0.5*1e3):($6) w lp ps 0.5 pt 4 lc "red" t "L_∞ - N1", \
    "hex.struct.ho.N2.summary.txt" u ((1/$4)**0.5*1e3):($5) w lp ps 0.5 pt 5 lc "blue" t "L_2 - N2", \
    "hex.struct.ho.N2.summary.txt" u ((1/$4)**0.5*1e3):($6) w lp ps 0.5 pt 4 lc "blue" t "L_∞ - N2", \
    "hex.struct.ho.N3.summary.txt" u ((1/$4)**0.5*1e3):($5) w lp ps 0.5 pt 5 lc "violet" t "L_2 - N3", \
    "hex.struct.ho.N3.summary.txt" u ((1/$4)**0.5*1e3):($6) w lp ps 0.5 pt 4 lc "violet" t "L_∞ - N3"

set output "mms_dispErrors_ho-tet-struct.pdf"
set title "Tetrahedral structured mesh"
plot \
    (3e-6 * x**2) w l lw 2 dt 2 lc "red" notitle,\
    (0.5e-08 * x**3) w l lw 2 dt 2 lc "blue" notitle,\
    (0.7e-11 * x**4) w l lw 2 dt 2 lc "violet" notitle,\
    "tet.struct.hypre-snes.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($5) w lp ps 0.5 pt 7 lc "slategrey" t "L_2 - S4F (SNES)", \
    "tet.struct.hypre-snes.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($6) w lp ps 0.5 pt 6 lc "slategrey" t "L_∞ - S4F (SNES)", \
    "tet.struct.seg.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($5) w lp ps 0.5 pt 7 lc "black" t "L_2 - S4F (SEG)", \
    "tet.struct.seg.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($6) w lp ps 0.5 pt 6 lc "black" t "L_∞ - S4F (SEG)", \
    "tet.struct.ho.N1.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($5) w lp ps 0.5 pt 7 lc "red" t "L_2 - N1", \
    "tet.struct.ho.N1.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($6) w lp ps 0.5 pt 6 lc "red" t "L_∞ - N1", \
    "tet.struct.ho.N2.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($5) w lp ps 0.5 pt 7 lc "blue" t "L_2 - N2", \
    "tet.struct.ho.N2.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($6) w lp ps 0.5 pt 6 lc "blue" t "L_∞ - N2", \
    "tet.struct.ho.N3.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($5) w lp ps 0.5 pt 7 lc "violet" t "L_2 - N3", \
    "tet.struct.ho.N3.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($6) w lp ps 0.5 pt 6 lc "violet" t "L_∞ - N3"

set output "mms_dispErrors_ho-tet-unstruct_v1.pdf"
set title"Tetrahedral unstructured-v1 mesh"
plot \
    (3e-6 * x**2) w l lw 2 dt 2 lc "red" notitle,\
    (0.5e-08 * x**3) w l lw 2 dt 2 lc "blue" notitle,\
    (0.7e-11 * x**4) w l lw 2 dt 2 lc "violet" notitle,\
    "tet.unstruct_v1.hypre-snes.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($5) w lp ps 0.5 pt 9 lc "slategrey" t "L_2 - S4F (SNES)", \
    "tet.unstruct_v1.hypre-snes.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($6) w lp ps 0.5 pt 8 lc "slategrey" t "L_∞ - S4F (SNES)", \
    "tet.unstruct_v1.seg.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($5) w lp ps 0.5 pt 9 lc "black" t "L_2 - S4F (SEG)", \
    "tet.unstruct_v1.seg.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($6) w lp ps 0.5 pt 8 lc "black" t "L_∞ - S4F (SEG)", \
    "tet.unstruct_v1.ho.N1.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($5) w lp ps 0.5 pt 9 lc "red" t "L_2 - N1", \
    "tet.unstruct_v1.ho.N1.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($6) w lp ps 0.5 pt 8 lc "red" t "L_∞ - N1", \
    "tet.unstruct_v1.ho.N2.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($5) w lp ps 0.5 pt 9 lc "blue" t "L_2 - N2", \
    "tet.unstruct_v1.ho.N2.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($6) w lp ps 0.5 pt 8 lc "blue" t "L_∞ - N2", \
    "tet.unstruct_v1.ho.N3.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($5) w lp ps 0.5 pt 9 lc "violet" t "L_2 - N3", \
    "tet.unstruct_v1.ho.N3.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($6) w lp ps 0.5 pt 8 lc "violet" t "L_∞ - N3"

set output "mms_dispErrors_ho-tet-unstruct_v2.pdf"
set title"Tetrahedral unstructured-v2 mesh"
plot \
    (3e-6 * x**2) w l lw 2 dt 2 lc "red" notitle,\
    (0.5e-08 * x**3) w l lw 2 dt 2 lc "blue" notitle,\
    (0.7e-11 * x**4) w l lw 2 dt 2 lc "violet" notitle,\
    "tet.unstruct_v2.hypre-snes.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($5) w lp ps 0.5 pt 9 lc "slategrey" t "L_2 - S4F (SNES)", \
    "tet.unstruct_v2.hypre-snes.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($6) w lp ps 0.5 pt 8 lc "slategrey" t "L_∞ - S4F (SNES)", \
    "tet.unstruct_v2.seg.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($5) w lp ps 0.5 pt 9 lc "black" t "L_2 - S4F (SEG)", \
    "tet.unstruct_v2.seg.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($6) w lp ps 0.5 pt 8 lc "black" t "L_∞ - S4F (SEG)", \
    "tet.unstruct_v2.ho.N1.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($5) w lp ps 0.5 pt 9 lc "red" t "L_2 - N1", \
    "tet.unstruct_v2.ho.N1.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($6) w lp ps 0.5 pt 8 lc "red" t "L_∞ - N1", \
    "tet.unstruct_v2.ho.N2.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($5) w lp ps 0.5 pt 9 lc "blue" t "L_2 - N2", \
    "tet.unstruct_v2.ho.N2.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($6) w lp ps 0.5 pt 8 lc "blue" t "L_∞ - N2", \
    "tet.unstruct_v2.ho.N3.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($5) w lp ps 0.5 pt 9 lc "violet" t "L_2 - N3", \
    "tet.unstruct_v2.ho.N3.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($6) w lp ps 0.5 pt 8 lc "violet" t "L_∞ - N3"

set output "mms_dispErrors_snes-hoRes-tet-unstruct_v1.pdf"
set title"Tetrahedral unstructured-v1 mesh"
plot \
    (3e-6 * x**2) w l lw 2 dt 2 lc "red" notitle,\
    (0.15e-08 * x**3) w l lw 2 dt 2 lc "blue" notitle,\
    (0.8e-12 * x**4) w l lw 2 dt 2 lc "violet" notitle,\
    "tet.unstruct_v1.hypre-snes.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($5) w lp ps 0.5 pt 9 lc "slategrey" t "L_2 - S4F (SNES)", \
    "tet.unstruct_v1.hypre-snes.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($6) w lp ps 0.5 pt 8 lc "slategrey" t "L_∞ - S4F (SNES)", \
    "tet.unstruct_v1.seg.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($5) w lp ps 0.5 pt 9 lc "black" t "L_2 - S4F (SEG)", \
    "tet.unstruct_v1.seg.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($6) w lp ps 0.5 pt 8 lc "black" t "L_∞ - S4F (SEG)", \
    "tet.unstruct_v1.snes-hoRes.N1.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($5) w lp ps 0.5 pt 9 lc "red" t "L_2 - N1 formResidual", \
    "tet.unstruct_v1.snes-hoRes.N1.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($6) w lp ps 0.5 pt 8 lc "red" t "L_∞ - N1 formResidual", \
    "tet.unstruct_v1.snes-hoRes.N2.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($5) w lp ps 0.5 pt 9 lc "blue" t "L_2 - N2 formResidual", \
    "tet.unstruct_v1.snes-hoRes.N2.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($6) w lp ps 0.5 pt 8 lc "blue" t "L_∞ - N2 formResidual", \
    "tet.unstruct_v1.snes-hoRes.N3.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($5) w lp ps 0.5 pt 9 lc "violet" t "L_2 - N3 formResidual", \
    "tet.unstruct_v1.snes-hoRes.N3.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($6) w lp ps 0.5 pt 8 lc "violet" t "L_∞ - N3 formResidual"

set output "mms_dispErrors_snes-hoRes-tet-struct.pdf"
set title "Tetrahedral structured mesh"
plot \
    (3e-6 * x**2) w l lw 2 dt 2 lc "red" notitle,\
    (0.15e-08 * x**3) w l lw 2 dt 2 lc "blue" notitle,\
    (0.8e-12 * x**4) w l lw 2 dt 2 lc "violet" notitle,\
    "tet.struct.hypre-snes.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($5) w lp ps 0.5 pt 7 lc "slategrey" t "L_2 - S4F (SNES)", \
    "tet.struct.hypre-snes.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($6) w lp ps 0.5 pt 6 lc "slategrey" t "L_∞ - S4F (SNES)", \
    "tet.struct.seg.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($5) w lp ps 0.5 pt 7 lc "black" t "L_2 - S4F (SEG)", \
    "tet.struct.seg.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($6) w lp ps 0.5 pt 6 lc "black" t "L_∞ - S4F (SEG)", \
    "tet.struct.snes-hoRes.N1.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($5) w lp ps 0.5 pt 7 lc "red" t "L_2 - N1 formResidual", \
    "tet.struct.snes-hoRes.N1.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($6) w lp ps 0.5 pt 6 lc "red" t "L_∞ - N1 formResidual", \
    "tet.struct.snes-hoRes.N2.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($5) w lp ps 0.5 pt 7 lc "blue" t "L_2 - N2 formResidual", \
    "tet.struct.snes-hoRes.N2.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($6) w lp ps 0.5 pt 6 lc "blue" t "L_∞ - N2 formResidual", \
    "tet.struct.snes-hoRes.N3.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($5) w lp ps 0.5 pt 7 lc "violet" t "L_2 - N3 formResidual", \
    "tet.struct.snes-hoRes.N3.summary.txt" u ((4*(1/$4)/3**0.5)**0.5*1e3):($6) w lp ps 0.5 pt 6 lc "violet" t "L_∞ - N3 formResidual"

set output "mms_dispErrors_snes-hoRes-hex.pdf"
set title "Hexahedral structured mesh"
plot \
    (3e-6 * x**2) w l lw 2 dt 2 lc "red" notitle,\
    (0.15e-08 * x**3) w l lw 2 dt 2 lc "blue" notitle,\
    (0.8e-12 * x**4) w l lw 2 dt 2 lc "violet" notitle,\
    "hex.struct.hypre-snes.summary.txt" u ((1/$4)**0.5*1e3):($5) w lp ps 0.5 pt 5 lc "slategrey" t "L_2 - S4F (SNES)", \
    "hex.struct.hypre-snes.summary.txt" u ((1/$4)**0.5*1e3):($6) w lp ps 0.5 pt 4 lc "slategrey" t "L_∞ - S4F (SNES)", \
    "hex.struct.seg.summary.txt" u ((1/$4)**0.5*1e3):($5) w lp ps 0.5 pt 5 lc "black" t "L_2 - S4F (SEG)", \
    "hex.struct.seg.summary.txt" u ((1/$4)**0.5*1e3):($6) w lp ps 0.5 pt 4 lc  "black" t "L_∞ - S4F (SEG)", \
    "hex.struct.snes-hoRes.N1.summary.txt" u ((1/$4)**0.5*1e3):($5) w lp ps 0.5 pt 5 lc "red" t "L_2 - N1 formResidual", \
    "hex.struct.snes-hoRes.N1.summary.txt" u ((1/$4)**0.5*1e3):($6) w lp ps 0.5 pt 4 lc "red" t "L_∞ - N1 formResidual", \
    "hex.struct.snes-hoRes.N2.summary.txt" u ((1/$4)**0.5*1e3):($5) w lp ps 0.5 pt 5 lc "blue" t "L_2 - N2 formResidual", \
    "hex.struct.snes-hoRes.N2.summary.txt" u ((1/$4)**0.5*1e3):($6) w lp ps 0.5 pt 4 lc "blue" t "L_∞ - N2 formResidual", \
    "hex.struct.snes-hoRes.N3.summary.txt" u ((1/$4)**0.5*1e3):($5) w lp ps 0.5 pt 5 lc "violet" t "L_2 - N3 formResidual", \
    "hex.struct.snes-hoRes.N3.summary.txt" u ((1/$4)**0.5*1e3):($6) w lp ps 0.5 pt 4 lc "violet" t "L_∞ - N3 formResidual"
