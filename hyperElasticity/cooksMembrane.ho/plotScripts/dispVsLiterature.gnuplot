set term pdfcairo dashed enhanced size 3.25,2
set datafile separator " "

set grid
set xrange [0.098:20]
set yrange [0:16]
set xtics
#set ytics (0.7, 0.8, 0.9, 1)
set logscale x
set format x "%g"
#set logscale y
#set ytics 0.002
set xlabel "Average cell spacing (in mm)"
set ylabel "Reference point vertical\n displacement (in mm)"
set key bottom center;

# Data lines for each p-order (with titles)
set style line 11 lc rgb "red"    pt 7 ps 0.75 lw 1
set style line 12 lc rgb "red"    pt 6 ps 0.75 lw 1
set style line 21 lc rgb "blue"   pt 5 ps 0.75 lw 1
set style line 22 lc rgb "blue"   pt 4 ps 0.75 lw 1
set style line 31 lc rgb "violet" pt 9 ps 0.75 lw 1
set style line 32 lc rgb "violet" pt 8 ps 0.75 lw 1

# Average mesh spacing of mesh1
# Area is 0.00144
# First mesh have 9 elements and one element area is then 0.00016. sqrt of that is 0.012649
dx=12.649

# Average mesh spacing of mesh 1 for Zienkiewicz and Taylor results
dxZT = 18.973666

# Membrane area
area =  1440

file_D = "deal.II.dat"
file_A = "abaqus.dat"

# Assume the mesh spacing is being halved for each succesive mesh
set output "CooksMembrane-hex-neoHookeanTipDispConvergence.pdf"
plot \
    "hex.lu.summary.txt" u (dx/(2**($0))):($5*1000) w lp pt 6 ps 0.75 lw 1.2 lc "black" t "solids4foam",\
    file_D u (dxZT/(2**($0))):($2) w lp pt 8 ps 0.75 lw 1.2 lc "gray" t "Pelteret and McBride (2016) - Q1",\
    file_D u (dxZT/(2**($0))):($3) w lp pt 4 ps 0.75 lw 1.2 lc "black!40" t "Pelteret and McBride (2016) - Q2", \
    file_A u 2:4 w lp pt 4 ps 0.75 lw 1.2 lc "purple" t "Abaqus (CPE4H)",\
    "hex.ho.N1.summary.txt" u (dx/(2**($0))):($5*1000) w lp ls 11 t"{/Times-Italic p}_{ }=1", \
    "hex.ho.N2.summary.txt" u (dx/(2**($0))):($5*1000) w lp ls 21 t"{/Times-Italic p}_{ }=2", \
    "hex.ho.N3.summary.txt" u (dx/(2**($0))):($5*1000) w lp ls 31 t"{/Times-Italic p}_{ }=3"

set output "CooksMembrane-tet-neoHookeanTipDispConvergence.pdf"
plot \
    "tet.seg.summary.txt" u (dx/(2**($0))):($5*1000) w lp pt 6 ps 0.75 lw 1.2 lc "black" t "solids4foam",\
    file_D u (dxZT/(2**($0))):($2) w lp pt 8 ps 0.75 lw 1.2 lc "gray" t "Pelteret and McBride (2016) - Q1",\
    file_D u (dxZT/(2**($0))):($3) w lp pt 4 ps 0.75 lw 1.2 lc "black!40" t "Pelteret and McBride (2016) - Q2", \
    file_A u 2:4 w lp pt 4 ps 0.75 lw 1.2 lc "purple" t "Abaqus (CPE4H)",\
    "tet.ho.N1.summary.txt" u ((4*(area/$4)/3**0.5)**0.5):($5*1000) w lp ls 11 t"{/Times-Italic p}_{ }=1", \
    "tet.ho.N2.summary.txt" u ((4*(area/$4)/3**0.5)**0.5):($5*1000) w lp ls 21 t"{/Times-Italic p}_{ }=2", \
    "tet.ho.N3.summary.txt" u ((4*(area/$4)/3**0.5)**0.5):($5*1000) w lp ls 31 t"{/Times-Italic p}_{ }=3"
