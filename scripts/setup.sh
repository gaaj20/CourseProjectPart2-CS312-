#!/usr/bin/env bash
# scripts/setup.sh
# Prepares local prereqs before running Terraform or Ansible.
# Run once when setting up a new workstation.

set -euo pipefail

KEY_PATH="${HOME}/.ssh/minecraft_key"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="${SCRIPT_DIR}/../terraform"
ANSIBLE_DIR="${SCRIPT_DIR}/../ansible"

# Colors 
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

# Dependency checks 
info "Checking required tools..."
for cmd in terraform ansible aws nmap ssh-keygen; do
  if ! command -v "$cmd" &>/dev/null; then
    error "'$cmd' is not installed. Please install it and re-run."
  fi
done
info "All required tools found."

# AWS credentials check 
info "Verifying AWS credentials..."
if ! aws sts get-caller-identity &>/dev/null; then
  error "AWS credentials are not configured. Run 'aws configure' or export AWS_* env vars."
fi
AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
info "Authenticated as AWS account: ${AWS_ACCOUNT}"

# SSH key generation
if [[ -f "${KEY_PATH}" ]]; then
  warn "SSH key already exists at ${KEY_PATH}. Skipping generation."
else
  info "Generating SSH key pair at ${KEY_PATH}..."
  ssh-keygen -t ed25519 -C "minecraft-server" -f "${KEY_PATH}" -N ""
  info "Key pair generated."
fi

# Terraform tfvars 
TFVARS="${TERRAFORM_DIR}/terraform.tfvars"
if [[ -f "${TFVARS}" ]]; then
  warn "terraform.tfvars already exists. Skipping copy."
else
  cp "${TERRAFORM_DIR}/terraform.tfvars.example" "${TFVARS}"
  # Update public key path to the generated key
  sed -i "s|~/.ssh/minecraft_key.pub|${KEY_PATH}.pub|" "${TFVARS}"
  info "Created terraform.tfvars from example. Edit it if you need custom values."
fi

info "Setup complete! Next steps:"
echo ""
echo "  1. Review  terraform/terraform.tfvars  and adjust if needed."
echo "  2. Run     ./scripts/provision.sh       to create AWS resources."
echo "  3. Run     ./scripts/configure.sh       to deploy the Minecraft server."
echo "  4. Verify  with the nmap command printed at the end of step 3."
