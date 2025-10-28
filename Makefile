ifndef CHPL_WWW
CHPL_WWW=~/chapel-www
endif

SHELL=/bin/bash
VENV_DIR=./venv
ACTIVATE=$(VENV_DIR)/bin/activate
SETUP=source $(ACTIVATE)

default: preview

$(ACTIVATE): requirements.txt
	rm -rf $(VENV_DIR)
#	python3 -m pip install --user virtualenv
	python3 -m venv $(VENV_DIR)
	$(SETUP) && pip install -r requirements.txt

clean:
	rm -rf ./public ./public-server

serve preview: check-env $(ACTIVATE)
	$(SETUP) && ./scripts/chpl_blog.py serve -F

serve-drafts preview-drafts: check-env $(ACTIVATE)
	$(SETUP) && ./scripts/chpl_blog.py serve -D -F

www web html: check-env clean $(ACTIVATE)
	$(SETUP) && ./scripts/chpl_blog.py build && \
		(find public -name "*.html" | xargs ./scripts/insert_links.py)
	$(MAKE) copy-to-www

www-future: $(ACTIVATE)
	$(SETUP) && ./scripts/chpl_blog.py build -F
	$(MAKE) copy-to-www

copy-to-www:
	cd public/posts/hpo-example/code && ln -s hpo-example.chpl tune.chpl
	start_test --clean-only
	rsync -avh --no-times --checksum --exclude CLEANFILES --exclude "*.tmp" --exclude "*.bad" --exclude "*.future" --exclude "*.compopts" --exclude COMPOPTS --exclude "*.execopts" --exclude "EXECOPTS" --exclude "*.noexec" --exclude "sub_test" --exclude "*.notest" --exclude "*.skipif" --exclude PRECOMP --exclude "*.numlocales" --exclude "*.suppressif" --exclude Makefile --exclude NUMLOCALES --delete-excluded public/* $(CHPL_WWW)/chapel-lang.org/blog/
	find $(CHPL_WWW)/chapel-lang.org/blog/

test: check-env
	start_test chpl-src content/posts/*/code

check-env:
ifndef CHPL_HOME
	$(error CHPL_HOME is undefined)
endif

clobber: clean
	rm -r content-gen
	rm -rf $(VENV_DIR)
