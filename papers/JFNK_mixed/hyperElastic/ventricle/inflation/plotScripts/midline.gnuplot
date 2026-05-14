set term pdfcairo dashed enhanced
set datafile separator " "

set size ratio -1
set grid
set xrange [-13.5:0]
set yrange [-28:5]
set xtics 5
set ytics
set xlabel "x (in mm)"
set ylabel "z (in mm)"
set key outside left center

methods = "rhiechow jst evenlap_m1"
titles = "RhieChow JST EvenLap_m1"

do for [mesh=1:4] {
    set output sprintf("ventricleInflation-midline-mesh%d.pdf", mesh)
    plot for [idx=1:words(methods)] \
        sprintf("hex_snes__%s.%d/midLineDeformed.txt", word(methods, idx), mesh) \
        u (1e3*$1):(1e3*$3) every 9::0 w lp pt (idx + 4) ps 0.7 lw 1.2 \
        t word(titles, idx)
}

set xrange [-5:0]
set yrange [-28:-25]
set size ratio 1
do for [mesh=1:4] {
    set output sprintf("ventricleInflation-midline-apex-mesh%d.pdf", mesh)
    plot for [idx=1:words(methods)] \
        sprintf("hex_snes__%s.%d/midLineDeformed.txt", word(methods, idx), mesh) \
        u (1e3*$1):(1e3*$3) w lp pt (idx + 4) ps 0.7 lw 1.2 \
        t word(titles, idx)
}

set xrange [-13.4:-12.4]
set yrange [-9:-2]
set xtics 0.5
set size ratio 1
do for [mesh=1:4] {
    set output sprintf("ventricleInflation-midline-inflection-mesh%d.pdf", mesh)
    plot for [idx=1:words(methods)] \
        sprintf("hex_snes__%s.%d/midLineDeformed.txt", word(methods, idx), mesh) \
        u (1e3*$1):(1e3*$3) w lp pt (idx + 4) ps 0.7 lw 1.2 \
        t word(titles, idx)
}
