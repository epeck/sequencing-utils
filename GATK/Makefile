.PRECIOUS : %.sam %.bam %.vcf %.intervals %.grp
SAM_HEADER=../../../NA12878/NA12878.new_header.sam
ALIGN_BASE=../../../hg19/hg19.fa
ANNOTATION=../../../vcf
TOOLS=../../../tools

%.base.sam : %.fq
	cat $< | ${TOOLS}/bwa/bwa mem hg19/hg19.fa - | perl -ne 'chomp;print "$_";print "\tRG:Z:0" unless m/^@/;print "\n"' | ${TOOLS}/samtools/samtools sort -O sam -T /tmp/sam$$. | grep -vE '^@' > $@

%.tagged.sam : %.base.sam
	cat ${SAM_HEADER} $< | perl -ne 'chomp;print "$$_";print "\tRG:Z:'`echo $< | perl -ne "m#RG(\\d+)#;print qq(\\$$1)"`'" unless m/^@/;print "\n"' | ${TOOLS}/samtools/samtools sort -O sam -T /tmp/sam`date +%s`. | grep -vE '^@' > $@

%.tagged.bam : %.tagged.sam
	cat ${SAM_HEADER} $< | ${TOOLS}/samtools/samtools view -b - > $@
	${TOOLS}/samtools/samtools index $@

%.rg.metrics : %.tagged.bam
	ALIGN_BASE=${ALIGN_BASE} TOOLS=${TOOLS} sh ../bin/picard_metrics.sh $<
	touch $@

%.chr.metrics : %.split.bam
	ALIGN_BASE=${ALIGN_BASE} TOOLS=${TOOLS} sh ../bin/picard_metrics.sh $<
	touch $@

all.bam :
	for i in 0 1 2; do ${MAKE} RG$$i.tagged.bam; done
	${TOOLS}/samtools/samtools merge $@ RG*.tagged.bam
	${TOOLS}/samtools/samtools index $@

####
chromosomes : chr22.split.bam chrY.split.bam chrM.split.bam


%.split.bam : all.bam
	${TOOLS}/samtools/samtools view -b all.bam $(@:.split.bam=) > $@

%.nodup.bam : %.split.bam
	java -jar ${TOOLS}/picard/dist/picard.jar MarkDuplicates I=$< O=$@ M=metrics/${@:bam=}metrics VALIDATION_STRINGENCY=SILENT ASSUME_SORTED=true REMOVE_DUPLICATES=false
	${TOOLS}/samtools/samtools index $@

%.realn.intervals : %.nodup.bam
	java -jar ${TOOLS}/gatk-protected/target/GenomeAnalysisTK.jar -T RealignerTargetCreator -I $< -R ${ALIGN_BASE} -o $@ -known ${ANNOTATION}/Mills_and_1000G_gold_standard.indels.hg19.vcf -known ${ANNOTATION}/1000G_phase1.indels.hg19.vcf

%.realn.bam : %.nodup.bam
	${MAKE} ${@:bam=intervals}
	java -jar ${TOOLS}/gatk-protected/target/GenomeAnalysisTK.jar -T IndelRealigner -I $< -R ${ALIGN_BASE} -o $@ -targetIntervals ${@:bam=intervals} -known ${ANNOTATION}/Mills_and_1000G_gold_standard.indels.hg19.vcf -known ${ANNOTATION}/1000G_phase1.indels.hg19.vcf
	${TOOLS}/samtools/samtools index $@

%.recal.grp : %.realn.bam
	java -jar ${TOOLS}/gatk-protected/target/GenomeAnalysisTK.jar -T BaseRecalibrator -I $< -R ${ALIGN_BASE} -o $@ -knownSites ${ANNOTATION}/Mills_and_1000G_gold_standard.indels.hg19.vcf -knownSites ${ANNOTATION}/1000G_phase1.indels.hg19.vcf -knownSites ${ANNOTATION}/dbsnp_137.hg19.vcf

%.bqsr.bam : %.realn.bam
	${MAKE} ${@:bqsr.bam=recal.grp}
	java -jar ${TOOLS}/gatk-protected/target/GenomeAnalysisTK.jar -T PrintReads -I $< -R ${ALIGN_BASE} -BQSR ${@:bqsr.bam=recal.grp} -o $@
	${TOOLS}/samtools/samtools index $@

%.gatk.vcf : %.bqsr.bam
	java -jar ${TOOLS}/gatk-protected/target/GenomeAnalysisTK.jar -T HaplotypeCaller -R ${ALIGN_BASE} -I $< --dbsnp ${ANNOTATION}/dbsnp_137.hg19.vcf -o $@ -stand_call_conf 20.0 -stand_emit_conf 10.0 -gt_mode DISCOVERY

all.vcf :
	for i in Y M 22; do ${MAKE} chr$$i.gatk.vcf; done
	java -jar ${TOOLS}/gatk-protected/target/GenomeAnalysisTK.jar -T CombineVariants -R ${ALIGN_BASE} `for i in M Y 22; do echo -n "--variant chr$$i.gatk.vcf "; done` -o $@ -genotypeMergeOptions UNIQUIFY

%.snp.vcf : %.vcf
	java -jar ${TOOLS}/gatk-protected/target/GenomeAnalysisTK.jar -T SelectVariants -R ${ALIGN_BASE} -V $< -o $@ -selectType SNP

%.indel.vcf : %.vcf
	java -jar ${TOOLS}/gatk-protected/target/GenomeAnalysisTK.jar -T SelectVariants -R ${ALIGN_BASE} -V $< -o $@ -selectType INDEL

%.snp.vqsr : %.snp.vcf
	java -jar ${TOOLS}/gatk-protected/target/GenomeAnalysisTK.jar -T VariantRecalibrator -R ${ALIGN_BASE} -input $< \
	-resource:hapmap,known=false,training=true,truth=true,prior=15.0 ${ANNOTATION}/hapmap_3.3.hg19.vcf \
	-resource:omni,known=false,training=true,truth=true,prior=12.0 ${ANNOTATION}/1000G_omni2.5.hg19.vcf \
	-resource:1000G,known=false,training=true,truth=false,prior=10.0 ${ANNOTATION}/1000G_phase1.snps.high_confidence.hg19.vcf \
	-resource:dbsnp,known=true,training=false,truth=false,prior=2.0 ${ANNOTATION}/dbsnp_137.b37.vcf \
	-mode SNP -an DP -an FS -an ReadPosRankSum -an MQRankSum \
	-tranche 100.0 -tranche 99.9 -tranche 99.0 -tranche 90.0 \
	-recalFile outdir/SAMPLE.tmp.snp.vcf \
	-tranchesFile outdir/SAMPLE.tranches.gatk.snp.recal.csv \
	-rscriptFile outdir/SAMPLE.gatk.recal.snp.R
	#dbsnp.b37.vcf

