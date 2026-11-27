# SecureCloudOps
## Architecture Specification

**Version:** 1.0  
**Status:** Proposed baseline  
**Cloud provider:** Amazon Web Services  
**Deployment environment:** AWS Academy Learner Lab  
**Target region:** `us-east-1`  
**Infrastructure as Code:** Terraform  
**Project type:** Cloud security engineering and automated security operations

---

## 1. Project Overview

### 1.1 Objective

SecureCloudOps is a Terraform-driven AWS environment designed to demonstrate how an enterprise cloud workload can be securely deployed, monitored, protected, and recovered.

The project implements a simulated enterprise document-management platform that stores confidential customer documents and associated business metadata.

The environment combines:

- Secure cloud networking and workload isolation.
- Identity and access management.
- Encryption and secrets management.
- Data protection and retention.
- Centralized logging and threat detection.
- Event-driven security monitoring.
- Controlled incident response.
- Backup and recovery.

The project is intended as an academic security engineering environment, not a production-ready enterprise platform.

### 1.2 Main scenario

A small enterprise operates a document-management application used by employees to manage customer documents.

The application relies on:
- An application server hosted on Amazon EC2.
- Amazon RDS for structured business metadata.
- Amazon S3 for document storage.
- AWS KMS for encryption.
- AWS Secrets Manager for application credentials.

The security environment must protect these resources against unauthorized access, data exposure, suspicious workload activity, and accidental or malicious data loss.

When a security finding occurs, the platform must detect it, classify it, record relevant evidence, and notify the security operator. Controlled containment of designated laboratory resources is an optional later capability.

### 1.3 Project goals

1. Deploy a logically segmented AWS environment.
2. Enforce least-privilege access for users and workloads.
3. Protect stored documents, database records, and credentials.
4. Collect and monitor security-relevant events.
5. Detect suspicious activity using AWS security services.
6. Automate security alert processing and controlled response.
7. Demonstrate backup, retention, and recovery mechanisms.
8. Manage infrastructure through reusable Terraform modules.

---

## 2. High-Level Architecture

The architecture is divided into six logical domains:

| Domain | Responsibility |
|---|---|
| Identity and access | Authentication, authorization, temporary credentials |
| Network and workloads | Network isolation and application infrastructure |
| Data protection | Storage, encryption, secrets, retention |
| Security monitoring | Logging, threat detection, centralized findings |
| Incident response | Event processing, notification, controlled containment |
| Backup and recovery | Backup policies, retention, restoration |

### 2.1 Architecture diagram

```mermaid
flowchart TB
    U["Enterprise Users"]
    OP["Security Operator"]

    subgraph AWS["AWS - us-east-1"]
        subgraph NET["VPC - 10.20.0.0/16"]
            ALB["Application Load Balancer"]
            EC2["EC2 Application Tier"]
            RDS["RDS Database"]

            ALB --> EC2
            EC2 --> RDS
        end

        S3["Private S3 Document Bucket"]
        KMS["AWS KMS"]
        SM["Secrets Manager"]

        EC2 --> S3
        EC2 --> SM
        EC2 --> KMS
        RDS --> KMS
        S3 --> KMS

        subgraph DET["Security Monitoring"]
            CT["CloudTrail"]
            GD["GuardDuty"]
            MAC["Macie"]
            SH["Security Hub"]
            CW["CloudWatch"]
        end

        subgraph IR["Incident Response"]
            EB["EventBridge"]
            L["Lambda Response Handler"]
            SNS["SNS Notifications"]
        end

        AB["IAM Access Analyzer"]
        BK["AWS Backup"]
        GL["S3 Lifecycle / Glacier"]
    end

    U -->|"HTTPS"| ALB
    OP -->|"Authorized administration"| AWS

    NET -.->|"VPC Flow Logs"| CW
    CT --> CW
    GD --> SH
    MAC --> SH
    GD --> EB
    SH --> EB
    CW --> EB
    EB --> L
    L --> SNS
    SNS --> OP

    S3 --> MAC
    S3 --> GL
    RDS --> BK
    EC2 --> BK
    AB -.->|"Access analysis"| AWS
```

The diagram describes logical relationships. It does not imply that every component will be deployed in the first implementation iteration.

---

