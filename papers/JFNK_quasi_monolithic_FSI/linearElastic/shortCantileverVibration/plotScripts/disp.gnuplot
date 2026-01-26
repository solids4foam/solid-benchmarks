set term pdfcairo dashed enhanced size 5, 2
set datafile separator " "

set grid
set xrange [0:1]
set yrange [0:0.7]
set xtics
set ytics
set xlabel "Time (in s)"
set ylabel "End displacement (in m)"
#set key left top;
set key right bottom outside;
set rmargin 25
set key spacing 1.2

# Data lines for each p-order (with titles)
set style line 1 lc rgb "black" pt 4 ps 0.005 lw 1.5
set style line 2 lc rgb "black" pt 8 ps 0.4 lw 1.5
set style line 3 lc rgb "red" pt 6 ps 0.8 lw 1
set style line 4 lc rgb "red" pt 6 ps 0.5 lw 1
set style line 5 lc rgb "red" pt 6 ps 0.2 lw 1
set style line 6 lc rgb "blue" pt 6 ps 0.8 lw 1
set style line 7 lc rgb "blue" pt 6 ps 0.5 lw 1
set style line 8 lc rgb "blue" pt 6 ps 0.2 lw 1

# Time-step sizes from Allrun script. Right now we plot three time-steps per solver type
DT1 = "3.2e-4"
DT2 = "1.6e-4"
DT3 = "4.0e-5"

# Mesh 1 - time-step behaviour
set output "mesh_1-dispComparison.pdf"
set label 1 "Mesh size: 264 cells" at graph 1.05,0.9 font ",10"

snes_disp_1 = sprintf("displacement-snes.mesh-1.deltaT-%s/postProcessing/0/solidPointDisplacement_pointDisp.dat", DT1)
snes_disp_2 = sprintf("displacement-snes.mesh-1.deltaT-%s/postProcessing/0/solidPointDisplacement_pointDisp.dat", DT2)
snes_disp_3 = sprintf("displacement-snes.mesh-1.deltaT-%s/postProcessing/0/solidPointDisplacement_pointDisp.dat", DT3)
snes_vel_1 = sprintf("velocity-snes.mesh-1.deltaT-%s/postProcessing/0/solidPointDisplacement_pointDisp.dat", DT1)
snes_vel_2 = sprintf("velocity-snes.mesh-1.deltaT-%s/postProcessing/0/solidPointDisplacement_pointDisp.dat", DT2)
snes_vel_3 = sprintf("velocity-snes.mesh-1.deltaT-%s/postProcessing/0/solidPointDisplacement_pointDisp.dat", DT3)

plot \
     NaN title "Greendshields paper" with l ls 2,\
    "../plotScripts/analyticalEndDeflection.txt" u 1:2 w p ls 1 notitle,\
    snes_disp_1 u 1:($5)  w l ls 3 notitle, '' u 1:5 every 50 w p ls 3 t sprintf("D-SNES  {/Symbol D}T=%s", DT1),\
    snes_disp_2 u 1:($5)  w l ls 4 notitle, '' u 1:5 every 100 w p ls 4 t sprintf("D-SNES  {/Symbol D}T=%s", DT2),\
    snes_disp_3 u 1:($5)  w l ls 5 notitle, '' u 1:5 every 400 w p ls 5 t sprintf("D-SNES  {/Symbol D}T=%s", DT3),\
    snes_vel_1 u 1:($5)   w l ls 6 notitle, '' u 1:5 every 50 w p ls 6 t sprintf("V-SNES  {/Symbol D}T=%s", DT1),\
    snes_vel_2 u 1:($5)   w l ls 7 notitle, '' u 1:5 every 100 w p ls 7 t sprintf("V-SNES  {/Symbol D}T=%s", DT2),\
    snes_vel_3 u 1:($5)   w l ls 8 notitle, '' u 1:5 every 400 w p ls 8 t sprintf("V-SNES  {/Symbol D}T=%s", DT3)



# Mesh 2 - time-step behaviour
set output "mesh_2-dispComparison.pdf"
set label 1 "Mesh size: 1 056 cells" at graph 1.05,0.9 font ",10"

snes_disp_1 = sprintf("displacement-snes.mesh-2.deltaT-%s/postProcessing/0/solidPointDisplacement_pointDisp.dat", DT1)
snes_disp_2 = sprintf("displacement-snes.mesh-2.deltaT-%s/postProcessing/0/solidPointDisplacement_pointDisp.dat", DT2)
snes_disp_3 = sprintf("displacement-snes.mesh-2.deltaT-%s/postProcessing/0/solidPointDisplacement_pointDisp.dat", DT3)
snes_vel_1 = sprintf("velocity-snes.mesh-2.deltaT-%s/postProcessing/0/solidPointDisplacement_pointDisp.dat", DT1)
snes_vel_2 = sprintf("velocity-snes.mesh-2.deltaT-%s/postProcessing/0/solidPointDisplacement_pointDisp.dat", DT2)
snes_vel_3 = sprintf("velocity-snes.mesh-2.deltaT-%s/postProcessing/0/solidPointDisplacement_pointDisp.dat", DT3)

