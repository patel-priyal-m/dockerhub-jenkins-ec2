# Simplified Makefile for Local Development & Testing
# Production deployments should use Jenkins pipeline

# Variables
DOCKER_USERNAME ?= patelpriyalm
IMAGE_NAME = simple-demo-app
TAG ?= latest
DOCKER_IMAGE = $(DOCKER_USERNAME)/$(IMAGE_NAME):$(TAG)
CONTAINER_NAME = demo-app

.PHONY: help build test stop clean

help: ## Show this help message
	@echo '================================='
	@echo 'Local Development & Testing Only'
	@echo 'Use Jenkins for actual deployment'
	@echo '================================='
	@echo ''
	@echo 'Available targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'
	@echo ''
	@echo 'For deployment, use Jenkins pipeline with parameters'

build: ## Build Docker image locally
	@echo "Building Docker image: $(DOCKER_IMAGE)"
	docker build -t $(DOCKER_IMAGE) .
	@echo "✅ Build complete!"

test: build ## Build and run container locally on port 8080
	@echo "Running container locally on port 8080..."
	@docker stop $(CONTAINER_NAME)-test 2>/dev/null || true
	@docker rm $(CONTAINER_NAME)-test 2>/dev/null || true
	docker run -d --name $(CONTAINER_NAME)-test -p 8080:80 $(DOCKER_IMAGE)
	@echo "✅ Test container running at http://localhost:8080"
	@echo "Run 'make stop' to stop it"

stop: ## Stop and remove test container
	@echo "Stopping test container..."
	@docker stop $(CONTAINER_NAME)-test 2>/dev/null || true
	@docker rm $(CONTAINER_NAME)-test 2>/dev/null || true
	@echo "✅ Test container stopped"

clean: ## Remove local Docker images
	@docker rmi $(DOCKER_IMAGE) 2>/dev/null || true
	@echo "✅ Cleaned local images"

clean-test: ## Stop and remove test container
	docker stop $(CONTAINER_NAME)-test || true
	docker rm $(CONTAINER_NAME)-test || true

clean: ## Remove local Docker images
	docker rmi $(DOCKER_IMAGE) || true
	@echo "Cleaned local images"

logs: ## Show logs from EC2 container
	ssh -i $(SSH_KEY) $(EC2_USER)@$(EC2_HOST) "docker logs $(CONTAINER_NAME)"

status: ## Check container status on EC2
	ssh -i $(SSH_KEY) $(EC2_USER)@$(EC2_HOST) "docker ps | grep $(CONTAINER_NAME)"
