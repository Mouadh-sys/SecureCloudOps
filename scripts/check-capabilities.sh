#!/usr/bin/env bash

set -uo pipefail

export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-east-1}"
failures=0

check() {
    local name="$1"
    local status
    shift

    printf '\n========== %s ==========\n' "$name"
    if "$@" 2>&1; then
        printf 'Result: available\n'
    else
        status=$?
        printf 'Result: failed (exit code: %s)\n' "$status"
        failures=$((failures + 1))
    fi
}

check "IAM" aws iam get-account-summary
check "ACCESS ANALYZER" aws accessanalyzer list-analyzers
check "VPC" aws ec2 describe-vpcs
check "SECURITY GROUPS" aws ec2 describe-security-groups
check "S3" aws s3api list-buckets
check "KMS" aws kms list-aliases
check "CLOUDTRAIL" aws cloudtrail describe-trails
check "GUARDDUTY" aws guardduty list-detectors
check "SECURITY HUB" aws securityhub describe-hub
check "MACIE" aws macie2 get-macie-session
check "LAMBDA" aws lambda list-functions
check "EVENTBRIDGE" aws events list-rules
check "CLOUDWATCH" aws cloudwatch describe-alarms
check "AWS BACKUP" aws backup list-backup-vaults
check "RDS" aws rds describe-db-instances

if (( failures > 0 )); then
    printf '\nCapability checks failed: %s\n' "$failures" >&2
    exit 1
fi

printf '\nAll capability checks succeeded.\n'
