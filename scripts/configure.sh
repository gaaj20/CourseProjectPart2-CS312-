#!/usr/bin/env bash
# scripts/configure.sh
# This runs the Ansible playbook to install and start the Minecraft server on the EC2 instance.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANSIBLE_DIR="${SCRIPT_DIR}/../ansible"
TERRAFORM_DIR="${SCRIPT_DIR}/../terraform"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

# Preflight 
[[ -f "${ANSIBLE_DIR}/inventory.ini" ]] || \
  error "inventory.ini not found. Run scripts/provision.sh first."

grep -q "REPLACE_WITH_PUBLIC_IP" "${ANSIBLE_DIR}/inventory.ini" && \
  error "inventory.ini still has placeholder IP. Run scripts/provision.sh first."

# Wait for SSH 
PUBLIC_IP=$(grep "ansible_host=" "${ANSIBLE_DIR}/inventory.ini" | \
  grep -oP 'ansible_host=\K[^\s]+')

info "Waiting for SSH to be available on ${PUBLIC_IP}..."
RETRIES=20
for i in $(seq 1 $RETRIES); do
  if ssh -o StrictHostKeyChecking=no \
         -o ConnectTimeout=5 \
         -i ~/.ssh/minecraft_key \
         ec2-user@"${PUBLIC_IP}" "echo ok" &>/dev/null; then
    info "SSH is ready."
    break
  fi
  warn "SSH not ready yet (attempt ${i}/${RETRIES}). Retrying in 15s..."
  sleep 15
  [[ $i -eq $RETRIES ]] && error "SSH never became available. Check the instance."
done

# Run Ansible playbook 
info "Running Ansible playbook..."
ansible-playbook \
  -i "${ANSIBLE_DIR}/inventory.ini" \
  "${ANSIBLE_DIR}/playbook.yml" \
  --private-key ~/.ssh/minecraft_key \
  -v

# Verify server
info "Waiting 30 seconds for Minecraft to finish starting up..."
sleep 30

NMAP_CMD="nmap -sV -Pn -p T:25565 ${PUBLIC_IP}"
info "Running: ${NMAP_CMD}"
${NMAP_CMD}

echo ""
info "Configuration complete!"
echo ""
echo "  Minecraft server: ${PUBLIC_IP}:25565"
echo "  Connect in-game : Add '${PUBLIC_IP}' as a server in Minecraft Java Edition."
echo "  Verify open port: ${NMAP_CMD}"