## 3. Network and Workload Architecture

### 3.1 VPC

Create one dedicated VPC:

- Name: `securecloudops-vpc`
- CIDR: `10.20.0.0/16`
- Region: `us-east-1`
- Availability zones: two for the target architecture

### 3.2 Subnet layout

| Subnet | CIDR | Purpose |
|---|---|---|
| Public AZ-1 | `10.20.0.0/24` | Public-facing load balancer |
| Public AZ-2 | `10.20.1.0/24` | Public-facing load balancer |
| Application AZ-1 | `10.20.10.0/24` | Application workloads |
| Application AZ-2 | `10.20.11.0/24` | Application workloads |
| Database AZ-1 | `10.20.20.0/24` | Private database tier |
| Database AZ-2 | `10.20.21.0/24` | Private database tier |

The actual Availability Zone names will be discovered dynamically by Terraform.

### 3.3 Network components

- Amazon VPC.
- Internet Gateway.
- Public and private route tables.
- Subnet associations.
- Security Groups.
- Network ACLs where justified.
- VPC Flow Logs.

### 3.4 Network security rules

**Public load balancer**
- Accept HTTPS traffic on TCP/443.
- No unrestricted administrative access.

**Application tier**
- Accept application traffic only from the load balancer Security Group.
- No direct public SSH access.
- Access to the database only through the required database port.
- Restrict access to AWS services through appropriate endpoints or controlled egress.

**Database tier**
- No public IP address.
- Accept database connections only from the application Security Group.
- Use encryption at rest.

Security Groups are the primary workload-level access control. Network ACLs provide additional subnet-level filtering where useful.

### 3.5 Network cost policy

A NAT Gateway will not be enabled by default in the Academy environment.

The private workloads will use the minimum required connectivity, such as an S3 Gateway Endpoint and selected interface endpoints, where permitted and economically justified.

A full production deployment may require controlled outbound connectivity.

---

## 4. Identity and Access Management

### 4.1 Identity model

All access must follow least privilege.

The project uses:

- AWS Academy temporary credentials for the deployment operator.
- AWS IAM roles for application workloads.
- Dedicated IAM roles for Lambda response automation.
- AWS STS temporary credentials.
- IAM policies scoped to required resources and actions.
- IAM Access Analyzer to identify unintended external access.

No permanent AWS access keys will be embedded in application code or Terraform configuration.

### 4.2 Workload identities

**Application EC2 role**

Permissions should be limited to:
- Read and write authorized document objects in the designated S3 bucket.
- Retrieve the required application secret.
- Use the designated KMS key for permitted cryptographic operations.
- Interact with explicitly authorized AWS resources.

**Incident response Lambda role**

Permissions should be limited to:
- Read the required security event.
- Write incident processing logs.
- Publish notifications.
- Perform explicitly authorized containment operations when that feature is enabled.

The Lambda function must not receive administrator permissions.

---

## 5. Data Protection Architecture

### 5.1 Amazon S3

The document-management platform uses a private S3 bucket.

Security configuration:

- S3 Block Public Access enabled.
- Bucket versioning enabled.
- Server-side encryption using AWS KMS.
- HTTPS-only bucket access.
- Restricted bucket policies.
- Application role access limited to the required bucket and prefixes.
- S3 Object Lock as an optional retention control.
- Lifecycle policies for archival.

### 5.2 KMS

Use AWS KMS customer-managed keys where permissions and account capabilities allow.

Encryption targets:

- S3 document objects.
- RDS database storage.
- EC2 EBS volumes.
- Backup resources where supported.

Key policies must grant access only to authorized identities and services.

### 5.3 Secrets Manager

Database credentials and other application secrets are stored in AWS Secrets Manager.

Application instances retrieve credentials at runtime through their IAM role.

Secrets must never be:
- Committed to Git.
- Stored in Terraform source code.
- Passed through unprotected user data.
- Written to application logs.

### 5.4 Amazon Macie

Macie is used to inspect the S3 document bucket for potentially sensitive data.

Its purpose is to demonstrate data discovery and identify potential accidental exposure of sensitive information.

Macie deployment is conditional on Academy permissions and service costs.

### 5.5 S3 Object Lock and Glacier

