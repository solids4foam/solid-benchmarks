set term pdfcairo dashed enhanced

# Comparison slice defaults.
methods = "monolithic_default partitioned_Aitken"
timeStepMesh = "2"
meshTimeStep = "dt0p01"

# Method style: open circles for monolithic, open squares for Aitken.
set style line 1 lc rgb "#2166ac" lw 2 pt 6
set style line 2 lc rgb "#b2182b" lw 2 pt 4
pointSize(i) = 0.5 + 0.25*(i - 1)

dispFile(c) = sprintf("%s/postProcessing/0/solidPointDisplacement_tipDisplacement.dat", c)
timeStepCases(m) = system(sprintf("ls -d %s.m%s.dt*/ 2>/dev/null", m, timeStepMesh))
meshCases(m) = system(sprintf("ls -d %s.m*.%s/ 2>/dev/null", m, meshTimeStep))
selectedTimeStepCases = system(sprintf("for m in %s; do ls -d ${m}.m%s.dt*/ 2>/dev/null; done", methods, timeStepMesh))
selectedMeshCases = system(sprintf("for m in %s; do ls -d ${m}.m*.%s/ 2>/dev/null; done", methods, meshTimeStep))

set grid
set xlabel "Time (s)"
set ylabel "Flap-tip vertical displacement (m)"
set key outside

if (words(selectedTimeStepCases) > 0) {
    set output "displacementVsTime_timeSteps_m".timeStepMesh.".pdf"
    plot for [i=1:words(methods)] \
         for [j=1:words(timeStepCases(word(methods, i)))] \
        dispFile(word(timeStepCases(word(methods, i)), j)) \
        u 1:3 w lp ls i ps pointSize(j) \
        title word(timeStepCases(word(methods, i)), j)
} else {
    print "Skipping displacement time-step comparison: no mesh m", timeStepMesh, " cases for ", methods
}

if (words(selectedMeshCases) > 0) {
    set output "displacementVsTime_meshes_".meshTimeStep.".pdf"
    plot for [i=1:words(methods)] \
         for [j=1:words(meshCases(word(methods, i)))] \
        dispFile(word(meshCases(word(methods, i)), j)) \
        u 1:3 w lp ls i ps pointSize(j) \
        title word(meshCases(word(methods, i)), j)
} else {
    print "Skipping displacement mesh comparison: no ", meshTimeStep, " cases for ", methods
}
