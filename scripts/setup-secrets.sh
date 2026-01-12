#!/bin/bash
# =============================================================================
# Setup Secrets for Infrastructure
# =============================================================================
# Creates AWS Secrets Manager secrets for the infrastructure.

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ENVIRONMENT=${1:-dev}
REGION=${2:-us-east-1}
PROJECT_NAME=${3:-iac-platform}

echo "=================================================="
echo "Setting up secrets for $ENVIRONMENT environment"
echo "=================================================="
echo ""

# Function to create or update secret
create_secret() {
    local secret_name=$1
    local secret_value=$2

    echo "Creating secret: $secret_name"

    # Check if secret exists
    if aws secretsmanager describe-secret --secret-id "$secret_name" --region "$REGION" &> /dev/null; then
        echo -e "${YELLOW}Secret already exists, updating...${NC}"
        aws secretsmanager put-secret-value \
            --secret-id "$secret_name" \
            --secret-string "$secret_value" \
            --region "$REGION"
    else
        echo "Creating new secret..."
        aws secretsmanager create-secret \
            --name "$secret_name" \
            --secret-string "$secret_value" \
            --description "Secret for $PROJECT_NAME $ENVIRONMENT environment" \
            --region "$REGION"
    fi

    echo -e "${GREEN}✓ Secret $secret_name configured${NC}"
    echo ""
}

# Function to generate random password
generate_password() {
    openssl rand -base64 32
}

# Create secrets
SECRET_PREFIX="${PROJECT_NAME}/${ENVIRONMENT}"

# Database credentials
echo "Setting up database credentials..."
DB_PASSWORD=$(generate_password)
create_secret "${SECRET_PREFIX}/database" "$(cat <<EOF
{
    "username": "dbadmin",
    "password": "${DB_PASSWORD}",
    "engine": "postgres",
    "host": "REPLACE_WITH_RDS_ENDPOINT",
    "port": 5432,
    "database": "application"
}
EOF
)"

# API Keys (placeholder values)
echo "Setting up API keys..."
create_secret "${SECRET_PREFIX}/api-keys" "$(cat <<EOF
{
    "internal_api_key": "REPLACE_WITH_SECURE_KEY",
    "external_api_key": "REPLACE_WITH_SECURE_KEY"
}
EOF
)"

# OAuth credentials (placeholder values)
echo "Setting up OAuth credentials..."
create_secret "${SECRET_PREFIX}/oauth" "$(cat <<EOF
{
    "client_id": "REPLACE_WITH_OAUTH_CLIENT_ID",
    "client_secret": "REPLACE_WITH_OAUTH_CLIENT_SECRET"
}
EOF
)"

# JWT signing key
echo "Setting up JWT signing key..."
JWT_SECRET=$(generate_password)
create_secret "${SECRET_PREFIX}/jwt" "$(cat <<EOF
{
    "signing_key": "${JWT_SECRET}",
    "algorithm": "HS256"
}
EOF
)"

echo "=================================================="
echo "Secrets setup complete!"
echo "=================================================="
echo ""
echo "Created secrets:"
aws secretsmanager list-secrets \
    --region "$REGION" \
    --query "SecretList[?starts_with(Name, '$SECRET_PREFIX')].Name" \
    --output table

echo ""
echo -e "${YELLOW}Important: Update the placeholder values in the secrets${NC}"
echo "Use the AWS Console or CLI to update secret values:"
echo ""
echo "  aws secretsmanager put-secret-value \\"
echo "    --secret-id ${SECRET_PREFIX}/database \\"
echo "    --secret-string '{\"username\":\"dbadmin\",\"password\":\"YOUR_PASSWORD\",...}'"
echo ""
