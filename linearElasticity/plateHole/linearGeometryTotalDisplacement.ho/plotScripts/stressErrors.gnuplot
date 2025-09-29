set term pdfcairo dashed enhanced size 3.5,2
set datafile separator " "

#set size ratio 1
area= 3.803650459

set grid
set xrange [5:150]
set yrange [1e-7:0.1]
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
set rmargin 20

#set label "1^{st} order" at graph 0.5,0.86 center rotate by 10
#set label "2^{nd} order" at graph 0.5,0.37 center rotate by 25


set output "plateHole-stressErrors_hex.pdf"
#set title "Hexahedral structured mesh"
plot \
    (2e-4 * x**1) w l lw 2 dt 2 lc "red" notitle,\
    (1e-6 * x**2) w l lw 2 dt 2 lc "blue" notitle,\
    (7e-9 * x**3) w l lw 2 dt 2 lc "violet" notitle,\
    "hex.seg.summary.txt" u ((area/$4)**0.5*1e3):($7*1e-6) w lp ps 0.5 pt 4 lc "black" t "L_2 - S4F - {/Symbol s}_{xx}", \
    "hex.seg.summary.txt" u ((area/$4)**0.5*1e3):($8*1e-6) w lp ps 0.5 pt 5 dt 8 lc "black" t "L_2 - S4F - {/Symbol s}_{yy}", \
    "hex.seg.summary.txt" u ((area/$4)**0.5*1e3):($9*1e-6) w lp ps 0.5 pt 6 dt 9 lc "black" t "L_2 - S4F -{/Symbol s}_{xy}", \
    "hex.ho.N1.summary.txt" u ((area/$4)**0.5*1e3):($7*1e-6) w lp ps 0.5 pt 4 lc "red" t "L_2 - N1 - {/Symbol s}_{xx}", \
    "hex.ho.N1.summary.txt" u ((area/$4)**0.5*1e3):($8*1e-6) w lp ps 0.5 pt 5 dt 8 lc "red" t "L_2 - N1 - {/Symbol s}_{yy}", \
    "hex.ho.N1.summary.txt" u ((area/$4)**0.5*1e3):($9*1e-6) w lp ps 0.5 pt 6 dt 9  lc "red" t "L_2 - N1 - {/Symbol s}_{xy}", \
    "hex.ho.N2.summary.txt" u ((area/$4)**0.5*1e3):($7*1e-6) w lp ps 0.5 pt 4 lc "blue" t "L_2 - N2 - {/Symbol s}_{xx}", \
    "hex.ho.N2.summary.txt" u ((area/$4)**0.5*1e3):($8*1e-6) w lp ps 0.5 pt 5 dt 8 lc "blue" t "L_2 - N2 - {/Symbol s}_{yy}", \
    "hex.ho.N2.summary.txt" u ((area/$4)**0.5*1e3):($9*1e-6) w lp ps 0.5 pt 6 dt 9 lc "blue" t "L_2 - N2 - {/Symbol s}_{xy}",\
    "hex.ho.N3.summary.txt" u ((area/$4)**0.5*1e3):($7*1e-6) w lp ps 0.5 pt 4 lc "violet" t "L_2 - N2 - {/Symbol s}_{xx}", \
    "hex.ho.N3.summary.txt" u ((area/$4)**0.5*1e3):($8*1e-6) w lp ps 0.5 pt 5 dt 8 lc "violet" t "L_2 - N2 - {/Symbol s}_{yy}", \
    "hex.ho.N3.summary.txt" u ((area/$4)**0.5*1e3):($9*1e-6) w lp ps 0.5 pt 6 dt 9 lc "violet" t "L_2 - N2 - {/Symbol s}_{xy}"



set output "plateHole-stressErrors_tet-unstruct.pdf"
# set title"Tetrahedral unstructured mesh"
plot \
    (2e-4 * x**1) w l lw 2 dt 2 lc "red" notitle,\
    (1e-6 * x**2) w l lw 2 dt 2 lc "blue" notitle,\
    (5e-9 * x**3) w l lw 2 dt 2 lc "violet" notitle,\
    "tet.seg.summary.txt" u ((4*(area/$4)/3**0.5)**0.5*1e3):($7*1e-6) w lp ps 0.5 pt 4 lc "black" t "L_2 - S4F- {/Symbol s}_{xx}", \
    "tet.seg.summary.txt" u ((4*(area/$4)/3**0.5)**0.5*1e3):($8*1e-6) w lp ps 0.5 pt 5 dt 8 lc "black" t "L_2 - S4F- {/Symbol s}_{yy}", \
    "tet.seg.summary.txt" u ((4*(area/$4)/3**0.5)**0.5*1e3):($9*1e-6) w lp ps 0.5 pt 6 dt 9 lc "black" t "L_2 - S4F- {/Symbol s}_{xy}", \
    "tet.ho.N1.summary.txt" u ((4*(area/$4)/3**0.5)**0.5*1e3):($7*1e-6) w lp ps 0.5 pt 4 lc "red" t "L_2 - N1 - {/Symbol s}_{xx}", \
    "tet.ho.N1.summary.txt" u ((4*(area/$4)/3**0.5)**0.5*1e3):($8*1e-6) w lp ps 0.5 pt 5 dt 8 lc "red" t "L_2 - N1 - {/Symbol s}_{yy}", \
    "tet.ho.N1.summary.txt" u ((4*(area/$4)/3**0.5)**0.5*1e3):($9*1e-6) w lp ps 0.5 pt 6 dt 9  lc "red" t "L_2 - N1 - {/Symbol s}_{xy}", \
    "tet.ho.N2.summary.txt" u ((4*(area/$4)/3**0.5)**0.5*1e3):($7*1e-6) w lp ps 0.5 pt 4 lc "blue" t "L_2 - N2 - {/Symbol s}_{xx}", \
    "tet.ho.N2.summary.txt" u ((4*(area/$4)/3**0.5)**0.5*1e3):($8*1e-6) w lp ps 0.5 pt 5 dt 8 lc "blue" t "L_2 - N2 - {/Symbol s}_{yy}", \
    "tet.ho.N2.summary.txt" u ((4*(area/$4)/3**0.5)**0.5*1e3):($9*1e-6) w lp ps 0.5 pt 6 dt 9 lc "blue" t "L_2 - N2 - {/Symbol s}_{xy}",\
    "tet.ho.N3.summary.txt" u ((4*(area/$4)/3**0.5)**0.5*1e3):($7*1e-6) w lp ps 0.5 pt 4 lc "violet" t "L_2 - N2 - {/Symbol s}_{xx}", \
    "tet.ho.N3.summary.txt" u ((4*(area/$4)/3**0.5)**0.5*1e3):($8*1e-6) w lp ps 0.5 pt 5 dt 8 lc "violet" t "L_2 - N2 - {/Symbol s}_{yy}", \
    "tet.ho.N3.summary.txt" u ((4*(area/$4)/3**0.5)**0.5*1e3):($9*1e-6) w lp ps 0.5 pt 6 dt 9 lc "violet" t "L_2 - N2 - {/Symbol s}_{xy}"
