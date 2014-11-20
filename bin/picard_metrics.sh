#!/bin/bash
mkdir -p metrics
PREFIX=${1/.bam/}
OUTPUT="metrics/$PREFIX"

echo $PREFIX
echo $OUTPUT

for i in CollectGcBiasMetrics
do
  java -jar ${TOOLS}/picard/dist/picard.jar $i VERBOSITY=ERROR R=${ALIGN_BASE} I=$PREFIX.bam O=$OUTPUT.$i.out CHART=$OUTPUT.$i.pdf 2>$OUTPUT.$i.err
done;

for i in CollectOxoGMetrics CollectWgsMetrics
do
  java -jar ${TOOLS}/picard/dist/picard.jar $i VERBOSITY=ERROR R=${ALIGN_BASE} I=$PREFIX.bam O=$OUTPUT.$i.out 2>$OUTPUT.$i.err
done;

for i in CollectQualityYieldMetrics EstimateLibraryComplexity
do
  java -jar ${TOOLS}/picard/dist/picard.jar $i VERBOSITY=ERROR I=$PREFIX.bam O=$OUTPUT.$i.out 2>$OUTPUT.$i.err
done;

java -jar ${TOOLS}/picard/dist/picard.jar CollectMultipleMetrics \
  I=$PREFIX.bam \
  O=$OUTPUT. \
  R=${ALIGN_BASE} \
  PROGRAM=null \
  PROGRAM=CollectAlignmentSummaryMetrics \
  PROGRAM=CollectInsertSizeMetrics \
  PROGRAM=QualityScoreDistribution \
  PROGRAM=MeanQualityByCycle \
  PROGRAM=CollectBaseDistributionByCycle \
  2>$OUTPUT.CollectMultipleMetrics.err

#cannot  CalculateHsMetrics
#cannot  CollectHiSeqXPfFailMetrics
#cannot  CollectJumpingLibraryMetrics
#cannot  CollectRnaSeqMetrics
#cannot  CollectRrbsMetrics
#cannot  CollectTargetedPcrMetrics
