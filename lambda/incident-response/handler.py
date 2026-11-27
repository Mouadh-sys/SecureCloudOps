import json
import os
from datetime import datetime, timezone
import boto3


def classify(detail):
    severity = detail.get("severity")
    if isinstance(severity, (int, float)):
        if severity >= 7:
            return "CRITICAL"
        if severity >= 4:
            return "HIGH"
        if severity >= 2:
            return "MEDIUM"
        return "LOW"

    findings = detail.get("findings", [])
    severity_labels = [
        finding.get("Severity", {}).get("Label", "").upper()
        for finding in findings
        if isinstance(finding, dict)
    ]
    if "CRITICAL" in severity_labels:
        return "CRITICAL"
    if "HIGH" in severity_labels:
        return "HIGH"
    if severity_labels:
        return severity_labels[0]
    return "MEDIUM"


def handler(event, context):
    detail = event.get("detail", {})
    classification = classify(detail)
    record = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "classification": classification,
        "source": event.get("source", "unknown"),
        "detail_type": event.get("detail-type", "unknown"),
        "action": "notification_only",
        "finding_summary": detail.get("title") or detail.get("description") or "Security finding received",
    }

    logs = boto3.client("logs")
    stream_name = context.log_stream_name
    try:
        logs.create_log_stream(
            logGroupName=os.environ["SECURITY_LOG_GROUP"],
            logStreamName=stream_name,
        )
    except logs.exceptions.ResourceAlreadyExistsException:
        pass
    logs.put_log_events(
        logGroupName=os.environ["SECURITY_LOG_GROUP"],
        logStreamName=stream_name,
        logEvents=[{"timestamp": int(datetime.now(timezone.utc).timestamp() * 1000),
                    "message": json.dumps(record)}],
    )

    boto3.client("sns").publish(
        TopicArn=os.environ["SNS_TOPIC_ARN"],
        Subject=f"SecureCloudOps {classification} security finding",
        Message=json.dumps(record, indent=2),
    )
    return {"statusCode": 200, "classification": classification}
