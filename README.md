sequencing-utils
================

1. run "make all" - download and build deps


_NOTES_

#look at Sam file
samtools/samtools view ~/data/NA12878.bam | less
#capture read group 1 to new bam file
samtools/samtools view -h ~/data/NA12878.bam | grep 'RG:Z:1' | samtools/samtools view -b - > RG1.bam

