set term pdfcairo dashed enhanced

# Comparison slice defaults.
methods = "monolithic_default partitioned_Aitken"
timeStepMesh = "2"
meshTimeStep = "dt0p01"

# Method style: open circles for monolithic, open squares for Aitken.
set style line 1 lc rgb "#2166ac" lw 2 pt 6
set style line 2 lc rgb "#b2182b" lw 2 pt 4
pointSize(i) = 0.5 + 0.25*(i - 1)

forceFile(c) = sprintf("%s/postProcessing/fluid/fluidForces/0/force.dat", c)
timeStepCases(m) = system(sprintf("ls -d %s.m%s.dt*/ 2>/dev/null", m, timeStepMesh))
meshCases(m) = system(sprintf("ls -d %s.m*.%s/ 2>/dev/null", m, meshTimeStep))
selectedTimeStepCases = system(sprintf("for m in %s; do ls -d ${m}.m%s.dt*/ 2>/dev/null; done", methods, timeStepMesh))
selectedMeshCases = system(sprintf("for m in %s; do ls -d ${m}.m*.%s/ 2>/dev/null; done", methods, meshTimeStep))

set grid
set xlabel "Time (s)"
set ylabel "Fluid interface F_y (N)"
set key outside

if (words(selectedTimeStepCases) > 0) {
    set output "forceVsTime_timeSteps_m".timeStepMesh.".pdf"
    plot for [i=1:words(methods)] \
         for [j=1:words(timeStepCases(word(methods, i)))] \
        forceFile(word(timeStepCases(word(methods, i)), j)) \
        u 1:3 w lp ls i ps pointSize(j) \
        title word(timeStepCases(word(methods, i)), j)
} else {
    print "Skipping force time-step comparison: no mesh m", timeStepMesh, " cases for ", methods
}

if (words(selectedMeshCases) > 0) {
    set output "forceVsTime_meshes_".meshTimeStep.".pdf"
    plot for [i=1:words(methods)] \
         for [j=1:words(meshCases(word(methods, i)))] \
        forceFile(word(meshCases(word(methods, i)), j)) \
        u 1:3 w lp ls i ps pointSize(j) \
        title word(meshCases(word(methods, i)), j)
} else {
    print "Skipping force mesh comparison: no ", meshTimeStep, " cases for ", methods
}
