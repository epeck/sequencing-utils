#!/bin/bash
mkdir -p metrics
PREFIX=${1/.bam/}
OUTPUT="metrics/$PREFIX"

for i in CollectGcBiasMetrics
do
  echo -n "$i...";
  java -jar ${TOOLS}/picard/dist/picard.jar $i \
    I=$PREFIX.bam \
    R=${ALIGN_BASE} \
    VALIDATION_STRINGENCY=LENIENT \
    VERBOSITY=INFO \
    O=$OUTPUT.$i.out \
    CHART=$OUTPUT.$i.pdf \
    2>$OUTPUT.$i.err
  echo "done";
done;

for i in CollectOxoGMetrics CollectWgsMetrics
do
  echo -n "$i...";
  java -jar ${TOOLS}/picard/dist/picard.jar $i \
    I=$PREFIX.bam \
    R=${ALIGN_BASE} \
    VALIDATION_STRINGENCY=LENIENT \
    VERBOSITY=INFO \
    O=$OUTPUT.$i.out \
    2>$OUTPUT.$i.err
  echo "done";
done;

for i in CollectQualityYieldMetrics EstimateLibraryComplexity
do
  echo -n "$i...";
  java -jar ${TOOLS}/picard/dist/picard.jar $i \
    I=$PREFIX.bam \
    VALIDATION_STRINGENCY=LENIENT \
    VERBOSITY=INFO \
    O=$OUTPUT.$i.out \
    2>$OUTPUT.$i.err
  echo "done";
done;

for i in CollectAlignmentSummaryMetrics CollectInsertSizeMetrics QualityScoreDistribution MeanQualityByCycle CollectBaseDistributionByCycle
do
  echo -n "CollectMultipleMetrics.$i...";
  java -jar ${TOOLS}/picard/dist/picard.jar CollectMultipleMetrics \
    I=$PREFIX.bam \
    R=${ALIGN_BASE} \
    VALIDATION_STRINGENCY=LENIENT \
    VERBOSITY=INFO \
    O=$OUTPUT. \
    PROGRAM=null \
    PROGRAM=$i \
    2>$OUTPUT.CollectMultipleMetrics.$i.err
  echo "done";
done;

#cannot  CalculateHsMetrics
#cannot  CollectHiSeqXPfFailMetrics
#cannot  CollectJumpingLibraryMetrics
#cannot  CollectRnaSeqMetrics
#cannot  CollectRrbsMetrics
#cannot  CollectTargetedPcrMetrics
