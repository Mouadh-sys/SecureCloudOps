#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "${ROOT_DIR}/terraform/environments/dev"

echo "Destroying SecureCloudOps Terraform resources..."
terraform destroy