S3 Object Lock demonstrates retention and protection against object deletion or modification.

The initial design should use a carefully scoped retention policy. Object Lock configuration must be decided when the bucket is created.

S3 Lifecycle rules can transition eligible objects to an Amazon S3 Glacier storage class.

---

## 6. Application and Database Architecture

### 6.1 Amazon EC2

EC2 hosts the document-management application.

Security requirements:

- Deployed in the private application subnet.
- Encrypted EBS storage.
- IAM instance role.
- Restricted Security Group.
- No SSH from the public internet.
- Centralized application logging.
- Administrative access through an authorized management channel where available.

The initial deployment can use a single test instance. The target architecture supports multiple application instances across two Availability Zones.

### 6.2 Amazon RDS

RDS stores structured application metadata, such as:

- Document identifiers.
- Document names.
- Customer references.
- Document status.
- Creation timestamps.
- Ownership and access metadata.

Security requirements:

- Private database subnets.
- Public accessibility disabled.
- Encryption at rest.
- Credentials retrieved from Secrets Manager.
- Network access restricted to the application tier.
- Backup policy attached through AWS Backup.

### 6.3 AWS Certificate Manager

ACM supplies the TLS certificate used by the public-facing load balancer.

ACM Private CA is not included in the initial implementation because it introduces additional complexity and cost without being necessary for the project's core scenario.

---

## 7. Security Monitoring and Threat Detection

### 7.1 AWS CloudTrail

CloudTrail records AWS API activity.

The project uses it to audit administrative and infrastructure operations.

Requirements:
- Capture management events.
- Store logs in a dedicated protected S3 bucket.
- Integrate with CloudWatch Logs where supported.
- Consider data events for the document bucket as a separately costed enhancement.

### 7.2 Amazon CloudWatch

CloudWatch provides centralized observability.

It receives or monitors:
- Application logs.
- EC2 operating metrics.
- VPC Flow Logs.
- CloudTrail events where configured.
- Lambda execution logs.
- Security-related alarms.

### 7.3 Amazon GuardDuty

GuardDuty analyzes supported AWS telemetry to identify suspicious activity.

Examples:
- Suspicious API activity.
- Potentially compromised EC2 workloads.
- Unusual network behavior.
- Threat indicators reported by GuardDuty.

### 7.4 AWS Security Hub

Security Hub provides a centralized view of supported security findings.

It is used to consolidate and review security information from integrated AWS services.

### 7.5 IAM Access Analyzer

Access Analyzer checks for unintended resource access and external sharing.

It is part of the identity and resource exposure assessment process.

### 7.6 Amazon Macie

Macie identifies potentially sensitive information in S3 and helps identify data exposure risks.

---

## 8. Incident Response Architecture

### 8.1 Event-driven workflow

The response pipeline uses:

- GuardDuty.
- Security Hub.
- Amazon EventBridge.
- AWS Lambda.
- Amazon SNS.
- CloudWatch Logs.

Workflow:

1. A monitored AWS service generates a security finding.
2. EventBridge receives the matching event.
3. EventBridge invokes the response Lambda function.
4. Lambda validates and parses the finding.
5. The finding is classified using severity and resource context.
6. The response is recorded in CloudWatch Logs.
7. A notification is sent through SNS.
8. The security operator reviews and determines the next action.

### 8.2 Initial response mode

The first implementation uses **notification and evidence recording only**.

This avoids accidentally isolating legitimate resources or modifying critical infrastructure.

### 8.3 Optional controlled containment

A later implementation may isolate a dedicated test EC2 instance by attaching a quarantine Security Group.

Containment requirements:

- Only explicitly designated laboratory instances are eligible.
- The target must carry the expected project and resource tags.
- The Lambda role must have narrowly scoped permissions.
- The action must be logged.
- The behavior must be reversible.
- Automatic containment must be disabled by default.

The response function must never delete resources, modify unrelated IAM policies, or disable security monitoring.

---

## 9. Backup and Recovery Architecture

### 9.1 AWS Backup

AWS Backup protects supported compute and database resources.

Initial targets:
- EBS volumes associated with the test workload.
- RDS database instances.

### 9.2 Backup Audit Manager

Backup Audit Manager is used to evaluate backup policy compliance and report deviations where supported.

