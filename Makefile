#brew install ant cmake wget zlib-devel ncurses-devel ant-nodeps
#JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk1.7.0_71.jdk/Contents/Home
MAVEN_OPTS="-Xmx1g -XX:MaxPermSize=512m"
CHROMOSOMES=1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 X Y M
GITHUB_USER=allenday
PROJECTS=htslib samtools bwa htsjdk picard gatk adam bamtools gatk-protected

all:
	${MAKE} htslib.built
	${MAKE} samtools.built
	${MAKE} bwa.built
	${MAKE} htsjdk.built
	${MAKE} picard.built
	${MAKE} adam.built
	#unused ${MAKE} bamtools.built
	${MAKE} gatk.built
	${MAKE} gatk-protected.built

clean:
	rm -rf ${PROJECTS}
	rm -rf *.built

htslib.built:
	git clone git@github.com:${GITHUB_USER}/htslib.git
	${MAKE} -C htslib all #test
	touch $@

samtools.built:
	git clone git@github.com:${GITHUB_USER}/samtools.git
	${MAKE} -C samtools all #test
	touch $@

bwa.built:
	git clone git@github.com:${GITHUB_USER}/bwa.git
	${MAKE} -C bwa all
	touch $@

htsjdk.built:
	git clone git@github.com:${GITHUB_USER}/htsjdk.git
	cd htsjdk && ant && cd .. #test
	touch $@

picard.built:
	git clone git@github.com:${GITHUB_USER}/picard.git
	#don't build test, it fails
	cd picard && ln -s ../htsjdk ./ && ant && cd ..
	touch $@

gatk.built:
	git clone git@github.com:${GITHUB_USER}/gatk.git
	cd gatk && mvn package install && cd ..
	touch $@

adam.built:
	echo ${MAVEN_OPTS}
	git clone git@github.com:${GITHUB_USER}/adam.git
	cd adam && mvn package install && cd ..
	touch $@

bamtools.built:
	git clone git@github.com:${GITHUB_USER}/bamtools.git
	cd bamtools && mkdir build && cd build && cmake .. && make && cd ../..
	touch $@

gatk-protected.built:
	git clone git@github.com:${GITHUB_USER}/gatk-protected.git
	cd gatk-protected && mvn package install && cd ..
	touch $@

####
#chromosome files

genome:
	mkdir -p hg19
	for i in ${CHROMOSOMES}; do wget -c -O - "http://hgdownload.cse.ucsc.edu/goldenPath/hg19/chromosomes/chr$$i.fa.gz" | zcat > hg19/chr$$i.fa; done
	rm -f hg19/hg19.fa
	for i in ${CHROMOSOMES}; do cat hg19/chr$$i.fa >> hg19/hg19.fa; done
	java -jar ./picard/dist/picard.jar CreateSequenceDictionary R=hg19/hg19.fa O=hg19/hg19.dict
	./samtools/samtools faidx hg19/hg19.fa
	./bwa/bwa index hg19/hg19.fa
	#for i in chr*.fa; do ../samtools/samtools faidx $i ; done
	#for i in chr*.fa; do  java -jar ../picard/dist/picard.jar CreateSequenceDictionary R=../synthetic/$i O=../synthetic/${i/fa/dict}; done


####
#annotation files

annotation:
	mkdir -p vcf
	${MAKE} vcf/1000G_omni2.5.hg19.vcf
	${MAKE} vcf/1000G_phase1.indels.hg19.vcf
	${MAKE} vcf/1000G_phase1.snps.high_confidence.hg19.vcf
	${MAKE} vcf/dbsnp_135.hg19.excluding_sites_after_129.vcf
	${MAKE} vcf/dbsnp_137.b37.unmangled.vcf
	${MAKE} vcf/dbsnp_137.hg19.vcf
	${MAKE} vcf/hapmap_3.3.hg19.vcf
	${MAKE} vcf/Mills_and_1000G_gold_standard.indels.hg19.vcf

vcf/1000G_omni2.5.hg19.vcf:
	wget -c -O - 'https://usegalaxy.org/library_common/download_dataset_from_folder?library_id=f9ba60baa2e6ba6d&cntrller=library&use_panels=False&id=78ece2fee875c263' > $@

vcf/1000G_phase1.indels.hg19.vcf:
	wget -c -O - 'https://usegalaxy.org/library_common/download_dataset_from_folder?library_id=f9ba60baa2e6ba6d&cntrller=library&use_panels=False&id=85d224941c9114fd' > $@

vcf/1000G_phase1.snps.high_confidence.hg19.vcf:
	wget -c -O - 'http://orione.crs4.it/library_common/download_dataset_from_folder?library_id=c6107057926ff452&cntrller=library&use_panels=False&id=26975315af6d33a8' > $@

vcf/dbsnp_135.hg19.excluding_sites_after_129.vcf:
	wget -c -O - 'https://usegalaxy.org/library_common/download_dataset_from_folder?library_id=f9ba60baa2e6ba6d&cntrller=library&use_panels=False&id=118977ea62bbe654' > $@

vcf/dbsnp_137.b37.unmangled.vcf:
	wget -c -O - 'ftp://gsapubftp-anonymous@ftp.broadinstitute.org/bundle/2.5/b37/dbsnp_137.b37.vcf.gz' | zcat > ${@:.unmangled=}
	cat ${@:.unmangled=} | perl ./bin/unmangle_chromosomes.pl > $@

vcf/dbsnp_137.hg19.vcf:
	wget -c -O - 'ftp://gsapubftp-anonymous@ftp.broadinstitute.org/bundle/2.5/hg19/dbsnp_137.hg19.vcf.gz' | zcat > $@

vcf/hapmap_3.3.hg19.vcf:
	wget -c -O - 'https://usegalaxy.org/library_common/download_dataset_from_folder?library_id=f9ba60baa2e6ba6d&cntrller=library&use_panels=False&id=19e1a16b810453de' > $@

vcf/Mills_and_1000G_gold_standard.indels.hg19.vcf:
	wget -c -O - 'https://usegalaxy.org/library_common/download_dataset_from_folder?library_id=f9ba60baa2e6ba6d&cntrller=library&use_panels=False&id=2217dd0542a71e8b' > $@

###unused
#1000G_omni2.5.hg19.sites.vcf:
#	wget -c -O - 'https://usegalaxy.org/library_common/download_dataset_from_folder?library_id=f9ba60baa2e6ba6d&show_deleted=False&cntrller=library&use_panels=False&id=08b67646777a9ddd' > $@


###unused, download URL not recorded
#vcf/dbsnp_135.hg19.vcf:
#vcf/dbsnp_138.b37.vcf:
#vcf/hapmap_3.3.hg19.sites.vcf:
#vcf/Mills_and_1000G_gold_standard.indels.hg19.sites.vcf:
