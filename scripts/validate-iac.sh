#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="${ROOT_DIR}/terraform/environments/dev"

if ! command -v terraform >/dev/null 2>&1; then
    echo "terraform is required but was not found on PATH." >&2
    exit 127
fi

if ! command -v checkov >/dev/null 2>&1; then
    echo "checkov is required for local IaC policy checks but was not found on PATH." >&2
    echo "Install Checkov, then rerun this script." >&2
    exit 127
fi

terraform -chdir="${TF_DIR}" fmt -check -recursive
terraform -chdir="${TF_DIR}" validate
checkov --directory "${ROOT_DIR}/terraform" --framework terraform
