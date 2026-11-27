#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../scripts" && pwd)"
exec "${SCRIPT_DIR}/check-capabilities.sh" "$@"