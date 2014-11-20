GITHUB_USER=allenday
PROJECTS=htslib samtools bwa htsjdk picard gatk adam bamtools gatk-protected

all:
	${MAKE} htslib.built
	${MAKE} samtools.built
	${MAKE} bwa.built
	${MAKE} htsjdk.built
	${MAKE} picard.built
	${MAKE} gatk.built
	${MAKE} adam.built
	${MAKE} bamtools.built
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
