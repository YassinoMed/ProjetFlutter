SHELL := /usr/bin/env bash

.PHONY: hooks-install autopush-install local-up local-up-observability local-down local-clean local-health local-test \
	backend-test-docker frontend-test quality-local logs ps

hooks-install:
	./scripts/dev/install-git-hooks.sh

autopush-install:
	git config alias.autopush '!f() { "$$(git rev-parse --show-toplevel)/scripts/dev/git-autopush.sh" "$$@"; }; f'

local-up:
	./scripts/dev/local-up.sh

local-up-observability:
	./scripts/dev/local-up.sh --with-observability

local-down:
	./scripts/dev/local-down.sh

local-clean:
	./scripts/dev/local-down.sh --volumes

local-health:
	./scripts/dev/local-health-check.sh

backend-test-docker:
	./scripts/dev/local-test.sh --backend-only

frontend-test:
	cd frontend && flutter pub get && flutter analyze && flutter test

local-test:
	./scripts/dev/local-test.sh

quality-local:
	./scripts/dev/pre-push-checks.sh

logs:
	docker compose -f docker-compose.yml -f docker-compose.local.yml logs -f --tail=150

ps:
	docker compose -f docker-compose.yml -f docker-compose.local.yml ps
