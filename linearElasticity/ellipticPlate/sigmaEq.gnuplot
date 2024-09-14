set term pdfcairo dashed enhanced
set datafile separator " "

set output "sigmaEq.pdf"

#set size ratio 1

#set style line 1 linecolor rgb 'black' linetype 6 linewidth 1 ps 1
#set style line 2 linecolor rgb 'red' linetype 4 linewidth 1 ps 1 dashtype 2
#set style line 3 linecolor rgb 'blue' linetype 2 linewidth 1 ps 1 dashtype 3
#set style line 4 linecolor rgb 'green' linetype 1 linewidth 1 ps 1 dashtype 4

set grid
set xrange [0:90]
set yrange [1:4]
set xtics
#set xtics add (5, 25, 50)
set ytics
#set logscale x
#set logscale y
#set ytics 0.002
set xlabel "Angle (in degrees)"
set ylabel "Equivalent (von Mises) Stress (in MPa)"
set key left top;

# Average mesh spacing is calculate as cbrt(totalVolume/numCells)
#dx=0.04

#0.04538297984 = mesh 4

# Assume the mesh spacing is being halved for each succesive mesh
plot \
    "mesh.1.macbook-pro-m3/sampleLineSigmaEq.txt" u ($1*180/pi):(1e-6*$5) w lp pt 6 ps 1 t "{/Symbol \D}x = 417.23 mm", \
    "mesh.2.macbook-pro-m3/sampleLineSigmaEq.txt" u ($1*180/pi):(1e-6*$5) w lp pt 6 ps 0.8 t "{/Symbol \D}x = 191.97 mm", \
    "mesh.3.macbook-pro-m3/sampleLineSigmaEq.txt" u ($1*180/pi):(1e-6*$5) w lp pt 6 ps 0.6 t "{/Symbol \D}x = 92.42 mm", \
    "mesh.4.macbook-pro-m3/sampleLineSigmaEq.txt" u ($1*180/pi):(1e-6*$5) w lp pt 6 ps 0.4 t "{/Symbol \D}x = 45.38 mm", \
    "mesh.5.macbook-pro-m3/sampleLineSigmaEq.txt" u ($1*180/pi):(1e-6*$5) w lp pt 6 ps 0.2 t "{/Symbol \D}x = 22.49 mm", \
    "mesh.6.macbook-pro-m3/sampleLineSigmaEq.txt" u ($1*180/pi):(1e-6*$5) w lp pt 6 ps 0.1 t "{/Symbol \D}x = 11.03 mm"
