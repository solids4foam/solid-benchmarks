set logscale x
set logscale y

set grid

plot \
    "vertexCentredLinearGeometry.displacementErrors.txt" u 1:2 w lp t "vertex L1", \
    "" u 1:3 w lp t "vertex L2", \
    "" u 1:4 w lp t "vertex LInf"