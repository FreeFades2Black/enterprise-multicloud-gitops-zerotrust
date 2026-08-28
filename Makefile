# ============================================================================
# Enterprise Multi-Cloud GitOps & Zero-Trust Makefile
# Lead Architect: William Free Hall (Free) <whall4.wh@gmail.com>
# ============================================================================

.PHONY: all lint policy-test security-scan tf-init tf-plan tf-apply gitops-bootstrap clean help

SHELL := /bin/bash

help: ## Show help instructions
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

lint: ## Lint Terraform and Helm charts
	@echo "[*] Linting Terraform code..."
	@terraform -chdir=terraform fmt -check
	@terraform -chdir=terraform validate
	@echo "[*] Linting Helm charts..."
	@helm lint helm/enterprise-app

policy-test: ## Run Open Policy Agent (OPA) / Conftest compliance tests
	@echo "[*] Testing CIS Kubernetes Benchmarks with Conftest..."
	@conftest test helm/enterprise-app/templates/*.yaml -p policy/cis_kubernetes.rego --no-fail || true
	@echo "[*] Testing CIS Terraform Benchmarks with Conftest..."
	@conftest test terraform/*.tf -p policy/cis_terraform.rego --no-fail || true

security-scan: ## Scan infrastructure and container images with Trivy
	@echo "[*] Scanning IaC configurations for CVEs & misconfigurations..."
	@trivy config terraform/ --severity HIGH,CRITICAL || true
	@trivy config helm/enterprise-app/ --severity HIGH,CRITICAL || true

tf-init: ## Initialize Terraform providers and backend
	@echo "[*] Initializing Terraform multi-cloud configuration..."
	@terraform -chdir=terraform init

tf-plan: ## Generate speculative Terraform execution plan
	@echo "[*] Generating Terraform execution plan..."
	@terraform -chdir=terraform plan -out=tfplan

tf-apply: ## Apply Terraform execution plan to target clouds
	@echo "[*] Applying infrastructure changes..."
	@terraform -chdir=terraform apply -auto-approve tfplan

gitops-bootstrap: ## Bootstrap ArgoCD and register GitOps applications
	@echo "[*] Registering ArgoCD GitOps root applications..."
	@kubectl apply -f argocd/appproject.yaml
	@kubectl apply -f argocd/application.yaml

clean: ## Clean up local plan files and caches
	@rm -f terraform/tfplan
	@rm -rf terraform/.terraform
