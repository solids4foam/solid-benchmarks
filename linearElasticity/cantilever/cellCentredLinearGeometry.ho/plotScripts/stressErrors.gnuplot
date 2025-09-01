set term pdfcairo dashed enhanced size 3.5,2
set datafile separator " "

#set size ratio 1
beamArea= 0.2

set grid
set xrange [5:55]
set yrange [0.0001:10]
set xtics
set xtics add (5, 25, 50)
set ytics
set logscale x
set logscale y
set format y "10^{%L}"
#set ytics 0.002
set xlabel "Average cell edge (in mm)"
set ylabel "Error (in MPa)"
#set key left top;
set key right bottom outside;

#set label "1^{st} order" at graph 0.5,0.86 center rotate by 10
#set label "2^{nd} order" at graph 0.5,0.37 center rotate by 25


set output "stressErrors_hex.pdf"
#set title "Hexahedral structured mesh"
plot \
    (0.2 * x**1) w l lw 2 dt 2 lc "red" notitle,\
    (2e-5 * x**2) w l lw 2 dt 2 lc "blue" notitle,\
    "hex.struct.hypre-snes.summary.txt" u ((beamArea/$4)**0.5*1e3):($7*1e-6) w lp ps 0.5 pt 4 lc "slategrey" t "L_2 - {/Symbol s}_{xx} -S4F (SNES)", \
        "hex.struct.hypre-snes.summary.txt" u ((beamArea/$4)**0.5*1e3):($8*1e-6) w lp ps 0.5 pt 5 dt 8 lc "slategrey" t "L_2 - {/Symbol s}_{yy} -S4F (SNES)", \
    "hex.struct.hypre-snes.summary.txt" u ((beamArea/$4)**0.5*1e3):($9*1e-6) w lp ps 0.5 pt 6 dt 9 lc "slategrey" t "L_2 - {/Symbol s}_{xy} -S4F (SNES)", \
    "hex.struct.ho.N1.summary.txt" u ((beamArea/$4)**0.5*1e3):($7*1e-6) w lp ps 0.5 pt 4 lc "red" t "L_2 - N1 - {/Symbol s}_{xx}", \
    "hex.struct.ho.N1.summary.txt" u ((beamArea/$4)**0.5*1e3):($8*1e-6) w lp ps 0.5 pt 5 dt 8 lc "red" t "L_2 - N1 - {/Symbol s}_{yy}", \
    "hex.struct.ho.N1.summary.txt" u ((beamArea/$4)**0.5*1e3):($9*1e-6) w lp ps 0.5 pt 6 dt 9  lc "red" t "L_2 - N1 - {/Symbol s}_{xy}", \
    "hex.struct.ho.N2.summary.txt" u ((beamArea/$4)**0.5*1e3):($7*1e-6) w lp ps 0.5 pt 4 lc "blue" t "L_2 - N2 - {/Symbol s}_{xx}", \
    "hex.struct.ho.N2.summary.txt" u ((beamArea/$4)**0.5*1e3):($8*1e-6) w lp ps 0.5 pt 5 dt 8 lc "blue" t "L_2 - N2 - {/Symbol s}_{yy}", \
    "hex.struct.ho.N2.summary.txt" u ((beamArea/$4)**0.5*1e3):($9*1e-6) w lp ps 0.5 pt 6 dt 9 lc "blue" t "L_2 - N2 - {/Symbol s}_{xy}"
    # "hex.struct.ho.N3.summary.txt" u ((beamArea/$4)**0.5*1e3):($7*1e-6) w lp ps 0.2 pt 5 lc "violet" t "L_2 - N2 - {/Symbol s}_{xx}", \
    # "hex.struct.ho.N3.summary.txt" u ((beamArea/$4)**0.5*1e3):($8*1e-6) w lp ps 0.2 pt 5 lc "violet" t "L_2 - N2 - {/Symbol s}_{yy}", \
    # "hex.struct.ho.N3.summary.txt" u ((beamArea/$4)**0.5*1e3):($9*1e-6) w lp ps 0.2 pt 5 lc "violet" t "L_2 - N2 - {/Symbol s}_{xy}"

