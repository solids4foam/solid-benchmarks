reset
set term pngcairo dashed size 1024,768 font "Arial,12"

set style line 1 linecolor rgb 'black' linetype 1 linewidth 2 ps 1.8
set style line 2 linecolor rgb 'red' linetype 6 linewidth 1 ps 1.8
set style line 3 linecolor rgb 'blue' linetype 6 linewidth 1 ps 1.8
set style line 4 linecolor rgb 'green' linetype 6 linewidth 1 ps 1.8

set grid
set xlabel "Normalised displacement"
set ylabel "Reaction-x"
set key left top
set xrange [0:1]
set yrange [-30:10]
set xtics 0.2
set output 'nonLinearGeometryUpdatedLagrangian.reaction-x.png'

plot "nonLinearGeometryUpdatedLagrangian.0.0/postProcessing/0/solidForcesfixed.dat" u ($1/31.5):($2) w l ls 1 title"s4f",\
     "nonLinearGeometryUpdatedLagrangian.0.3/postProcessing/0/solidForcesfixed.dat" u ($1/31.5):($2) w l ls 1 notitle,\
     "nonLinearGeometryUpdatedLagrangian.0.6/postProcessing/0/solidForcesfixed.dat" u ($1/31.5):($2) w l ls 1 notitle,\
     "../data/neto-mu=0.0-x.txt" u ($1/31.5):2 w p ls 2 title"Neto, cof = 0.0",\
     "../data/neto-mu=0.3-x.txt" u ($1/31.5):2 w p ls 3 title"Neto, cof = 0.3",\
     "../data/neto-mu=0.6-x.txt" u ($1/31.5):2 w p ls 4 title"Neto, cof = 0.6"
     
set output 'nonLinearGeometryUpdatedLagrangian.reaction-y.png'
set yrange [0:50]
set ylabel "Reaction-y"

plot "nonLinearGeometryUpdatedLagrangian.0.0/postProcessing/0/solidForcesfixed.dat" u ($1/31.5):($3) w l ls 1 title"s4f",\
     "nonLinearGeometryUpdatedLagrangian.0.3/postProcessing/0/solidForcesfixed.dat" u ($1/31.5):($3) w l ls 1 notitle,\
     "nonLinearGeometryUpdatedLagrangian.0.6/postProcessing/0/solidForcesfixed.dat" u ($1/31.5):($3) w l ls 1 notitle,\
     "../data/neto-mu=0.0-y.txt" u ($1/31.5):2 w p ls 2 title"Neto, cof = 0.0",\
     "../data/neto-mu=0.3-y.txt" u ($1/31.5):2 w p ls 3 title"Neto, cof = 0.3",\
     "../data/neto-mu=0.6-y.txt" u ($1/31.5):2 w p ls 4 title"Neto, cof = 0.6"
