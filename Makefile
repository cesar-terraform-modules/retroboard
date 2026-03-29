build:
	sh build-lambda-package.sh

dev-up:
	docker compose up --build -d

dev-down:
	docker compose down

dev-logs:
	docker compose logs -f

.PHONY: build init-aws cleanup-aws dev-up dev-down dev-logs
