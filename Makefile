POETRY ?= poetry
PYTHON ?= python
COMPOSE ?= docker compose
COMPOSE_FILE ?= infra/docker/docker-compose.yaml

export PYTHONDONTWRITEBYTECODE = 1

.PHONY: help bootstrap compose-up compose-down data feast-apply materialize train register serve producer drift-report load-test smoke lint test fmt fmt-check

help:
	@grep -E '^[a-zA-Z_-]+:.*?##' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

bootstrap: ## Install Python deps and pre-commit hooks
	$(POETRY) install
	$(POETRY) run pre-commit install

compose-up: ## Launch docker-compose stack
	$(COMPOSE) -f $(COMPOSE_FILE) up -d --build

compose-down: ## Stop docker-compose stack
	$(COMPOSE) -f $(COMPOSE_FILE) down -v

data: ## Generate synthetic data and upload to MinIO
	$(POETRY) run $(PYTHON) scripts/generate_synthetic_data.py

feast-apply: ## Apply Feast repository definitions
	$(POETRY) run feast -c services/feature_service/feast_repo apply

materialize: ## Materialize Feast offline to online store
	$(POETRY) run $(PYTHON) services/feature_service/feast_repo/materialize.py

train: ## Train model and log to MLflow
	$(POETRY) run $(PYTHON) services/model_training/train.py

register: ## Register best model to MLflow Staging
	$(POETRY) run $(PYTHON) services/model_training/register.py

serve: ## Run Ray Serve API locally
	$(POETRY) run $(PYTHON) services/serving/app/main.py

producer: ## Stream synthetic events into Redpanda
	$(POETRY) run $(PYTHON) services/producer/main.py

drift-report: ## Generate Evidently drift report artifacts
	$(POETRY) run $(PYTHON) services/monitoring/drift/run_evidently.py

load-test: ## Run Locust headless quick test
	$(POETRY) run locust -f scripts/load_test_locustfile.py --headless -u 20 -r 5 --run-time 1m

lint: ## Run ruff and black checks
	$(POETRY) run ruff check .
	$(POETRY) run black --check .

fmt: ## Format code with black
	$(POETRY) run black .

fmt-check: lint ## Alias for lint

test: ## Execute unit tests
	$(POETRY) run pytest -q

smoke: ## End-to-end health smoke
	bash scripts/smoke_test.sh
