build:
	sh build-lambda-package.sh

init-aws:
	./init-aws.sh

dev-up:
	docker compose up --build -d

dev-down:
	docker compose down

dev-logs:
	docker compose logs -f

.PHONY: build init-aws dev-up dev-down dev-logs