### 9.3 Recovery validation

A backup is not considered successful merely because it exists.

The project must demonstrate:
- A successful backup operation.
- A restore operation into an isolated test environment.
- Verification that restored data is accessible.
- Recording of restoration results.

Retention periods are configurable and must be selected according to Academy limits and cost constraints.

---

## 10. Terraform Architecture

Terraform is the infrastructure source of truth.

The project will use reusable, independently understandable modules.

```text
SecureCloudOps/
│
├── terraform/
│   ├── environments/
│   │   └── dev/
│   │       ├── main.tf
│   │       ├── provider.tf
│   │       ├── variables.tf
│   │       ├── outputs.tf
│   │       └── versions.tf
│   │
│   └── modules/
│       ├── networking/
│       ├── identity/
│       ├── compute/
│       ├── data-protection/
│       ├── database/
│       ├── audit-logging/
│       ├── threat-detection/
│       ├── incident-response/
│       └── backup/
│
├── lambda/
│   └── incident-response/
│
├── security/
│   ├── environment.md
│   ├── capability-matrix.md
│   ├── threat-model.md
│   ├── test-cases.md
│   └── findings.md
│
├── docs/
│   ├── architecture.md
│   ├── deployment.md
│   └── recovery-procedure.md
│
├── scripts/
│   ├── check-capabilities.sh
│   └── cleanup.sh
│
├── .gitignore
└── README.md
```

### 10.1 Terraform rules

- Terraform is the source of truth for managed infrastructure.
- Use variables for environment-specific configuration.
- Use outputs to expose module interfaces.
- Use data sources to discover supported Availability Zones and account metadata.
- Commit `.terraform.lock.hcl`.
- Do not commit Terraform state.
- Do not commit credentials or secret variable files.
- Keep state local until an appropriate remote backend is verified and configured.
- Use common resource tags.
- Document resource cleanup and retention exceptions.

The AWS Academy execution role is treated as an externally supplied identity. Terraform will not attempt to replace or administer that role.

---

## 11. Service Scope and Implementation Priority

The architecture covers the following services from the course.

| AWS service | Architectural role | Priority |
|---|---|---|
| IAM | Access management | Core |
| STS | Temporary credentials | Core |
| IAM Access Analyzer | External access assessment | Core |
| VPC | Network isolation | Core |
| EC2 | Application workload | Core |
| EBS | Workload storage | Core |
| S3 | Document storage and audit logs | Core |
| KMS | Encryption | Core |
| Secrets Manager | Credential protection | Core |
| CloudTrail | API auditing | Core |
| CloudWatch | Monitoring and logging | Core |
| EventBridge | Security event routing | Core |
| Lambda | Response automation | Core |
| GuardDuty | Threat detection | Conditional |
| Security Hub | Centralized findings | Conditional |
| Macie | Sensitive data discovery | Conditional |
| RDS | Relational data storage | Conditional |
| ACM | TLS certificate management | Conditional |
| S3 Object Lock | Retention protection | Conditional |
| S3 Glacier | Long-term archival | Conditional |
| AWS Backup | Backup and restore | Conditional |
| Backup Audit Manager | Backup compliance assessment | Conditional |

**Core** means necessary to the project's logical foundation. **Conditional** means deployment depends on Academy permissions, service availability, and acceptable costs. These classifications do not imply that every service has already been verified in the account.

### 11.1 Services deliberately excluded from the baseline

- **AWS Directory Service and Amazon WorkSpaces:** Not required for the selected document-management scenario.
- **ACM Private CA:** Not required for the initial TLS use case.
- **DynamoDB:** RDS is the selected structured metadata database.
- **Elastic Beanstalk:** EC2 is the selected application compute model. Beanstalk could replace this deployment approach in a future variant.

These exclusions are architectural choices, not claims that the services are unavailable.

---

## 12. Implementation Phases

### Phase 0 - Environment readiness

- Verify AWS Academy credentials.
- Identify account and region.
- Inspect service permissions.
- Verify quotas and resource availability.
- Establish cost and cleanup constraints.

### Phase 1 - Secure foundation

- Terraform environment.
- VPC and subnet architecture.
- Security Groups and route tables.
- IAM workload roles where permitted.
- KMS foundations.
- CloudTrail.
- VPC Flow Logs.

