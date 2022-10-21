.PHONY: integration
integration: luacheck test

.PHONY: luacheck
luacheck:
	luacheck ./lua

.PHONY: test
test:
	vusted ./lua