plot \
     NaN title "Greendshields paper" with l ls 2,\
    "../plotScripts/analyticalEndDeflection.txt" u 1:2 w p ls 1 notitle,\
    snes_disp_1 u 1:($5)  w l ls 3 notitle, '' u 1:5 every 50 w p ls 3 t sprintf("D-SNES  {/Symbol D}T=%s", DT1),\
    snes_disp_2 u 1:($5)  w l ls 4 notitle, '' u 1:5 every 100 w p ls 4 t sprintf("D-SNES  {/Symbol D}T=%s", DT2),\
    snes_disp_3 u 1:($5)  w l ls 5 notitle, '' u 1:5 every 400 w p ls 5 t sprintf("D-SNES  {/Symbol D}T=%s", DT3),\
    snes_vel_1 u 1:($5)   w l ls 6 notitle, '' u 1:5 every 50 w p ls 6 t sprintf("V-SNES  {/Symbol D}T=%s", DT1),\
    snes_vel_2 u 1:($5)   w l ls 7 notitle, '' u 1:5 every 100 w p ls 7 t sprintf("V-SNES  {/Symbol D}T=%s", DT2),\
    snes_vel_3 u 1:($5)   w l ls 8 notitle, '' u 1:5 every 400 w p ls 8 t sprintf("V-SNES  {/Symbol D}T=%s", DT3)


# Mesh 3 - time-step behaviour
set output "mesh_3-dispComparison.pdf"
set label 1 "Mesh size: 4 389 cells" at graph 1.05,0.9 font ",10"

snes_disp_1 = sprintf("displacement-snes.mesh-3.deltaT-%s/postProcessing/0/solidPointDisplacement_pointDisp.dat", DT1)
snes_disp_2 = sprintf("displacement-snes.mesh-3.deltaT-%s/postProcessing/0/solidPointDisplacement_pointDisp.dat", DT2)
snes_disp_3 = sprintf("displacement-snes.mesh-3.deltaT-%s/postProcessing/0/solidPointDisplacement_pointDisp.dat", DT3)
snes_vel_1 = sprintf("velocity-snes.mesh-3.deltaT-%s/postProcessing/0/solidPointDisplacement_pointDisp.dat", DT1)
snes_vel_2 = sprintf("velocity-snes.mesh-3.deltaT-%s/postProcessing/0/solidPointDisplacement_pointDisp.dat", DT2)
snes_vel_3 = sprintf("velocity-snes.mesh-3.deltaT-%s/postProcessing/0/solidPointDisplacement_pointDisp.dat", DT3)

plot \
     NaN title "Greendshields paper" with l ls 2,\
    "../plotScripts/analyticalEndDeflection.txt" u 1:2 w p ls 1 notitle,\
    snes_disp_1 u 1:($5)  w l ls 3 notitle, '' u 1:5 every 50 w p ls 3 t sprintf("D-SNES  {/Symbol D}T=%s", DT1),\
    snes_disp_2 u 1:($5)  w l ls 4 notitle, '' u 1:5 every 100 w p ls 4 t sprintf("D-SNES  {/Symbol D}T=%s", DT2),\
    snes_disp_3 u 1:($5)  w l ls 5 notitle, '' u 1:5 every 400 w p ls 5 t sprintf("D-SNES  {/Symbol D}T=%s", DT3),\
    snes_vel_1 u 1:($5)   w l ls 6 notitle, '' u 1:5 every 50 w p ls 6 t sprintf("V-SNES  {/Symbol D}T=%s", DT1),\
    snes_vel_2 u 1:($5)   w l ls 7 notitle, '' u 1:5 every 100 w p ls 7 t sprintf("V-SNES  {/Symbol D}T=%s", DT2),\
    snes_vel_3 u 1:($5)   w l ls 8 notitle, '' u 1:5 every 400 w p ls 8 t sprintf("V-SNES  {/Symbol D}T=%s", DT3)

# Mesh 4 - time-step behaviour
set output "mesh_4-dispComparison.pdf"
set label 1 "Mesh size: 17 556 cells" at graph 1.05,0.9 font ",10"

snes_disp_1 = sprintf("displacement-snes.mesh-4.deltaT-%s/postProcessing/0/solidPointDisplacement_pointDisp.dat", DT1)
snes_disp_2 = sprintf("displacement-snes.mesh-4.deltaT-%s/postProcessing/0/solidPointDisplacement_pointDisp.dat", DT2)
snes_disp_3 = sprintf("displacement-snes.mesh-4.deltaT-%s/postProcessing/0/solidPointDisplacement_pointDisp.dat", DT3)
snes_vel_1 = sprintf("velocity-snes.mesh-4.deltaT-%s/postProcessing/0/solidPointDisplacement_pointDisp.dat", DT1)
snes_vel_2 = sprintf("velocity-snes.mesh-4.deltaT-%s/postProcessing/0/solidPointDisplacement_pointDisp.dat", DT2)
snes_vel_3 = sprintf("velocity-snes.mesh-4.deltaT-%s/postProcessing/0/solidPointDisplacement_pointDisp.dat", DT3)

plot \
     NaN title "Greendshields paper" with l ls 2,\
    "../plotScripts/analyticalEndDeflection.txt" u 1:2 w p ls 1 notitle,\
    snes_disp_1 u 1:($5)  w l ls 3 notitle, '' u 1:5 every 50 w p ls 3 t sprintf("D-SNES  {/Symbol D}T=%s", DT1),\
    snes_disp_2 u 1:($5)  w l ls 4 notitle, '' u 1:5 every 100 w p ls 4 t sprintf("D-SNES  {/Symbol D}T=%s", DT2),\
    snes_disp_3 u 1:($5)  w l ls 5 notitle, '' u 1:5 every 400 w p ls 5 t sprintf("D-SNES  {/Symbol D}T=%s", DT3),\
    snes_vel_1 u 1:($5)   w l ls 6 notitle, '' u 1:5 every 50 w p ls 6 t sprintf("V-SNES  {/Symbol D}T=%s", DT1),\
    snes_vel_2 u 1:($5)   w l ls 7 notitle, '' u 1:5 every 100 w p ls 7 t sprintf("V-SNES  {/Symbol D}T=%s", DT2),\
    snes_vel_3 u 1:($5)   w l ls 8 notitle, '' u 1:5 every 400 w p ls 8 t sprintf("V-SNES  {/Symbol D}T=%s", DT3)