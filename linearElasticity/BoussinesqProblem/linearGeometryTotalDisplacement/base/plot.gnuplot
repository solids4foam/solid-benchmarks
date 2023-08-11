#------------------------------------------------------------------------------#
#                               Input settings
#------------------------------------------------------------------------------#

F = -400000       # Force (N)
E = 1000e6        # Young modul (Pa)
nu = 0.3          # Poisson's ratio

#------------------------------------------------------------------------------#
#                           Displacement profile
#------------------------------------------------------------------------------#

reset

set term pngcairo dashed font "Arial,20" size 1520,1080
set output 'displacementProfile.png'

set style line 1 linecolor rgb 'red' linetype 6 linewidth 2 ps 2
set style line 2 linecolor rgb 'black' linetype 6 linewidth 2 ps 2

set grid
set xlabel 'z [m]'
set ylabel 'u_z [m]'
set title 'Displacement profile at x=0,y=0'
set key right bottom

set xrange [0:1]
set yrange [-0.02:0.002]
set ytics 0.004
set xtics 0.25
set samples 800, 800

G=E/(2.0*(1.0+nu))
u(x)=((F/(4.0*G*pi))*(x**2/x**3+(2*(1-nu))/x))

plot [0:1]  u(x) w l ls 1 title'analytical u_z',\
    "./postProcessing/sets/1/line_D.xy" u ($3*-1.0):6 w lp ls 2 title'linearGeometryTotalDisplacement'

set output

#------------------------------------------------------------------------------#
#                              Stress profile
#------------------------------------------------------------------------------#

reset
set term pngcairo dashed font "Arial,20" size 1520,1080
set output 'stressProfile.png'

set style line 1 linecolor rgb 'red' linetype 7 linewidth 2 ps 2
set style line 2 linecolor rgb 'black' linetype 6 linewidth 2 ps 2

set grid
set xlabel 'z [m]'
set ylabel '{/Symbol s}_{zz} [MPa]'
set title '{/Symbol s}_{zz} stress profile at x=0,y=0'
set key right bottom 

set xrange [0:1]
set yrange [-600:20]
set ytics 50
set xtics 0.25
set samples 800, 800

sigmaz(x)= (F*3.0*x**3)/(2*pi*x**5)

plot [0:1] sigmaz(x)/1e6 w l ls 1 title'analytical {/Symbol s}_{zz}',\
    "./postProcessing/sets/1/line_sigma.xy" u ($3*-1.0):($9/1e6) w lp ls 2 title'linearGeometryTotalDisplacement'

set output



