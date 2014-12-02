# !!!! Configure variables required in this Makefile !!!!
include config.mk
.PRECIOUS : %.sam %.bam %.vcf %.intervals %.grp %.nodup.bam %.bai
READGROUPS=0 1 2
CHROMOSOMES=1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 X Y M

CHR_SPLIT_BAM:=${shell perl -e '@F=split/\s+/,"${CHROMOSOMES}";print map{"chr$$_.split.bam "}@F'}
CHR_CHR_METRICS:=${shell perl -e '@F=split/\s+/,"${CHROMOSOMES}";print map{"chr$$_.chr.metrics "}@F'}
CHR_GATK_VCF:=${shell perl -e '@F=split/\s+/,"${CHROMOSOMES}";print map{"chr$$_.gatk.vcf "}@F'}
CHR_TAGGED_BAM:=${shell perl -e '@F=split/\s+/,"${CHROMOSOMES}";print map{"chr$$_.tagged.bam "}@F'}

all: samheaders qc all.vcf

clean:
	rm -f *.bam *.bai *.vcf *.grp *.intervals *.idx

samheaders:
	mkdir -p samheader
	#XXX hardcoded
	${TOOLS}/samtools/samtools view -H RG0.tagged.bam > samheader/RG0.header.sam
	perl ../bin/samheader_split.pl samheader/RG0.header.sam samheader/

qc: ${CHR_SPLIT_BAM}
	mkdir -p metrics
	${MAKE} ${CHR_CHR_METRICS}

%.base.sam : %.fq
	cat $< | ${TOOLS}/bwa/bwa mem ${ALIGN_BASE}/${ALIGN_GENOME} - | perl -ne 'chomp;print "$_";print "\tRG:Z:0" unless m/^@/;print "\n"' | ${TOOLS}/samtools/samtools sort -O sam -T /tmp/sam$$. | grep -vE '^@' > $@

%.tagged.sam : %.base.sam
	cat ${SAM_HEADER} $< | perl -ne 'chomp;print "$$_";print "\tRG:Z:'`echo $< | perl -ne "m#RG(\\d+)#;print qq(\\$$1)"`'" unless m/^@/;print "\n"' | ${TOOLS}/samtools/samtools sort -O sam -T /tmp/sam`date +%s`. | grep -vE '^@' > $@

%.tagged.bam : %.tagged.sam
	cat ${SAM_HEADER} $< | ${TOOLS}/samtools/samtools view -b - > $@
	${TOOLS}/samtools/samtools index $@

%.rg.metrics : %.tagged.bam
	ALIGN_BASE=${ALIGN_BASE}/${ALIGN_GENOME} TOOLS=${TOOLS} bash ../bin/picard_metrics.sh $<
	touch $@

%.chr.metrics : %.split.bam
	ALIGN_BASE=${ALIGN_BASE}/${@:.chr.metrics=.fa} TOOLS=${TOOLS} bash ../bin/picard_metrics.sh $<
	touch $@

all.bam :
	for i in ${RG}; do ${MAKE} RG$$i.tagged.bam; done
	if [ `ls RG*.tagged.bam | wc -w` gt 1 ]; then \
	  ${TOOLS}/samtools/samtools merge $@ `ls RG*.tagged.bam`; \
	else \
	  ln -s `ls RG*.tagged.bam` $@; \
	fi
	${TOOLS}/samtools/samtools index $@

####
chromosomes : ${CHR_SPLIT_BAM}
	#${CHR_CHR_METRICS}
	#for i in ${CHROMOSOMES}; do ${MAKE} chr$$i.split.bam; done
	#for i in ${CHROMOSOMES}; do ${MAKE} chr$$i.chr.metrics; done


%.split.bam : all.bam
	cat samheader/$(@:.split.bam=.samheader.sam) > $(@:.bam=.sam)
	${TOOLS}/samtools/samtools view $< $(@:.split.bam=) >> $(@:.bam=.sam)
	${TOOLS}/samtools/samtools view -b $(@:.bam=.sam) > $@
	${TOOLS}/samtools/samtools index $@
	rm -f $(@:.bam=.sam)

	#${TOOLS}/samtools/samtools view -b all.bam $(@:.split.bam=) > $@

	#cat ${SAM_HEADER} > $(@:.bam=.sam)
	#${TOOLS}/samtools/samtools view all.bam $(@:.split.bam=) >> $(@:.bam=.sam)
	#${TOOLS}/samtools/samtools view -b $(@:.bam=.sam) > $@
	#rm -f $(@:.bam=.sam)

%.nodup.bam : %.split.bam
	java -jar ${TOOLS}/picard/dist/picard.jar MarkDuplicates I=$< O=$@ M=metrics/${@:bam=}metrics VALIDATION_STRINGENCY=SILENT ASSUME_SORTED=true REMOVE_DUPLICATES=false
	${TOOLS}/samtools/samtools index $@

%.realn.intervals : %.nodup.bam
	java -jar ${TOOLS}/gatk-protected/target/GenomeAnalysisTK.jar -T RealignerTargetCreator -I $< -R ${ALIGN_BASE}/${ALIGN_GENOME} -o $@ -known ${ANNOTATION}/Mills_and_1000G_gold_standard.indels.hg19/${@:.realn.intervals=.vcf} -known ${ANNOTATION}/1000G_phase1.indels.hg19/${@:.realn.intervals=.vcf} -nt $(DATA_THREADS)

