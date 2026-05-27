set term pdfcairo dashed enhanced

summary = "campaignSummary.tsv"

set datafile commentschars "#"
set key top right
set grid
set logscale x
set logscale y
set xlabel "{/Symbol D}t (s)"
set xrange [0.001:0.1]
set format x "%g"

methods = "monolithic.default monolithic.schurTuned monolithic.physicsPC partitioned.IQNILS partitioned.Aitken"
costMethods = "monolithic.default partitioned.Aitken"
meshes = "1 2 3"
ok(s) = (s eq "completed")
costMethodTitle(m) = (m eq "monolithic.default") ? "monolithic default" : "partitioned Aitken"

pointSize(i) = 1.0 - 0.2*(i - 1)
set style line 1 lc rgb "#2166ac" lw 2 pt 6
set style line 2 lc rgb "#b2182b" lw 2 pt 4
set bmargin 5
set key outside bottom center horizontal maxcols 3 maxrows 2 font ",8"

set output "campaignTimeStepCost.pdf"
set ylabel "Wall time (h)"
plot for [i=1:words(costMethods)] \
         for [j=1:words(meshes)] summary \
            u ((strcol(2).".".strcol(3) eq word(costMethods, i) && strcol(5) eq word(meshes, j) && ok(strcol(7))) ? $6 : 1/0):($10/3600) \
            w lp ls i ps pointSize(j) title costMethodTitle(word(costMethods, i))." m".word(meshes, j)
