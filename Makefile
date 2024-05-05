TESTS_INIT=tests/minimal_init.lua
TESTS_DIR=tests/

.PHONY: test

documentation:
	nvim --headless --noplugin -u ./scripts/minimal_init.vim -c "lua MiniDoc.generate()" -c "qa!"

tag:
	./scripts/generate_tag.sh

test:
	@nvim \
		--headless \
		--noplugin \
		-u ${TESTS_INIT} \
		-c "PlenaryBustedDirectory ${TESTS_DIR} { minimal_init = '${TESTS_INIT}' }"