%.realn.bam : %.nodup.bam
	${MAKE} ${@:bam=intervals}
	java -jar ${TOOLS}/gatk-protected/target/GenomeAnalysisTK.jar -T IndelRealigner -I $< -R ${ALIGN_BASE}/${@:.realn.bam=.fa} -o $@ -targetIntervals ${@:bam=intervals} -known ${ANNOTATION}/Mills_and_1000G_gold_standard.indels.hg19/${@:.realn.bam=.vcf} -known ${ANNOTATION}/1000G_phase1.indels.hg19/${@:.realn.bam=.vcf}
	${TOOLS}/samtools/samtools index $@

%.recal.grp : %.realn.bam
	java -jar ${TOOLS}/gatk-protected/target/GenomeAnalysisTK.jar -T BaseRecalibrator -I $< -R ${ALIGN_BASE}/${@:.recal.grp=.fa} -o $@ -knownSites ${ANNOTATION}/Mills_and_1000G_gold_standard.indels.hg19/${@:.recal.grp=.vcf} -knownSites ${ANNOTATION}/1000G_phase1.indels.hg19/${@:.recal.grp=.vcf} -knownSites ${ANNOTATION}/dbsnp_137.hg19/${@:.recal.grp=.vcf} -nct $(CPU_THREADS)
#java -jar ..//gatk-protected/target/GenomeAnalysisTK.jar -T BaseRecalibrator -I chr22.realn.bam -R ../synthetic/chr22.fa -o chr22.recal.grp -knownSites ../vcf/Mills_and_1000G_gold_standard.indels.hg19/chr22.vcf -knownSites ../vcf/1000G_phase1.indels.hg19/chr22.vcf -knownSites ../vcf/dbsnp_137.hg19/chr22.vcf -nct 4

%.bqsr.bam : %.realn.bam
	${MAKE} ${@:bqsr.bam=recal.grp}
	java -jar ${TOOLS}/gatk-protected/target/GenomeAnalysisTK.jar -T PrintReads -I $< -R ${ALIGN_BASE}/${@:.bqsr.bam=.fa} -BQSR ${@:bqsr.bam=recal.grp} -o $@ -nct $(CPU_THREADS)
	${TOOLS}/samtools/samtools index $@

%.gatk.vcf : %.bqsr.bam
	# Use UnifiedGenotyper with -nt to parallelize 
	#java -jar ${TOOLS}/gatk-protected/target/GenomeAnalysisTK.jar -T HaplotypeCaller -R ${ALIGN_BASE}/${ALIGN_GENOME} -I $< --dbsnp ${ANNOTATION}/dbsnp_137.hg19.vcf -o $@ -stand_call_conf 20.0 -stand_emit_conf 10.0 -gt_mode DISCOVERY
	java -jar ${TOOLS}/gatk-protected/target/GenomeAnalysisTK.jar -T HaplotypeCaller -R ${ALIGN_BASE}/${@:.gatk.vcf=.fa} -I $< --dbsnp ${ANNOTATION}/dbsnp_137.hg19/${@:.gatk.vcf=.vcf} -o $@ -stand_call_conf 20.0 -stand_emit_conf 10.0 -gt_mode DISCOVERY

#XXX better to put CHR_GATK_VCF on first line for parallism, but some syntax problem needs to be investigated
all.vcf : ${CHR_GATK_VCF}
	java -jar ${TOOLS}/gatk-protected/target/GenomeAnalysisTK.jar -T CombineVariants -R ${ALIGN_BASE}/${ALIGN_GENOME} `for i in ${CHROMOSOMES}; do echo -n "--variant chr$$i.gatk.vcf "; done` -o $@ -genotypeMergeOptions UNIQUIFY -nt $(DATA_THREADS)

%.snp.vcf : %.vcf
	java -jar ${TOOLS}/gatk-protected/target/GenomeAnalysisTK.jar -T SelectVariants -R ${ALIGN_BASE}/${ALIGN_GENOME} -V $< -o $@ -selectType SNP -nt $(DATA_THREADS)

%.indel.vcf : %.vcf
	java -jar ${TOOLS}/gatk-protected/target/GenomeAnalysisTK.jar -T SelectVariants -R ${ALIGN_BASE}/${ALIGN_GENOME} -V $< -o $@ -selectType INDEL -nt $(DATA_THREADS)

%.snp.vqsr : %.snp.vcf
	java -jar ${TOOLS}/gatk-protected/target/GenomeAnalysisTK.jar -T VariantRecalibrator -R ${ALIGN_BASE}/${ALIGN_GENOME} -input $< \
	-resource:hapmap,known=false,training=true,truth=true,prior=15.0 ${ANNOTATION}/hapmap_3.3.hg19.vcf \
	-resource:omni,known=false,training=true,truth=true,prior=12.0 ${ANNOTATION}/1000G_omni2.5.hg19.vcf \
	-resource:1000G,known=false,training=true,truth=false,prior=10.0 ${ANNOTATION}/1000G_phase1.snps.high_confidence.hg19.vcf \
	-resource:dbsnp,known=true,training=false,truth=false,prior=2.0 ${ANNOTATION}/dbsnp_137.b37.unmangled.vcf \
	-mode SNP \
	-an DP \
	-an FS \
	-an ReadPosRankSum \
	-tranche 100.0 -tranche 99.9 -tranche 99.0 -tranche 90.0 \
	-recalFile outdir/SAMPLE.tmp.snp.vcf \
	-tranchesFile outdir/SAMPLE.tranches.gatk.snp.recal.csv \
	-rscriptFile outdir/SAMPLE.gatk.recal.snp.R \
	-nt $(DATA_THREADS)
	#-an MQRankSum \ #disabled for genome subset run.  must be re-enabled for whole genome
	#dbsnp.b37.vcf
