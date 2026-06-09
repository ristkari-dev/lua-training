SHELL := /bin/bash
.DEFAULT_GOAL := help

REPO_ROOT := $(shell pwd)
LUA_ENV := .lua
LUA := $(LUA_ENV)/bin/lua
BUSTED := $(LUA_ENV)/bin/busted
LUACHECK := $(LUA_ENV)/bin/luacheck

.PHONY: help
help: ## List available targets
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: bootstrap
bootstrap: ## Install pinned Lua 5.4 + LuaRocks + rocks into ./.lua (via hererocks)
	./scripts/bootstrap

.PHONY: test
test: ## Run tool specs + every lesson's solution specs (the always-green set)
	$(BUSTED) tools
	@for d in $$(find lessons -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort); do \
		if [ -d "$$d/solutions" ]; then \
			echo "== $$d/solutions =="; \
			$(BUSTED) "$$d/solutions" || exit 1; \
		fi; \
	done

.PHONY: test-exercises
test-exercises: ## Run exercise specs (these fail by design until students complete them)
	@for d in $$(find lessons -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort); do \
		if [ -d "$$d/exercises" ]; then \
			echo "== $$d/exercises =="; \
			$(BUSTED) "$$d/exercises" || true; \
		fi; \
	done

.PHONY: test-lesson
test-lesson: ## Run one lesson's specs, exercises then solutions (LESSON=NN-slug)
	@test -n "$(LESSON)" || (echo "usage: make test-lesson LESSON=NN-slug" && exit 1)
	-$(BUSTED) lessons/$(LESSON)/exercises
	$(BUSTED) lessons/$(LESSON)/solutions

.PHONY: lint
lint: ## Run luacheck over the tools and lessons
	$(LUACHECK) tools lessons

.PHONY: fmt
fmt: ## Format Lua with StyLua (install separately: brew install stylua)
	stylua tools lessons

.PHONY: new-lesson
new-lesson: ## Scaffold a new lesson (NAME=NN-slug)
	@test -n "$(NAME)" || (echo "usage: make new-lesson NAME=NN-slug" && exit 1)
	$(LUA) tools/new-lesson/main.lua $(NAME)

.PHONY: slides-dev
slides-dev: ## Serve one lesson's deck locally on http://localhost:8000 (LESSON=NN-slug)
	@test -n "$(LESSON)" || (echo "usage: make slides-dev LESSON=NN-slug" && exit 1)
	$(LUA) tools/slides-dev/main.lua --lesson $(LESSON) --repo-root $(REPO_ROOT)

.PHONY: slides-build
slides-build: ## Build the static slides site into dist/
	$(LUA) tools/build-index/main.lua --lessons lessons --shared shared/reveal --out dist

.PHONY: slides-docker
slides-docker: ## Build the deploy image and run it locally on http://localhost:8080
	docker build -t lua-training-slides:local -f deploy/Dockerfile .
	@echo "starting container on http://localhost:8080  (Ctrl-C to stop)"
	docker run --rm -p 8080:8080 -e PORT=8080 lua-training-slides:local
