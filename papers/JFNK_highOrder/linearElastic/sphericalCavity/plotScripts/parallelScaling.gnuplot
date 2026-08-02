set term pdfcairo dashed enhanced size 3.25, 2
set datafile separator " "

dataFile = "parallelScaling.summary.txt"

set grid
set xrange [1:*]
set yrange [0:*]
set xtics 1
set ytics
set xlabel "Number of processors"
set ylabel "Speedup"
set key left top
set key spacing 1.2

set style line 11 lc rgb "red"    pt 7 ps 0.5 lw 1
set style line 21 lc rgb "blue"   pt 5 ps 0.5 lw 1
set style line 31 lc rgb "violet" pt 9 ps 0.5 lw 1
set style line 41 lc rgb "black"  lt 2 lw 1 dt 2

meshes = system("awk 'NF && $1 !~ /^#/ {print $2}' ".dataFile." | sort -n | uniq")

do for [i=1:words(meshes)] {
    mesh = word(meshes, i) + 0

    set output sprintf("sphericalCavity_parallelScaling_mesh%d.pdf", mesh)
    set title sprintf("Mesh %d", mesh)

    plot \
        x w l ls 41 title "ideal", \
        dataFile u (($2 == mesh && strstrt(strcol(1), ".N1") > 0) ? $3 : 1/0):5 w lp ls 11 title "{/Times-Italic p}_{ }=1", \
        dataFile u (($2 == mesh && strstrt(strcol(1), ".N2") > 0) ? $3 : 1/0):5 w lp ls 21 title "{/Times-Italic p}_{ }=2", \
        dataFile u (($2 == mesh && strstrt(strcol(1), ".N3") > 0) ? $3 : 1/0):5 w lp ls 31 title "{/Times-Italic p}_{ }=3"
}
