.PHONY: article
article:
	npx zenn new:article

.PHONY: preview
preview:
	npx zenn preview

.PHONY: lint
lint:
	npm run lint
