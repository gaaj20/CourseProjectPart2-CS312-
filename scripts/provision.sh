#!/usr/bin/env bash
# scripts/provision.sh
# Runs Terraform to create (or update) all AWS infrastructure.
# Outputs the public IP and updates ansible/inventory.ini automatically.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="${SCRIPT_DIR}/../terraform"
INVENTORY_FILE="${SCRIPT_DIR}/../ansible/inventory.ini"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

# Preflight
[[ -f "${TERRAFORM_DIR}/terraform.tfvars" ]] || \
  error "terraform.tfvars not found. Run scripts/setup.sh first."

# Terraform init + apply 
info "Initializing Terraform..."
terraform -chdir="${TERRAFORM_DIR}" init -upgrade

info "Planning infrastructure changes..."
terraform -chdir="${TERRAFORM_DIR}" plan -out=tfplan

info "Applying infrastructure changes..."
terraform -chdir="${TERRAFORM_DIR}" apply tfplan
rm -f "${TERRAFORM_DIR}/tfplan"

# Extract outputs
PUBLIC_IP=$(terraform -chdir="${TERRAFORM_DIR}" output -raw instance_public_ip)
NMAP_CMD=$(terraform -chdir="${TERRAFORM_DIR}" output -raw nmap_command)

info "EC2 Elastic IP: ${PUBLIC_IP}"

# Update Ansible inventory
info "Updating ansible/inventory.ini with public IP ${PUBLIC_IP}..."
sed -i "s/REPLACE_WITH_PUBLIC_IP/${PUBLIC_IP}/" "${INVENTORY_FILE}"

info "Waiting 30 seconds for the instance to finish booting..."
sleep 30

info "Provisioning complete!"
echo ""
echo "  Public IP : ${PUBLIC_IP}"
echo "  Next step : ./scripts/configure.sh"
echo "  Verify    : ${NMAP_CMD}"
