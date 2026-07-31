.PHONY: web

web:
	mkdir -p docs
	godot --headless --path . --export-release Web docs/index.html
