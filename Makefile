.PHONY: deploy
deploy: doxygen messages build

	sudo rsync --recursive /local/www/htdocs/ \
	/local/www/htdocs.backup-$(shell date '+%Y-%m-%d')/

	sudo rsync --recursive --delete \
	--exclude /cg \
	--exclude /circuit \
	--exclude /fluid \
	--exclude /profiler \
	--exclude /profiler-data \
	--exclude /profiling.html \
	--exclude /rect \
	--exclude /s3d \
	--exclude /software_lunch \
	--exclude /s3dtraces \
	_site/ /local/www/htdocs/

	# rm -rf doxygen _site

.PHONY: doxygen
doxygen: legion
	doxygen


.PHONY: messages
messages: legion
	rm -rf design_patterns glossary messages
	cd ./_legion/doc && bash ./makeAllTheThings.bash
	mv ./_legion/doc/publish/design_patterns .
	mv ./_legion/doc/publish/glossary .
	mv ./_legion/doc/publish/messages .

.PHONY: legion
legion:
ifneq ($(wildcard _legion/.),)
	git -C _legion pull --ff-only
else
	git clone -b master https://github.com/StanfordLegion/legion.git _legion
endif

.PHONY: build
build:
	jekyll build

.PHONY: serve
serve:
	jekyll serve --watch

.PHONY: spelling
spelling:
	for f in *.md; do aspell -c $$f;done

.PHONY: clean
clean:
	rm -rf _site messages *.bak
