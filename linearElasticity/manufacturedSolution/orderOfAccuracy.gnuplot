# Attempt to retrieve the TIMES_FILE environment variable
# Note: you should source the USER_VARIABLE_NAMES file before running this
# script, i.e. "source USER_VARIABLE_NAMES && gnuplot dispErrors.gnuplot"
datafile = system("echo $TIMES_FILE.orderOfAccuracy")

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

set output "orderOfAccuracy.pdf"

#set size ratio 1

#set style line 1 linecolor rgb 'black' linetype 6 linewidth 1 ps 1
#set style line 2 linecolor rgb 'red' linetype 4 linewidth 1 ps 1 dashtype 2
#set style line 3 linecolor rgb 'blue' linetype 2 linewidth 1 ps 1 dashtype 3
#set style line 4 linecolor rgb 'green' linetype 1 linewidth 1 ps 1 dashtype 4

set grid
set xrange [1:200]
set yrange [0:3]
set xtics
set xtics add (5, 25, 50)
set ytics
set logscale x
#set logscale y
#set ytics 0.002
set xlabel "Average cell spacing (in mm)"
set ylabel "Order of Accuracy"
set key right top;

# Average mesh spacing of mesh1
dx=0.04

# Assume the mesh spacing is being halved for each succesive mesh
plot \
    datafile using (1e3*dx/(2**($0))):2 skip 1 w lp t "L_2 - Displacement", \
    datafile using (1e3*dx/(2**($0))):3 skip 1 w lp t "L_∞ - Displacement", \
    datafile using (1e3*dx/(2**($0))):4 skip 1 w lp t "L_2 - Stress", \
    datafile using (1e3*dx/(2**($0))):5 skip 1 w lp t "L_∞ - Stress"

