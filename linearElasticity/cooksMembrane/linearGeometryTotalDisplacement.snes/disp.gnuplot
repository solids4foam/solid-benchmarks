set term pdfcairo dashed enhanced
set datafile separator " "

set output "disp.pdf"

#set size ratio 1

set grid
#set xrange [1:50]
#set yrange [1e-5:0.2]
set xtics
#set xtics add (5, 25, 50)
set ytics
#set y2tics
set logscale x
#set logscale y
#set format y "10^{%L}"
#set ytics 0.002
set xlabel "Average cell spacing (in mm)"
set ylabel "Vertical Displacement (in mm)"
set key right top;
#set key right bottom;

#set label "1^{st} order" at graph 0.5,0.86 center rotate by 10
#set label "2^{nd} order" at graph 0.5,0.37 center rotate by 25

# Average mesh spacing of mesh1
dx=14.6666666667

# 15,14 - upturned solid penta
# 5,4 - square

# Assume the mesh spacing is being halved for each succesive mesh
plot \
    "times.mac-studio-m1.hex.lu.txt" u (dx/(2**($0))):($4) w lp pt 5 lc "red" t "U_2 - Hexahedra"

# In another plot, we can show time and memory
#"times.mac-studio-m1.hex.lu.txt" u (dx/(2**($0))):($2) axes x1y2 w lp pt 5 lc "red" t "Time - Hexahedra"

# If we knew the exact answer, we could plot the error
#    "times.mac-studio-m1.hex.lu.txt" u (dx/(2**($0))):(abs(32.27 - $4)) w lp pt 5 lc "red" t "U_2 - Hexahedra"

#"orderOfAccuracySlopesDisp.dat" u 1:2 w l lw 2 lc "black" notitle, \
#    "orderOfAccuracySlopesDisp.dat" u 1:3 w l lw 2 lc "black" notitle
