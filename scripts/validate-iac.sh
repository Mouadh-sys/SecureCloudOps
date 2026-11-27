#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="${ROOT_DIR}/terraform/environments/dev"

if ! command -v terraform >/dev/null 2>&1; then
    echo "terraform is required but was not found on PATH." >&2
    exit 127
fi

LOCAL_CHECKOV="${ROOT_DIR}/.venv/bin/checkov"
CHECKOV_COMMAND="checkov"

if [[ -x "${LOCAL_CHECKOV}" ]] && "${LOCAL_CHECKOV}" --version >/dev/null 2>&1; then
    CHECKOV_COMMAND="${LOCAL_CHECKOV}"
elif ! command -v checkov >/dev/null 2>&1 || ! checkov --version >/dev/null 2>&1; then
    echo "A working Checkov installation is required for local IaC policy checks." >&2
    echo "Install the pinned dependency with: python3 -m venv .venv && .venv/bin/python -m pip install -r requirements-dev.txt" >&2
    exit 127
fi

terraform -chdir="${TF_DIR}" fmt -check -recursive
terraform -chdir="${TF_DIR}" validate
"${CHECKOV_COMMAND}" --directory "${ROOT_DIR}/terraform" --framework terraform
