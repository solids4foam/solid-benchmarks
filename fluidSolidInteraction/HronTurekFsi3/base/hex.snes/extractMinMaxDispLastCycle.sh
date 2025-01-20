#!/bin/bash

# Note: the time is set manually below to isolate the min and max
# peaks of the last period

echo; echo "Dx"
awk 'BEGIN {
    minDx = 1e+30; maxDx = -1e+30;
}
function abs(x) { return (x < 0 ? -x : x) }
$1 > 19.9 {
    if ($2 < minDx) { minDx = $2; timeMinDx = $1; }
    if ($2 > maxDx) { maxDx = $2; timeMaxDx = $1; }
} 
END { 
    # Amplitude
    amp = (maxDx - minDx)/2.0;

    # Mean
    mean = (maxDx + minDx)/2.0;

    # Period and frequency
    period = 2.0*abs(timeMinDx - timeMaxDx);
    frequency = 1.0/period;

    print "Min Dx:", minDx, "at time:", timeMinDx; 
    print "Max Dx:", maxDx, "at time:", timeMaxDx; 
    print "Mean:", mean, "Amplitude:",  amp, "Frequency:", frequency;
}' postProcessing/0/solidPointDisplacement_pointDisp.dat

echo; echo "Dy"
awk 'BEGIN {
    minDy = 1e+30; maxDy = -1e+30;
}
function abs(x) { return (x < 0 ? -x : x) }
$1 > 19.8 {
    if ($3 < minDy) { minDy = $3; timeMinDy = $1; }
    if ($3 > maxDy) { maxDy = $3; timeMaxDy = $1; }
} 
END {

    # Amplitude
    amp = (maxDy - minDy)/2.0;

    # Mean
    mean = (maxDy + minDy)/2.0;

    # Period and frequency
    period = 2.0*abs(timeMinDy - timeMaxDy);
    frequency = 1.0/period;

    print "Min Dy:", minDy, "at time:", timeMinDy, "amplitude:",  amp, "mean:", mean; 
    print "Max Dy:", maxDy, "at time:", timeMaxDy;
    print "Mean:", mean, "Amplitude:",  amp, "Frequency:", frequency;
}' postProcessing/0/solidPointDisplacement_pointDisp.dat

echo
