#set ylabel 'CPU time [sec]' font "Times-Roman,14"
#set xlabel 'Time [sec]' font "Times-Roman,14"
#set key font ",14"
#set key left top
#set xtics font ", 16"
#set ytics font ", 16"
#set title "singleCavity-caseA" font  "Times-Roman,15"

set logscale x
set logscale y

set grid

#set terminal pdfcairo
#set output "stressError.pdf"

plot \
    "tri.vertex.stressErrors.xx.txt" u 1:2 w lp t "vertex L1", \
    "" u 1:3 w lp t "vertex L2", \
    "" u 1:4 w lp t "vertex LInf", \
    "tri.linGeomSolid.stressErrors.xx.txt" u 1:2 w lp t "linGeomSolid L1", \
    "" u 1:3 w lp t "linGeomSolid L2", \
    "" u 1:4 w lp t "linGeomSolid LInf"

#"linGeomSolid.stressErrors.xx.txt" u 1:3 w lp t "linGeomSolid L2", \
#    "" u 1:4 w lp t "linGeomSolid LInf", \
#    "vertex.stressErrors.xx.txt" u 1:3 w lp t "vertex L2", \
#    "" u 1:4 w lp t "vertex LInf", \