set output "stressErrors_tet-struct.pdf"
#set title "Tetrahedral structured mesh"
plot \
    (0.2 * x**1) w l lw 2 dt 2 lc "red" notitle,\
    (2e-5 * x**2) w l lw 2 dt 2 lc "blue" notitle,\
    "tet.struct.ho.N1.summary.txt" u ((4*(beamArea/$4)/3**0.5)**0.5*1e3):($7*1e-6) w lp ps 0.5 pt 4 lc "red" t "L_2 - N1 - {/Symbol s}_{xx}", \
    "tet.struct.ho.N1.summary.txt" u ((4*(beamArea/$4)/3**0.5)**0.5*1e3):($8*1e-6) w lp ps 0.5 pt 5 dt 8 lc "red" t "L_2 - N1 - {/Symbol s}_{yy}", \
    "tet.struct.ho.N1.summary.txt" u ((4*(beamArea/$4)/3**0.5)**0.5*1e3):($9*1e-6) w lp ps 0.5 pt 6 dt 9  lc "red" t "L_2 - N1 - {/Symbol s}_{xy}", \
    "tet.struct.ho.N2.summary.txt" u ((4*(beamArea/$4)/3**0.5)**0.5*1e3):($7*1e-6) w lp ps 0.5 pt 4 lc "blue" t "L_2 - N2 - {/Symbol s}_{xx}", \
    "tet.struct.ho.N2.summary.txt" u ((4*(beamArea/$4)/3**0.5)**0.5*1e3):($8*1e-6) w lp ps 0.5 pt 5 dt 8 lc "blue" t "L_2 - N2 - {/Symbol s}_{yy}", \
    "tet.struct.ho.N2.summary.txt" u ((4*(beamArea/$4)/3**0.5)**0.5*1e3):($9*1e-6) w lp ps 0.5 pt 6 dt 9 lc "blue" t "L_2 - N2 - {/Symbol s}_{xy}"

set output "stressErrors_tet-unstruct.pdf"
# set title"Tetrahedral unstructured mesh"
plot \
    (0.2 * x**1) w l lw 2 dt 2 lc "red" notitle,\
    (2e-5 * x**2) w l lw 2 dt 2 lc "blue" notitle,\
    "tet.unstruct.ho.N1.summary.txt" u ((4*(beamArea/$4)/3**0.5)**0.5*1e3):($7*1e-6) w lp ps 0.5 pt 4 lc "red" t "L_2 - N1 - {/Symbol s}_{xx}", \
    "tet.unstruct.ho.N1.summary.txt" u ((4*(beamArea/$4)/3**0.5)**0.5*1e3):($8*1e-6) w lp ps 0.5 pt 5 dt 8 lc "red" t "L_2 - N1 - {/Symbol s}_{yy}", \
    "tet.unstruct.ho.N1.summary.txt" u ((4*(beamArea/$4)/3**0.5)**0.5*1e3):($9*1e-6) w lp ps 0.5 pt 6 dt 9  lc "red" t "L_2 - N1 - {/Symbol s}_{xy}", \
    "tet.unstruct.ho.N2.summary.txt" u ((4*(beamArea/$4)/3**0.5)**0.5*1e3):($7*1e-6) w lp ps 0.5 pt 4 lc "blue" t "L_2 - N2 - {/Symbol s}_{xx}", \
    "tet.unstruct.ho.N2.summary.txt" u ((4*(beamArea/$4)/3**0.5)**0.5*1e3):($8*1e-6) w lp ps 0.5 pt 5 dt 8 lc "blue" t "L_2 - N2 - {/Symbol s}_{yy}", \
    "tet.unstruct.ho.N2.summary.txt" u ((4*(beamArea/$4)/3**0.5)**0.5*1e3):($9*1e-6) w lp ps 0.5 pt 6 dt 9 lc "blue" t "L_2 - N2 - {/Symbol s}_{xy}"
