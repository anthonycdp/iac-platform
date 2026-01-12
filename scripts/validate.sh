#!/bin/bash
# =============================================================================
# Infrastructure as Code Validation Script
# =============================================================================
# This script runs validation checks on all Terraform configurations.
# Use this before committing changes or in CI/CD pipelines.

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Project root
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODULES_DIR="$PROJECT_ROOT/modules"
ENVIRONMENTS_DIR="$PROJECT_ROOT/environments"

# Counters
ERRORS=0
WARNINGS=0

# Print functions
print_header() {
    echo -e "\n${YELLOW}========================================${NC}"
    echo -e "${YELLOW}$1${NC}"
    echo -e "${YELLOW}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
    ((ERRORS++))
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
    ((WARNINGS++))
}

# =============================================================================
# Check 1: Terraform Format
# =============================================================================
check_format() {
    print_header "Checking Terraform Format"

    # Check all .tf files
    FILES=$(find "$PROJECT_ROOT" -name "*.tf" -type f)

    for file in $FILES; do
        if terraform fmt -check "$file" > /dev/null 2>&1; then
            print_success "Format OK: $file"
        else
            print_error "Format issue: $file"
            echo "  Run: terraform fmt $file"
        fi
    done
}

# =============================================================================
# Check 2: Terraform Validate
# =============================================================================
check_validate() {
    print_header "Validating Terraform Configurations"

    # Validate modules
    for module_dir in "$MODULES_DIR"/*/; do
        if [ -f "$module_dir/main.tf" ]; then
            echo "Validating module: $(basename $module_dir)"
            cd "$module_dir"

            if terraform init -backend=false > /dev/null 2>&1; then
                if terraform validate > /dev/null 2>&1; then
                    print_success "Validation OK: $(basename $module_dir)"
                else
                    print_error "Validation failed: $(basename $module_dir)"
                    terraform validate 2>&1 | head -20
                fi
            else
                print_warning "Init failed: $(basename $module_dir)"
            fi

            cd "$PROJECT_ROOT"
        fi
    done

    # Validate environments (without backend)
    for env_dir in "$ENVIRONMENTS_DIR"/*/; do
        if [ -f "$env_dir/main.tf" ]; then
            echo "Validating environment: $(basename $env_dir)"
            cd "$env_dir"

            if terraform init -backend=false > /dev/null 2>&1; then
                if terraform validate > /dev/null 2>&1; then
                    print_success "Validation OK: $(basename $env_dir)"
                else
                    print_error "Validation failed: $(basename $env_dir)"
                    terraform validate 2>&1 | head -20
                fi
            else
                print_warning "Init failed: $(basename $env_dir)"
            fi

            cd "$PROJECT_ROOT"
        fi
    done
}

# =============================================================================
# Check 3: Documentation
# =============================================================================
check_documentation() {
    print_header "Checking Documentation"

    # Check README exists
    if [ -f "$PROJECT_ROOT/README.md" ]; then
        print_success "README.md exists"
    else
        print_warning "README.md missing"
    fi

    # Check module documentation
    for module_dir in "$MODULES_DIR"/*/; do
        module_name=$(basename "$module_dir")
        if [ ! -f "$module_dir/README.md" ]; then
            print_warning "Missing README.md in module: $module_name"
        else
            print_success "README.md exists in module: $module_name"
        fi
    done
}

# =============================================================================
# Check 4: Security Scanning (if tfsec is installed)
# =============================================================================
check_security() {
    print_header "Running Security Scans"

    if command -v tfsec &> /dev/null; then
        echo "Running tfsec..."
        if tfsec "$PROJECT_ROOT" --soft-fail; then
            print_success "tfsec scan passed"
        else
            print_error "tfsec found issues"
        fi
    else
        print_warning "tfsec not installed, skipping security scan"
        echo "  Install with: brew install tfsec"
    fi

    if command -v checkov &> /dev/null; then
        echo "Running checkov..."
        if checkov -d "$PROJECT_ROOT" --soft-fail; then
            print_success "checkov scan passed"
        else
            print_error "checkov found issues"
        fi
    else
        print_warning "checkov not installed, skipping security scan"
        echo "  Install with: pip install checkov"
    fi
}

# =============================================================================
# Check 5: Policy Validation (if conftest is installed)
# =============================================================================
check_policies() {
    print_header "Running Policy Checks"

    if command -v conftest &> /dev/null; then
        # Create a sample plan for policy testing
        echo "Generating test plan..."
        cd "$ENVIRONMENTS_DIR/dev"

        if terraform init -backend=false > /dev/null 2>&1; then
            if terraform plan -out=tfplan -input=false > /dev/null 2>&1; then
                terraform show -json tfplan > tfplan.json 2>/dev/null || true

                if [ -f tfplan.json ]; then
                    echo "Running OPA policies..."
                    if conftest test tfplan.json --policy "$PROJECT_ROOT/policies/opa" --all-namespaces; then
                        print_success "OPA policy checks passed"
                    else
                        print_error "OPA policy checks failed"
                    fi
                    rm -f tfplan tfplan.json
                fi
            fi
        fi

        cd "$PROJECT_ROOT"
    else
        print_warning "conftest not installed, skipping policy checks"
        echo "  Install with: brew install conftest"
    fi
}

# =============================================================================
# Main
# =============================================================================
main() {
    print_header "Infrastructure as Code Validation"

    echo "Project root: $PROJECT_ROOT"
    echo "Started at: $(date)"

    # Run all checks
    check_format
    check_validate
    check_documentation
    check_security
    check_policies

    # Summary
    print_header "Summary"

    echo -e "Errors: ${RED}$ERRORS${NC}"
    echo -e "Warnings: ${YELLOW}$WARNINGS${NC}"

    if [ $ERRORS -gt 0 ]; then
        echo -e "\n${RED}Validation FAILED${NC}"
        exit 1
    else
        echo -e "\n${GREEN}Validation PASSED${NC}"
        exit 0
    fi
}

# Run main function
main "$@"
