set term pdfcairo dashed enhanced
set datafile separator " "

#set size ratio 1

set grid
set xrange [5:1000]
set yrange [1e-8:1]
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

set linestyle 1 pt 5 ps 0.2 lw 2 lc "red"
set linestyle 2 pt 5 ps 0.2 lw 2 lc "blue"
set linestyle 3 pt 5 ps 0.2 lw 2 lc "violet"
set linestyle 4 pt 4 lw 2 ps 0.2 lc rgb "#DC143C"
set linestyle 5 pt 4 lw 2 ps 0.2 lc rgb "#377EB8"
set linestyle 6 pt 4 lw 2 ps 0.2 lc rgb "#984EA3"

set output "mms_dispErrorsComparison-hex-L2.pdf"
set title "Hexahedral structured mesh L_2"
plot \
    (3e-6 * x**2) w l lw 2 dt 2 lc "red" notitle,\
    (0.15e-8 * x**3) w l lw 2 dt 2 lc "blue" notitle,\
    (0.8e-12 * x**4) w l lw 2 dt 2 lc "violet" notitle,\
    "hex.struct.ho.N1.summary.txt" u ((1/$4)**0.5*1e3):($5) w lp ls 1 t "L_2 - N1", \
    "hex.struct.ho.N2.summary.txt" u ((1/$4)**0.5*1e3):($5) w lp ls 2 t "L_2 - N2", \
    "hex.struct.ho.N3.summary.txt" u ((1/$4)**0.5*1e3):($5) w lp ls 3 t "L_2 - N3", \
    "../plotScripts/Pablo_matlab/hex.struct.N1.txt" u ((1/$4)**0.5*1e3):($13) w lp ls 4 t "L_2 - N1 - matlab", \
    "../plotScripts/Pablo_matlab/hex.struct.N2.txt" u ((1/$4)**0.5*1e3):($13) w lp ls 5 t "L_2 - N2 - matlab", \
    "../plotScripts/Pablo_matlab/hex.struct.N3.txt" u ((1/$4)**0.5*1e3):($13) w lp ls 6 t "L_2 - N3 - matlab"

set output "mms_dispErrorsComparison-tet-struct-L2.pdf"
set title "Tetrahedral structured mesh L_2"
plot \
    (3e-6 * x**2) w l lw 2 dt 2lc "red" notitle,\
    (0.15e-8 * x**3) w l lw 2 dt 2 lc "blue" notitle,\
    (0.8e-12 * x**4) w l lw 2 dt 2 lc "violet" notitle,\
    "tet.struct.ho.N1.summary.txt" u ((4*(1/$4)/3**2)**0.5*1e3):($5) w lp ls 1 t "L_2 - N1", \
    "tet.struct.ho.N2.summary.txt" u ((4*(1/$4)/3**2)**0.5*1e3):($5) w lp ls 2 t "L_2 - N2", \
    "tet.struct.ho.N3.summary.txt" u ((4*(1/$4)/3**2)**0.5*1e3):($5) w lp ls 3 t "L_2 - N3", \
    "../plotScripts/Pablo_matlab/tet.struct.N1.txt" u ((4*(1/$4)/3**2)**0.5*1e3):($13) w lp ls 4 t "L_2 - N1 - matlab", \
    "../plotScripts/Pablo_matlab/tet.struct.N2.txt" u ((4*(1/$4)/3**2)**0.5*1e3):($13) w lp ls 5 t "L_2 - N2 - matlab", \
    "../plotScripts/Pablo_matlab/tet.struct.N3.txt" u ((4*(1/$4)/3**2)**0.5*1e3):($13) w lp ls 6 t "L_2 - N3 - matlab"

