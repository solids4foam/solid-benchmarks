set term pdfcairo dashed enhanced
if (ARGC < 1) {
    print "Error: No input summary provided."
    print "usage: ", ARG0, " <campaignSummary.tsv>"
    exit
} else {
    summary = ARG1
}

set output "campaignForceVsTime.pdf"

files = system(sprintf("awk 'NF && $1 !~ /^#/ && $8 == \"completed\" {print $19}' %s", summary))
labels = system(sprintf("awk 'NF && $1 !~ /^#/ && $8 == \"completed\" {print $4}' %s", summary))

set grid
set xrange [0:*]
set xlabel "Time (s)"
set ylabel "Interface force x (N)"
set key outside right

plot for [i=1:words(files)] word(files, i) u 1:2 w l lw 2 title word(labels, i)
