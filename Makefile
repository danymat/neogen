documentation:
	nvim --headless --noplugin -u ./scripts/minimal_init.vim -c "lua MiniDoc.generate()" -c "qa!"

tag:
	./scripts/generate_tag.sh