set output "mms_dispErrorsComparison-tet-struct-Linf.pdf"
set title "Tetrahedral structured mesh L_∞"
plot \
    (3e-6 * x**2) w l lw 2 dt 2lc "red" notitle,\
    (0.15e-8 * x**3) w l lw 2 dt 2 lc "blue" notitle,\
    (0.8e-12 * x**4) w l lw 2 dt 2 lc "violet" notitle,\
     "tet.struct.ho.N1.summary.txt" u ((4*(1/$4)/3**2)**0.5*1e3):($6) w lp ls 1 t "L_∞ - N1", \
     "tet.struct.ho.N2.summary.txt" u ((4*(1/$4)/3**2)**0.5*1e3):($6) w lp ls 2 t "L_∞ - N2", \
     "tet.struct.ho.N3.summary.txt" u ((4*(1/$4)/3**2)**0.5*1e3):($6) w lp ls 3 t "L_∞ - N3", \
    "../plotScripts/Pablo_matlab/tet.struct.N1.txt" u ((4*(1/$4)/3**2)**0.5*1e3):($13) w lp ls 4 t "L_2 - N1 - matlab", \
    "../plotScripts/Pablo_matlab/tet.struct.N2.txt" u ((4*(1/$4)/3**2)**0.5*1e3):($13) w lp ls 5 t "L_2 - N2 - matlab", \
    "../plotScripts/Pablo_matlab/tet.struct.N3.txt" u ((4*(1/$4)/3**2)**0.5*1e3):($13) w lp ls 6 t "L_2 - N3 - matlab"

set output "mms_dispErrorsComparison-tet-unstruct_v1-L2.pdf"
set title"Tetrahedral unstructured-v1 mesh L_2"
plot \
    (3e-6 * x**2) w l lw 1 dt 2 lc "red" notitle,\
    (0.15e-8 * x**3) w l lw 1 dt 2 lc "blue" notitle,\
    (0.8e-12 * x**4) w l lw 1 dt 2 lc "violet" notitle,\
    "tet.unstruct_v1.ho.N1.summary.txt" u ((4*(1/$4)/3**2)**0.5*1e3):($5) w lp ls 1 t "L_2 - N1", \
    "tet.unstruct_v1.ho.N2.summary.txt" u ((4*(1/$4)/3**2)**0.5*1e3):($5) w lp ls 2 t "L_2 - N2", \
    "tet.unstruct_v1.ho.N3.summary.txt" u ((4*(1/$4)/3**2)**0.5*1e3):($5) w lp ls 3 t "L_2 - N3", \
    "../plotScripts/Pablo_matlab/tet.unstruct_v1.N1.txt" u ((4*(1/$4)/3**2)**0.5*1e3):($13) w lp ls 4 t "L_2 - N1 - matlab", \
    "../plotScripts/Pablo_matlab/tet.unstruct_v1.N2.txt" u ((4*(1/$4)/3**2)**0.5*1e3):($13) w lp ls 5 t "L_2 - N2 - matlab", \
    "../plotScripts/Pablo_matlab/tet.unstruct_v1.N3.txt" u ((4*(1/$4)/3**2)**0.5*1e3):($13) w lp ls 6 t "L_2 - N3 - matlab"

set output "mms_dispErrorsComparison-tet-unstruct_v1-Linf.pdf"
set title"Tetrahedral unstructured-v1 mesh L__∞"
plot \
    (3e-6 * x**2) w l lw 1 dt 2 lc "red" notitle,\
    (0.15e-8 * x**3) w l lw 1 dt 2 lc "blue" notitle,\
    (0.8e-12 * x**4) w l lw 1 dt 2 lc "violet" notitle,\
    "tet.unstruct_v1.ho.N1.summary.txt" u ((4*(1/$4)/3**2)**0.5*1e3):($6) w lp ls 1 t "L_∞ - N1", \
    "tet.unstruct_v1.ho.N2.summary.txt" u ((4*(1/$4)/3**2)**0.5*1e3):($6) w lp ls 2 t "L_∞ - N2", \
    "tet.unstruct_v1.ho.N3.summary.txt" u ((4*(1/$4)/3**2)**0.5*1e3):($6) w lp ls 3 t "L_∞ - N3", \
    "../plotScripts/Pablo_matlab/tet.unstruct_v1.N1.txt" u ((4*(1/$4)/3**2)**0.5*1e3):($14) w lp ls 4 t "L_∞ - N1 - matlab", \
    "../plotScripts/Pablo_matlab/tet.unstruct_v1.N2.txt" u ((4*(1/$4)/3**2)**0.5*1e3):($14) w lp ls 5 t "L_∞ - N2 - matlab", \
    "../plotScripts/Pablo_matlab/tet.unstruct_v1.N3.txt" u ((4*(1/$4)/3**2)**0.5*1e3):($14) w lp ls 6 t "L_∞ - N3 - matlab"

