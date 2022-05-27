SHELL := /bin/bash

run:
	go run app/services/sales-api/main.go | go run app/tooling/logfmt/main.go

build:
	go build -ldflags "-X main.build=local"

# ==============================================================================
# Building containers

VERSION := 1.0

all: sales-api

sales-api:
	docker build \
		-f zarf/docker/dockerfile.sales-api \
		-t sales-api-amd64:$(VERSION) \
		--build-arg BUILD_REF=$(VERSION) \
		--build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
		.

# ==============================================================================
# Running from within k8s/kind

KIND_CLUSTER := ardan-starter-cluster

# Starts up cluster
kind-up:
	kind create cluster \
		--image kindest/node:v1.24.0@sha256:0866296e693efe1fed79d5e6c7af8df71fc73ae45e3679af05342239cdc5bc8e \
		--name $(KIND_CLUSTER) \
		--config zarf/k8s/kind/kind-config.yaml
	kubectl config set-context --current --namespace=sales-system

# Deletes cluster
kind-down:
	kind delete cluster --name $(KIND_CLUSTER)
	
# Specific to kind -- load local images to kind cluster environment
kind-load:
	# Edits the version in kind kustomize (which updates our base kustomize)
	cd zarf/k8s/kind/sales-pod; kustomize edit set image sales-api-image=sales-api-amd64:$(VERSION)
	kind load docker-image sales-api-amd64:$(VERSION) --name $(KIND_CLUSTER)

# Kustomize patches our base with environment settings (like replicas, strategy, resource limits/quotas)
kind-apply:
	kustomize build zarf/k8s/kind/sales-pod | kubectl apply -f -

# Gets cluster status
kind-status:
	kubectl get nodes -o wide
	kubectl get svc -o wide
	kubectl get pods -o wide --watch --all-namespaces

# Get cluster status for just sales
kind-status-sales:
	kubectl get pods -o wide --watch

# Query logs of a sales
kind-logs:
	kubectl logs -l app=sales --all-containers=true -f --tail=100 | go run app/tooling/logfmt/main.go

# Restart deployment
kind-restart:
	kubectl rollout restart deployment sales-pod

# Builds, loads, and updates the deployment
kind-update: all kind-load kind-restart

# Updated environment settings -- build, load, apply (will restart with apply because of strategy: Recreate)
kind-update-apply: all kind-load kind-apply

# Describe the pod
kind-describe:
	kubectl describe pod -l app=sales

# ==============================================================================
# Modules support

tidy:
	go mod tidy
	go mod vendor
