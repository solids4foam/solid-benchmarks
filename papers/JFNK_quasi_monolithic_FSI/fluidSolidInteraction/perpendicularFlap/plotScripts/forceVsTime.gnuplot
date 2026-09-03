set term pdfcairo dashed enhanced

# Comparison slice defaults.
methods = "monolithic_default partitioned_Aitken"
timeStepMesh = "2"
meshTimeStep = "dt0p0025"

# Method style: open circles for monolithic, open squares for Aitken.
set style line 1 lc rgb "#2166ac" lw 1 pt 6
set style line 2 lc rgb "#b2182b" lw 1 pt 4
pointSize(i) = 1.0 - 0.2*(i - 1)

forceFile(c) = sprintf("%s/postProcessing/fluid/fluidForces/0/force.dat", c)
timeStepCases(m) = system(sprintf("ls -d %s.m%s.dt*/ 2>/dev/null", m, timeStepMesh))
meshCases(m) = system(sprintf("ls -d %s.m*.%s/ 2>/dev/null", m, meshTimeStep))
selectedTimeStepCases = system(sprintf("for m in %s; do ls -d ${m}.m%s.dt*/ 2>/dev/null; done", methods, timeStepMesh))
selectedMeshCases = system(sprintf("for m in %s; do ls -d ${m}.m*.%s/ 2>/dev/null; done", methods, meshTimeStep))
meshLegend(c) = system(sprintf("echo '%s' | sed -E 's/^monolithic_[^.]+\\.(m[0-9]+)\\..*/monolithic \\1/; s/^partitioned_[^.]+\\.(m[0-9]+)\\..*/partitioned \\1/'", c))
dtLegend(c) = system(sprintf("echo '%s' | sed -E 's/^monolithic_[^.]+\\.m[0-9]+\\.dt0p([0-9]+).*/monolithic DT=0.\\1/; s/^partitioned_[^.]+\\.m[0-9]+\\.dt0p([0-9]+).*/partitioned DT=0.\\1/'", c))
dtValue(s) = system(sprintf("echo '%s' | sed -E 's/^dt0p([0-9]+)$/0.\\1/'", s))

set grid
set xlabel "Time (s)" offset 0,1
set ylabel "Fluid interface F_y (N)"
set xtics 1
set yrange [15000:50000]
#set key inside top right

set bmargin 5
set key outside bottom center horizontal maxcols 3 maxrows 2 font ",8"

if (words(selectedTimeStepCases) > 0) {
    set output "forceVsTime_timeSteps.pdf"
    set title "Force convergence for different time-steps on mesh ".timeStepMesh.""
    plot for [i=1:words(methods)] \
         for [j=1:words(timeStepCases(word(methods, i)))] \
        forceFile(word(timeStepCases(word(methods, i)), j)) \
        u 1:3 w lp ls i ps pointSize(j) pi 50 \
        title dtLegend(word(timeStepCases(word(methods, i)), j))
} else {
    print "Skipping force time-step comparison: no mesh m", timeStepMesh, " cases for ", methods
}

if (words(selectedMeshCases) > 0) {
    set output "forceVsTime_meshes.pdf"
    set title "Force convergence on different meshes for DT=".dtValue(meshTimeStep).""
    plot for [i=1:words(methods)] \
         for [j=1:words(meshCases(word(methods, i)))] \
        forceFile(word(meshCases(word(methods, i)), j)) \
        u 1:3 w lp ls i ps pointSize(j) pi 50 \
        title meshLegend(word(meshCases(word(methods, i)), j))
} else {
    print "Skipping force mesh comparison: no ", meshTimeStep, " cases for ", methods
}
