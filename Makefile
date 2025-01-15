# =============================================================================
# Infrastructure as Code Makefile
# =============================================================================
# Common commands for managing infrastructure

.PHONY: all init plan apply destroy fmt validate clean help

# Default environment
ENV ?= dev

# Terraform directory
TF_DIR = environments/$(ENV)

# Colors
GREEN  = $(shell tput -Txterm setaf 2)
YELLOW = $(shell tput -Txterm setaf 3)
WHITE  = $(shell tput -Txterm setaf 7)
RESET  = $(shell tput -Txterm sgr0)

# Help target
help: ## Show this help message
	@echo ''
	@echo 'Usage:'
	@echo '  ${YELLOW}make${RESET} ${GREEN}<target>${RESET} [ENV=dev|staging|prod]'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} { \
		if (/^[a-zA-Z_-]+:.*?##.*$$/) {printf "  ${GREEN}%-15s${RESET} %s\n", $$1, $$2} \
		else if (/^## .*$$/) {printf "  %s\n", substr($$1, 4)} \
		}' $(MAKEFILE_LIST)
	@echo ''

# =============================================================================
# Terraform Commands
# =============================================================================

init: ## Initialize Terraform for specified environment
	@echo "${YELLOW}Initializing Terraform for $(ENV) environment...${RESET}"
	cd $(TF_DIR) && terraform init

plan: ## Plan infrastructure changes
	@echo "${YELLOW}Planning infrastructure for $(ENV) environment...${RESET}"
	cd $(TF_DIR) && terraform plan -var-file=terraform.tfvars -out=tfplan

apply: ## Apply infrastructure changes
	@echo "${YELLOW}Applying infrastructure for $(ENV) environment...${RESET}"
	cd $(TF_DIR) && terraform apply tfplan

destroy: ## Destroy infrastructure
	@echo "${RED}Destroying infrastructure for $(ENV) environment...${RESET}"
	cd $(TF_DIR) && terraform destroy -var-file=terraform.tfvars

fmt: ## Format Terraform files
	@echo "${YELLOW}Formatting Terraform files...${RESET}"
	find . -name "*.tf" -exec terraform fmt {} \;

validate: ## Validate Terraform configuration
	@echo "${YELLOW}Validating Terraform for $(ENV) environment...${RESET}"
	cd $(TF_DIR) && terraform validate

# =============================================================================
# Output Commands
# =============================================================================

output: ## Show Terraform outputs
	cd $(TF_DIR) && terraform output

state-list: ## List all resources in state
	cd $(TF_DIR) && terraform state list

# =============================================================================
# Utility Commands
# =============================================================================

clean: ## Clean up generated files
	@echo "${YELLOW}Cleaning up...${RESET}"
	find . -name "*.tfplan" -delete
	find . -name "*.tfplan.json" -delete
	find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	find . -name "*.tfstate*" -delete 2>/dev/null || true

check: fmt validate ## Run format and validation checks
	@echo "${GREEN}All checks passed!${RESET}"

security: ## Run security scans
	@echo "${YELLOW}Running security scans...${RESET}"
	@if command -v tfsec >/dev/null 2>&1; then \
		tfsec . --soft-fail; \
	else \
		echo "tfsec not installed. Install with: brew install tfsec"; \
	fi
	@if command -v checkov >/dev/null 2>&1; then \
		checkov -d . --soft-fail; \
	else \
		echo "checkov not installed. Install with: pip install checkov"; \
	fi

# =============================================================================
# Module Commands
# =============================================================================

modules-init: ## Initialize all modules
	@echo "${YELLOW}Initializing all modules...${RESET}"
	for dir in modules/*/; do \
		cd "$$dir" && terraform init -backend=false && cd ../..; \
	done

modules-validate: ## Validate all modules
	@echo "${YELLOW}Validating all modules...${RESET}"
	for dir in modules/*/; do \
		echo "Validating $$dir" && \
		cd "$$dir" && terraform validate && cd ../..; \
	done

# =============================================================================
# Bootstrap Commands
# =============================================================================

bootstrap: ## Bootstrap state management infrastructure
	@echo "${YELLOW}Bootstrapping state management...${RESET}"
	cd state-management && terraform init && terraform apply

# =============================================================================
# CI/CD Commands
# =============================================================================

ci-validate: ## Run all CI validation checks
	@echo "${YELLOW}Running CI validation...${RESET}"
	./scripts/validate.sh

ci-plan: ## Generate plan for CI
	@echo "${YELLOW}Generating CI plan...${RESET}"
	cd $(TF_DIR) && \
	terraform plan -var-file=terraform.tfvars -out=tfplan && \
	terraform show -json tfplan > tfplan.json

ci-policy: ci-plan ## Run policy checks
	@echo "${YELLOW}Running policy checks...${RESET}"
	conftest test $(TF_DIR)/tfplan.json --policy policies/opa --all-namespaces

# =============================================================================
# Development Commands
# =============================================================================

dev-console: ## Open Terraform console
	cd $(TF_DIR) && terraform console

dev-graph: ## Generate dependency graph
	cd $(TF_DIR) && terraform graph | dot -Tpng > graph.png
	@echo "${GREEN}Graph saved to graph.png${RESET}"

dev-import: ## Import existing resource (usage: make dev-import ADDR=address ID=id)
	cd $(TF_DIR) && terraform import $(ADDR) $(ID)

# =============================================================================
# Terragrunt Commands
# =============================================================================

tg-init: ## Initialize Terragrunt
	@echo "${YELLOW}Initializing Terragrunt for $(ENV)...${RESET}"
	cd environments/$(ENV) && terragrunt init

tg-plan: ## Plan with Terragrunt
	@echo "${YELLOW}Planning with Terragrunt for $(ENV)...${RESET}"
	cd environments/$(ENV) && terragrunt plan

tg-apply: ## Apply with Terragrunt
	@echo "${YELLOW}Applying with Terragrunt for $(ENV)...${RESET}"
	cd environments/$(ENV) && terragrunt apply

tg-destroy: ## Destroy with Terragrunt
	@echo "${RED}Destroying with Terragrunt for $(ENV)...${RESET}"
	cd environments/$(ENV) && terragrunt destroy

tg-run-all-plan: ## Plan all modules in environment
	@echo "${YELLOW}Planning all modules for $(ENV)...${RESET}"
	cd environments/$(ENV) && terragrunt run-all plan

tg-run-all-apply: ## Apply all modules in environment
	@echo "${YELLOW}Applying all modules for $(ENV)...${RESET}"
	cd environments/$(ENV) && terragrunt run-all apply

# =============================================================================
# Cost Estimation
# =============================================================================

cost: ## Generate cost estimate with Infracost
	@echo "${YELLOW}Generating cost estimate for $(ENV)...${RESET}"
	@if command -v infracost >/dev/null 2>&1; then \
		infracost breakdown --path=$(TF_DIR) --format=json --out-file=infracost.json && \
		infracost output --path=infracost.json --format=table; \
	else \
		echo "infracost not installed. Install from: https://infracost.io"; \
	fi

cost-diff: ## Generate cost diff for PR
	@echo "${YELLOW}Generating cost diff...${RESET}"
	@if command -v infracost >/dev/null 2>&1; then \
		infracost diff --path=$(TF_DIR) --compare-to=main; \
	else \
		echo "infracost not installed. Install from: https://infracost.io"; \
	fi

# =============================================================================
# Test Commands
# =============================================================================

test: ## Run Terraform tests
	@echo "${YELLOW}Running Terraform tests...${RESET}"
	terraform init -backend=false && terraform test -test-directory=tests

test-modules: ## Run tests for all modules
	@echo "${YELLOW}Running module tests...${RESET}"
	for dir in modules/*/; do \
		echo "Testing $$dir" && \
		cd "$$dir" && terraform test && cd ../..; \
	done

lint: ## Run tflint
	@echo "${YELLOW}Running tflint...${RESET}"
	@if command -v tflint >/dev/null 2>&1; then \
		tflint --recursive; \
	else \
		echo "tflint not installed. Install from: https://github.com/terraform-linters/tflint"; \
	fi

validate-all: fmt lint validate test ## Run all validation checks
	@echo "${GREEN}All validation checks passed!${RESET}"
