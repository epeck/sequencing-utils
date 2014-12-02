#!/bin/bash
mkdir -p metrics
PREFIX=${1/.bam/}
OUTPUT="metrics/$PREFIX"

for i in CollectGcBiasMetrics
do
  java -jar ${TOOLS}/picard/dist/picard.jar $i \
    I=$PREFIX.bam \
    R=${ALIGN_BASE} \
    VALIDATION_STRINGENCY=LENIENT \
    VERBOSITY=INFO \
    O=$OUTPUT.$i.out \
    CHART=$OUTPUT.$i.pdf \
    2>$OUTPUT.$i.err
done;

for i in CollectOxoGMetrics CollectWgsMetrics
do
  java -jar ${TOOLS}/picard/dist/picard.jar $i \
    I=$PREFIX.bam \
    R=${ALIGN_BASE} \
    VALIDATION_STRINGENCY=LENIENT \
    VERBOSITY=INFO \
    O=$OUTPUT.$i.out \
    2>$OUTPUT.$i.err
done;

for i in CollectQualityYieldMetrics EstimateLibraryComplexity
do
  java -jar ${TOOLS}/picard/dist/picard.jar $i \
    I=$PREFIX.bam \
    VALIDATION_STRINGENCY=LENIENT \
    VERBOSITY=INFO \
    O=$OUTPUT.$i.out \
    2>$OUTPUT.$i.err
done;

java -jar ${TOOLS}/picard/dist/picard.jar CollectMultipleMetrics \
  I=$PREFIX.bam \
  R=${ALIGN_BASE} \
  VALIDATION_STRINGENCY=LENIENT \
  VERBOSITY=INFO \
  O=$OUTPUT. \
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
