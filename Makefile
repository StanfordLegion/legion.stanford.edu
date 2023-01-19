# Deploy locally
.PHONY: local
local: doxygen manual messages build
	@echo "Result is in _site"

# Deploy to Sapling
.PHONY: deploy
deploy: local

	sudo rsync --recursive /scratch/www/htdocs/ \
	/scratch/www/htdocs.backup-$(shell date '+%Y-%m-%d')/

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
	_site/ /scratch/www/htdocs/

	# rm -rf doxygen _site

# Deploy to GitHub
.PHONY: github
github: local
	@if [ -d _github ]; then git -C _github pull --ff-only; else git clone -b master git@github.com:StanfordLegion/StanfordLegion.github.io.git _github; fi

	@if ! git -C _github diff-index --quiet --cached HEAD --; then echo "The _github directory has staged (uncommitted) files, please resolve"; exit 1; fi
	@if ! git -C _github diff-files --quiet; then echo "The _github directory has dirty files, please resolve"; exit 1; fi
	@if git -C _github ls-files --others --error-unmatch . 1> /dev/null 2> /dev/null; then echo "The _github directory has untracked files, please resolve"; exit 1; fi

	rsync --recursive --delete \
	--exclude .git \
	--exclude .nojekyll \
	--exclude CNAME \
	_site/ _github/

	git -C _github add -A .
	git -C _github commit --message "Deploy $(shell date)."
	git -C _github push

# Build steps:
.PHONY: doxygen
doxygen: legion
	doxygen


.PHONY: messages
messages: legion
	rm -rf messages
	cd ./_legion/doc && LG_RT_DIR=$(dir $(realpath $(lastword $(MAKEFILE_LIST))))_legion/runtime bash ./makeAllTheThings.bash
	mv ./_legion/doc/publish/messages .

.PHONY: legion
legion:
	@if [ -d _legion ]; then git -C _legion pull --ff-only; else git clone -b master https://github.com/StanfordLegion/legion.git _legion; fi

.PHONY: manual
manual:
	@if [ -d _manual ]; then git -C _manual pull --ff-only; else git clone -b master https://github.com/StanfordLegion/legion-manual.git _manual; fi
	cd _manual && TEST_LATEX=1 ./ci.sh
	cp _manual/legion.pdf pdfs/legion-manual.pdf

.PHONY: build
build:
	bundle install
	bundle exec jekyll build

.PHONY: serve
serve: doxygen manual messages
	bundle install
	bundle exec jekyll serve --watch

.PHONY: spelling
spelling:
	for f in *.md; do aspell -c $$f;done

.PHONY: clean
clean:
	rm -rf _site messages *.bak