### Phase 2 - Workload and data protection

- EC2 test workload.
- EBS encryption.
- S3 document bucket.
- KMS encryption.
- Secrets Manager.
- RDS if available.
- ACM and load balancer if justified.

### Phase 3 - Security monitoring

- CloudWatch logging and alarms.
- GuardDuty.
- Security Hub.
- Macie.
- IAM Access Analyzer.
- EventBridge rules.

### Phase 4 - Automated response

- Lambda response processor.
- Event validation and severity classification.
- Evidence logging.
- SNS notification.
- Optional controlled quarantine.

### Phase 5 - Backup and validation

- AWS Backup.
- Backup Audit Manager.
- S3 retention and lifecycle.
- Restore validation.
- Security test execution.
- Architecture and results documentation.

The phases may be split into smaller Terraform deployment increments to accommodate the temporary Academy environment.

---

## 13. Security Validation Scenarios

The final project must demonstrate security controls through tests, not just resource creation.

| ID | Scenario | Expected result |
|---|---|---|
| SC-01 | Attempt public access to the document bucket | Access denied |
| SC-02 | Attempt database access from an unauthorized network source | Connection denied |
| SC-03 | Attempt application access without authorized credentials | Access denied |
| SC-04 | Inspect S3 encryption configuration | KMS encryption confirmed |
| SC-05 | Inspect EC2 storage configuration | EBS encryption confirmed |
| SC-06 | Generate a controlled security test event | Finding is processed |
| SC-07 | Trigger an EventBridge rule | Lambda is invoked |
| SC-08 | Process a simulated security finding | Finding is logged and notification sent |
| SC-09 | Inspect externally accessible resources | Access Analyzer findings reviewed |
| SC-10 | Restore a protected workload resource | Restored resource is validated |

Tests must be performed only against resources in the designated project environment.

---

## 14. Architectural Constraints and Risks

1. AWS Academy permissions can prevent creation or configuration of certain resources.
2. Temporary credentials may expire during implementation.
3. Some security services generate usage-based charges.
4. Multi-AZ deployments, load balancers, NAT Gateways, interface endpoints, and database resources may increase cost.
5. Some services require account-level enablement or service-linked roles.
6. S3 Object Lock retention can make cleanup difficult or impossible before the retention period expires.
7. Academy environments can reset, terminate, or restrict resources.

The architecture must be adapted when a capability is unavailable, but alternatives must preserve the intended security objective wherever possible.

---

## 15. Architectural Decision Register

| ID | Decision | Rationale |
|---|---|---|
| ADR-001 | Use Terraform | Reproducible infrastructure and IaC practice |
| ADR-002 | Use `us-east-1` | Selected project region |
| ADR-003 | Use AWS Academy | Educational deployment environment |
| ADR-004 | Model a document-management workload | Coherent scenario for multiple security domains |
| ADR-005 | Use IAM roles and temporary credentials | Least privilege and reduced secret exposure |
| ADR-006 | Use EC2 and RDS as the primary application stack | Explicit workload and database security controls |
| ADR-007 | Use S3 and KMS for document protection | Central data protection mechanism |
| ADR-008 | Use EventBridge and Lambda for response automation | Event-driven security operations |
| ADR-009 | Begin with notification-only response | Avoid unsafe automatic containment |
| ADR-010 | Avoid NAT Gateway by default | Control laboratory costs |
| ADR-011 | Separate target architecture from lab deployment | Preserve architectural intent despite Academy limitations |
| ADR-012 | Require validation before claiming a control works | Evidence-based security testing |

---

## 16. Definition of Done

SecureCloudOps is complete when:

- The implemented infrastructure can be reproduced using Terraform.
- The network and workload boundaries are documented and validated.
- IAM access is scoped to the required resources.
- Data storage and encryption controls are tested.
- Relevant AWS activity is logged.
- Available detection services are configured and tested.
- Security findings can be processed and notifications delivered.
- Backup and restoration are demonstrated where the services are available.
- Security test results and limitations are documented.
- Resources can be cleaned up safely without violating retention requirements.

**Final principle:** The architecture defines the desired security properties. Terraform implements them, AWS services enforce them, and the test results provide evidence that they work.