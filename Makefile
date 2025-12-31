# Variables
DOCKER_USERNAME ?= your-dockerhub-username
IMAGE_NAME = simple-demo-app
TAG ?= latest
DOCKER_IMAGE = $(DOCKER_USERNAME)/$(IMAGE_NAME):$(TAG)

# EC2 Configuration
EC2_HOST ?= your-ec2-ip-address
EC2_USER ?= ec2-user
SSH_KEY ?= ~/.ssh/your-key.pem
CONTAINER_NAME = demo-app
PORT = 80

.PHONY: help build push deploy clean test

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'

build: ## Build Docker image
	@echo "Building Docker image: $(DOCKER_IMAGE)"
	docker build -t $(DOCKER_IMAGE) .
	@echo "Build complete!"

tag: build ## Build and tag image
	@echo "Image tagged as: $(DOCKER_IMAGE)"

push: build ## Build, tag and push to DockerHub
	@echo "Pushing $(DOCKER_IMAGE) to DockerHub..."
	docker push $(DOCKER_IMAGE)
	@echo "Push complete!"

deploy: push ## Build, push and deploy to EC2
	@echo "Deploying to EC2 instance at $(EC2_HOST)..."
	@echo "Stopping old container if exists..."
	ssh -i $(SSH_KEY) $(EC2_USER)@$(EC2_HOST) "docker stop $(CONTAINER_NAME) || true && docker rm $(CONTAINER_NAME) || true"
	@echo "Pulling latest image..."
	ssh -i $(SSH_KEY) $(EC2_USER)@$(EC2_HOST) "docker pull $(DOCKER_IMAGE)"
	@echo "Starting new container..."
	ssh -i $(SSH_KEY) $(EC2_USER)@$(EC2_HOST) "docker run -d --name $(CONTAINER_NAME) -p $(PORT):80 --restart unless-stopped $(DOCKER_IMAGE)"
	@echo "Deployment complete! App running at http://$(EC2_HOST)"

test: ## Test Docker image locally
	@echo "Running container locally on port 8080..."
	docker run -d --name $(CONTAINER_NAME)-test -p 8080:80 $(DOCKER_IMAGE)
	@echo "Test container running at http://localhost:8080"
	@echo "Run 'make clean-test' to stop it"

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
