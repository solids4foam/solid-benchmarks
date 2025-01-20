set term pdfcairo dashed enhanced
set datafile separator " "

set output "cooksMembrane-neoHookeanPlasticTipDispConvergence.pdf"

set size ratio 0.7

set grid
set xrange [0.098:20]
set yrange [0:8]
set xtics
#set ytics (0.7, 0.8, 0.9, 1)

set logscale x
set format x "%g"

#set logscale y
#set ytics 0.002
set xlabel "Average cell spacing (in mm)"
set ylabel "Reference point vertical displacement (in mm)"
#set key at 2.6, 3200;
#set key left reverse
#set key samplen 1.5 spacing 1 font ",12"
set key bottom left

# Average mesh spacing of mesh1
# Area is 0.00144
# First mesh have 9 elements and one element area is then 0.00016. sqrt of that is 0.012649
dx=12.649

# Average mesh spacing of mesh 1 for Simo and Areias results
dxZT = 18.973666

file = "hex.seg.summary.txt"
file_SA = "SimoAndArmero.dat"
file_Ar = "Areias.dat"
file_C = "CesarEtAl.dat"
file_A = "abaqus.dat"

# Assume the mesh spacing is being halved for each succesive mesh
plot \
    file u (dx/(2**($0))):($4*1000) w lp pt 6 ps 1 lw 1.2 lc "red" t "Present work",\
    file_C u (dxZT/(2**($0))):($2) w lp pt 74 ps 0.8 lw 1.2 lc rgb '#666666' t "Cesar et al. (2001) - Q4",\
    file_C u (dxZT/(2**($0))):($3) w lp pt 74 ps 1.2 lw 1.2 lc rgb '#666666' t "Cesar et al. (2001) - Q1E4",\
    file_Ar u (dxZT/(2**($0))):($2) w lp pt 4 ps 0.8 lw 1.2 lc "black" t "Areias (Simplas) - δ",\
    file_Ar u (dxZT/(2**($0))):($3) w lp pt 4 ps 1.2 lw 1.2 lc "black" t "Areias (Simplas) - α",\
    file_SA u (dxZT/(2**($0))):($2) w lp pt 8 ps 0.8 lw 1.2 lc "gray" t "Simo and Armero (1992) - Q1/P0",\
    file_SA u (dxZT/(2**($0))):($3) w lp pt 8 ps 1.2 lw 1.2 lc "gray" t "Simo and Armero (1992) - Q1/E4", \
    file_A u 2:4 w lp pt 4 ps 1.2 lw 1 lc "purple" t "Abaqus (CPE4H)"
