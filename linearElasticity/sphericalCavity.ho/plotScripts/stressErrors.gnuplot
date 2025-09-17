set term pdfcairo dashed enhanced size 3.5, 3
set datafile separator " "

volume = 0.104056049

#set size ratio 1

set grid
set xrange [10:100]
#set yrange [1e-3:100]
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
set rmargin 15

#set label "1^{st} order" at graph 0.5,0.86 center rotate by 10
#set label "2^{nd} order" at graph 0.5,0.37 center rotate by 25

set output "sphericalCavity_ho-tet.pdf"
#set title"Tetrahedral unstructured mesh"
plot \
    (5e-1 * x) w l lw 2 dt 2 lc "red" notitle,\
    (15e-4 * x**2) w l lw 2 dt 2 lc "blue" notitle,\
    (1e-5 * x**3) w l lw 2 dt 2 lc "violet" notitle,\
    "tet.unstruct.hypre-snes.summary.txt" u ((8.48528*(volume/$4))**(1.0/3.0)*1e3):($7*1e-6) w lp ps 0.5 pt 9 lc "slategrey" t "L_2 - S4F*", \
    "tet.unstruct.hypre-snes.summary.txt" u ((8.48528*(volume/$4))**(1.0/3.0)*1e3):($8*1e-6) w lp ps 0.5 pt 8 lc "slategrey" t "L_∞ - S4F*", \
    "tet.unstruct.seg.summary.txt" u ((8.48528*(volume/$4))**(1.0/3.0)*1e3):($7*1e-6) w lp ps 0.5 pt 9 lc "black" t "L_2 - S4F", \
    "tet.unstruct.seg.summary.txt" u ((8.48528*(volume/$4))**(1.0/3.0)*1e3):($8*1e-6) w lp ps 0.5 pt 8 lc "black" t "L_∞ - S4F", \
    "tet.unstruct.ho.N1.summary.txt" u ((8.48528*(volume/$4))**(1.0/3.0)*1e3):($7*1e-6) w lp ps 0.5 pt 9 lc "red" t "L_2 - N1", \
    "tet.unstruct.ho.N1.summary.txt" u ((8.48528*(volume/$4))**(1.0/3.0)*1e3):($8*1e-6) w lp ps 0.5 pt 8 lc "red" t "L_∞ - N1", \
    "tet.unstruct.ho.N2.summary.txt" u ((8.48528*(volume/$4))**(1.0/3.0)*1e3):($7*1e-6) w lp ps 0.5 pt 9 lc "blue" t "L_2 - N2", \
    "tet.unstruct.ho.N2.summary.txt" u ((8.48528*(volume/$4))**(1.0/3.0)*1e3):($8*1e-6) w lp ps 0.5 pt 8 lc "blue" t "L_∞ - N2", \
    "tet.unstruct.ho.N3.summary.txt" u ((8.48528*(volume/$4))**(1.0/3.0)*1e3):($7*1e-6) w lp ps 0.5 pt 9 lc "violet" t "L_2 - N3", \
    "tet.unstruct.ho.N3.summary.txt" u ((8.48528*(volume/$4))**(1.0/3.0)*1e3):($8*1e-6) w lp ps 0.5 pt 8 lc "violet" t "L_∞ - N3"

# set output "mms_stressErrors_ho-poly.pdf"
# #set title"Polyhedral mesh"
# plot \
#     (5e-1 * x) w l lw 2 dt 2 lc "red" notitle,\
#     (15e-4 * x**2) w l lw 2 dt 2 lc "blue" notitle,\
#     (1e-5 * x**3) w l lw 2 dt 2 lc "violet" notitle,\
#     "poly.hypre-snes.summary.txt" u ((6*(volume/$4)/pi)**(1.0/3.0)*1e3):($7*1e-6) w lp ps 0.5 pt 9 lc "slategrey" t "L_2 - S4F*", \
#     "poly.hypre-snes.summary.txt" u ((6*(volume/$4)/pi)**(1.0/3.0)*1e3):($8*1e-6) w lp ps 0.5 pt 8 lc "slategrey" t "L_∞ - S4F*", \
#     "poly.seg.summary.txt" u ((6*(volume/$4)/pi)**(1.0/3.0)*1e3):($7*1e-6) w lp ps 0.5 pt 9 lc "black" t "L_2 - S4F", \
#     "poly.seg.summary.txt" u ((6*(volume/$4)/pi)**(1.0/3.0)*1e3):($8*1e-6) w lp ps 0.5 pt 8 lc "black" t "L_∞ - S4F", \
#     "poly.ho.N1.summary.txt" u ((6*(volume/$4)/pi)**(1.0/3.0)*1e3):($7*1e-6) w lp ps 0.5 pt 9 lc "red" t "L_2 - N1", \
#     "poly.ho.N1.summary.txt" u ((6*(volume/$4)/pi)**(1.0/3.0)*1e3):($8*1e-6) w lp ps 0.5 pt 8 lc "red" t "L_∞ - N1", \
#     "poly.ho.N2.summary.txt" u ((6*(volume/$4)/pi)**(1.0/3.0)*1e3):($7*1e-6) w lp ps 0.5 pt 9 lc "blue" t "L_2 - N2", \
#     "poly.ho.N2.summary.txt" u ((6*(volume/$4)/pi)**(1.0/3.0)*1e3):($8*1e-6) w lp ps 0.5 pt 8 lc "blue" t "L_∞ - N2", \
#     "poly.ho.N3.summary.txt" u ((6*(volume/$4)/pi)**(1.0/3.0)*1e3):($7*1e-6) w lp ps 0.5 pt 9 lc "violet" t "L_2 - N3", \
#     "poly.ho.N3.summary.txt" u ((6*(volume/$4)/pi)**(1.0/3.0)*1e3):($8*1e-6) w lp ps 0.5 pt 8 lc "violet" t "L_∞ - N3"
