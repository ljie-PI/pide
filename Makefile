.PHONY: test check format

test:
	nvim --headless -u tests/minimal_init.lua -l tests/smoke.lua

check:
	luacheck lua plugin tests
	stylua --check lua plugin tests

format:
	stylua lua plugin tests
