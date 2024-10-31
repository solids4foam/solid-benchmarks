# Attempt to retrieve the TIMES_FILE environment variable
# Note: you should source the USER_VARIABLE_NAMES file before running this
# script, i.e. "source USER_VARIABLE_NAMES && gnuplot dispErrors.gnuplot"
datafile = system("echo $TIMES_FILE")

# Check if TIMES_FILE is not defined or is an empty string
if (strlen(datafile) == 0) {
    print "Error: TIMES_FILE environment variable is not defined."
    print "You should source the USER_VARIABLE_NAMES file first"
    print "e.g. source USER_VARIABLE_NAMES && gnuplot dispErrors.gnuplot"
    exit
} else {
    print "Data file is: ", datafile
}

set term pdfcairo dashed enhanced
set datafile separator " "

set output "dispErrors.pdf"

#set size ratio 1

#set style line 1 linecolor rgb 'black' linetype 6 linewidth 1 ps 1
#set style line 2 linecolor rgb 'red' linetype 4 linewidth 1 ps 1 dashtype 2
#set style line 3 linecolor rgb 'blue' linetype 2 linewidth 1 ps 1 dashtype 3
#set style line 4 linecolor rgb 'green' linetype 1 linewidth 1 ps 1 dashtype 4

set grid
set xrange [1:60]
#set yrange [-0.026:0.002]
set xtics
set xtics add (5, 25, 50)
set ytics
set logscale x
set logscale y
#set ytics 0.002
set xlabel "Average cell spacing (in mm)"
set ylabel "Error (in μm)"
set key left top;

# Average mesh spacing of mesh1
dx=0.04

# Assume the mesh spacing is being halved for each succesive mesh
plot \
    datafile u (1e3*dx/(2**($0))):(1e6*$4) w lp t "L_2", \
    datafile u (1e3*dx/(2**($0))):(1e6*$5) w lp t "L_∞", \
    "orderOfAccuracySlopesDisp.dat" u 1:2 w l t "1^{st} order", \
    "orderOfAccuracySlopesDisp.dat" u 1:3 w l t "2^{nd} order"