set output "mms_dispErrorsComparison-tet-unstruct_v2-L2.pdf"
set title"Tetrahedral unstructured-v2 mesh L_2"
plot \
    (3e-6 * x**2) w l lw 1 dt 2 lc "red" notitle,\
    (0.15e-8 * x**3) w l lw 1 dt 2 lc "blue" notitle,\
    (0.8e-12 * x**4) w l lw 1 dt 2 lc "violet" notitle,\
    "tet.unstruct_v2.ho.N1.summary.txt" u ((4*(1/$4)/3**2)**0.5*1e3):($5) w lp ls 1 t "L_2 - N1", \
    "tet.unstruct_v2.ho.N2.summary.txt" u ((4*(1/$4)/3**2)**0.5*1e3):($5) w lp ls 2 t "L_2 - N2", \
    "tet.unstruct_v2.ho.N3.summary.txt" u ((4*(1/$4)/3**2)**0.5*1e3):($5) w lp ls 3 t "L_2 - N3", \
    "../plotScripts/Pablo_matlab/tet.unstruct_v2.N1.txt" u ((4*(1/$4)/3**2)**0.5*1e3):($13) w lp ls 4 t "L_2 - N1 - matlab", \
    "../plotScripts/Pablo_matlab/tet.unstruct_v2.N2.txt" u ((4*(1/$4)/3**2)**0.5*1e3):($13) w lp ls 5 t "L_2 - N2 - matlab", \
    "../plotScripts/Pablo_matlab/tet.unstruct_v2.N3.txt" u ((4*(1/$4)/3**2)**0.5*1e3):($13) w lp ls 6 t "L_2 - N3 - matlab"

set output "mms_dispErrorsComparison-tet-unstruct_v2-Linf.pdf"
set title"Tetrahedral unstructured-v2 mesh L__∞"
plot \
    (3e-6 * x**2) w l lw 1 dt 2 lc "red" notitle,\
    (0.15e-8 * x**3) w l lw 1 dt 2 lc "blue" notitle,\
    (0.8e-12 * x**4) w l lw 1 dt 2 lc "violet" notitle,\
    "tet.unstruct_v2.ho.N1.summary.txt" u ((4*(1/$4)/3**2)**0.5*1e3):($6) w lp ls 1 t "L_∞ - N1", \
    "tet.unstruct_v2.ho.N2.summary.txt" u ((4*(1/$4)/3**2)**0.5*1e3):($6) w lp ls 2 t "L_∞ - N2", \
    "tet.unstruct_v2.ho.N3.summary.txt" u ((4*(1/$4)/3**2)**0.5*1e3):($6) w lp ls 3 t "L_∞ - N3", \
    "../plotScripts/Pablo_matlab/tet.unstruct_v2.N1.txt" u ((4*(1/$4)/3**2)**0.5*1e3):($14) w lp ls 4 t "L_∞ - N1 - matlab", \
    "../plotScripts/Pablo_matlab/tet.unstruct_v2.N2.txt" u ((4*(1/$4)/3**2)**0.5*1e3):($14) w lp ls 5 t "L_∞ - N2 - matlab", \
    "../plotScripts/Pablo_matlab/tet.unstruct_v2.N3.txt" u ((4*(1/$4)/3**2)**0.5*1e3):($14) w lp ls 6 t "L_∞ - N3 - matlab"