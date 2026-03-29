build:
	sh build-lambda-package.sh

init-aws:
	./init-aws.sh

cleanup-aws:
	RETROBOARD_FORCE_DESTROY=1 ./cleanup-aws.sh

dev-up:
	docker compose up --build -d

dev-down:
	docker compose down

dev-logs:
	docker compose logs -f

.PHONY: build init-aws cleanup-aws dev-up dev-down dev-logs
