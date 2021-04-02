.PHONY: backup pack unpack

SHELL = /bin/bash

RSPATH ?= ${HOME}/Library/Application\ Support/Steam/steamapps/common/Rocksmith2014

# path where direnv would place virtualenv
virtual_env = ${PWD}/.direnv/python-$(shell python3 -V|awk '{print $$2}')

pyrocksmith = ${virtual_env}/bin/pyrocksmith
7z = /usr/local/bin/7z
ffdec = vendor/ffdec/ffdec.jar

# specific compression arguments to replicate rocksmits native 7z compression, not required?
# 7z_compress_args = -m1=LZMA:d23 -ms=off

cache_nrs = 0 1 3 4 6 7 8

mod_fastload: overrides/cache4/gfxassets/views/introsequence.gfx

overrides/cache4/gfxassets/views/introsequence.gfx: src/cache4/gfxassets/views/introsequence.gfx | ${ffdec}
	mkdir -p ${@D}
	java -jar ~/Downloads/ffdec_14/ffdec.jar -format script:pcode -export script src/ $<
	sed -iE '20s/LogoVideo/BlackScreen/' src/scripts/__Packages/IntroSequence_TestData.pcode
	java -jar ~/Downloads/ffdec_14/ffdec.jar -replace $< $@ /__Packages/IntroSequence_TestData src/scripts/__Packages/IntroSequence_TestData.pcode

install: ${RSPATH}/cache.psarc
${RSPATH}/cache.psarc: dist/cache.psarc | ${RSPATH}/cache.psarc.bck
	cp $< "$@"

dist_cache_files = $(foreach nr,${cache_nrs},dist/cache/cache${nr}.7z)
pack: dist/cache.psarc
dist/cache.psarc: ${dist_cache_files} | ${pyrocksmith}
	cd ${@D} && ${pyrocksmith} --pack ${PWD}/dist/cache

dist/cache/cache4.7z: dist/cache/cache%.7z: src/cache/cache%.7z src/cache4
	mkdir -p ${@D}
	cp $< $@
	cd overrides/cache4 && ${7z} ${7z_compress_args} a ${PWD}/$@ $$(find * -type f)

dist/cache/cache%.7z: src/cache/cache%.7z
	mkdir -p ${@D}
	cp $< $@


src/cache4/gfxassets/views/introsequence.gfx: src/cache4

unzip: src/cache4
src/cache4: src/cache/cache4.7z | ${7z}
	mkdir -p ${@D}
	${7z} x $< -o$@

src_cache_files = $(foreach nr,${cache_nrs},src/cache/cache${nr}.7z)

unpack: ${src_cache_files}
${src_cache_files} &: src/cache.psarc | ${pyrocksmith}
	cd src/ && ${pyrocksmith} --unpack ${PWD}/$<

src/cache.psarc:
	mkdir -p ${@D}
	cp ${RSPATH}/cache.psarc "$@"

restore:
	cp ${RSPATH}/cache.psarc.bck ${RSPATH}/cache.psarc

backup: ${RSPATH}/cache.psarc.bck
${RSPATH}/cache.psarc.bck:
	cp ${RSPATH}/cache.psarc "$@"

${pyrocksmith}: ${virtual_env}
	pip3 install git+https://github.com/0x0L/rocksmith.git

${virtual_env}:
	python3 -m venv "${virtual_env}"

${7z}:
	brew install p7zip

${ffdec}:
	mkdir -p vendor/ffdec
	cd vendor/ffdec && wget https://github.com/jindrapetrik/jpexs-decompiler/releases/download/nightly1918/ffdec_14.3.1_nightly1918.zip
	cd vendor/ffdec && unzip ffdec_14.3.1_nightly1918.zip

clean:
	rm -rf src/ dist/ overrides/

mrproper: clean
	rm -rf .direnv/ vendor/