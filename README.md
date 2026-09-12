# Enterprise Multi-Cloud GitOps & Zero-Trust Infrastructure Pipeline

> Automated multi-cloud provisioning and application delivery system spanning AWS (EKS) and GCP (GKE) with GitOps continuous synchronization, HashiCorp Vault dynamic credentials, and Policy-as-Code CIS benchmark enforcement.

---

**Lead Architect:** William Free Hall (Free)  
*Principal Cloud & AI Architect • DevSecOps Lead*  
*18Z / 18F, U.S. Army Special Forces (Ret.)*  
**Email:** [whall4.wh@gmail.com](mailto:whall4.wh@gmail.com) • **LinkedIn:** [william-free-hall](https://linkedin.com/in/william-free-hall)

[![Terraform](https://img.shields.io/badge/IAC-TERRAFORM_1.8+-7B42BC?style=flat-square&logo=terraform&logoColor=white)](terraform/)
[![Kubernetes](https://img.shields.io/badge/K8S-EKS_%7C_GKE-326CE5?style=flat-square&logo=kubernetes&logoColor=white)](helm/)
[![GitOps](https://img.shields.io/badge/GITOPS-ARGO_CD-FF6B00?style=flat-square&logo=argo&logoColor=white)](argocd/)
[![Zero-Trust](https://img.shields.io/badge/SECURITY-HASHICORP_VAULT-000000?style=flat-square&logo=vault&logoColor=white)](terraform/modules/vault/)
[![Policy-as-Code](https://img.shields.io/badge/POLICY-OPA_%7C_CONFTEST_%7C_TRIVY-00FF66?style=flat-square&logo=open-policy-agent&logoColor=black)](policy/)
[![CI/CD](https://img.shields.io/badge/CI%2FCD-GITHUB_ACTIONS-2088FF?style=flat-square&logo=github-actions&logoColor=white)](.github/workflows/)

---

## Operational Problem Statement

Enterprise engineering organizations scaling multi-cloud Kubernetes clusters frequently struggle with:
1. **Configuration Drift & Inconsistent Multi-Cloud Topology:** Disconnected manual deployments across AWS and GCP create fragile, non-reproducible infrastructure.
2. **Static Credential Exposure:** Long-lived IAM access keys and Kubernetes secrets checked into code or static vaults present critical lateral movement vectors.
3. **Delivery Bottlenecks & Risky Releases:** Monolithic deployment procedures without automated Canary/Blue-Green traffic migration lead to deployment friction and outages.
4. **Late-Stage Compliance Failures:** Security and CIS benchmark scanning performed after deployment rather than shifted left as Policy-as-Code gatekeepers in CI/CD.

This project implements a **zero-trust, automated GitOps engine** addressing these operational challenges.

---

## System Architecture

```mermaid
flowchart TD
    subgraph DevSecOps ["1. Developer & CI/CD Pipeline (Shift-Left Security)"]
        GitCommit["Developer Git Commit<br/>Signed Commit"] --> GHAction["GitHub Actions CI"]
        GHAction --> Lint["Terraform / Helm Linting"]
        Lint --> Trivy["Trivy Vulnerability Scan<br/>(Container Images + IaC)"]
        Trivy --> OPA["OPA / Conftest Policy Enforcement<br/>(CIS Benchmark Gatekeeper)"]
    end

    subgraph GitOpsControl ["2. GitOps & Secrets Engine"]
        OPA -->|Approved PR Merge| ArgoCD["ArgoCD GitOps Controller<br/>Continuous State Reconciliation"]
        Vault["HashiCorp Vault / Cloud KMS<br/>Dynamic Short-Lived Tokens (mTLS)"]
        Vault -->|Inject Secrets| ArgoCD
    end

    subgraph MultiCloudWorkloads ["3. Multi-Cloud Kubernetes Clusters"]
        ArgoCD -->|Sync Manifests| EKS["AWS EKS (us-east-1)<br/>Private Node Groups"]
        ArgoCD -->|Sync Manifests| GKE["GCP GKE (us-central1)<br/>Workload Identity Nodes"]
        
        subgraph ClusterMesh ["Zero-Trust Istio Service Mesh"]
            EKS --- Istio["Istio Ingress Gateway + VirtualService<br/>Strict mTLS (PeerAuthentication)"]
            GKE --- Istio
            Istio --> Canary["Canary 90/10 Traffic Splitting"]
        end
    end
```

---

## Architectural Engineering Decisions & Trade-offs

| Architectural Decision | Chosen Implementation | Trade-Off & Rationale |
| :--- | :--- | :--- |
| **Multi-Cloud IaC Engine** | **Modular Terraform (AWS + GCP)** | Defined reusable, parameterized modules with remote state locking (S3/DynamoDB) and strict IAM boundary controls to eliminate cloud vendor lock-in. |
| **Continuous Delivery Engine** | **ArgoCD (Declarative GitOps)** | Pull-based reconciliation model prevents direct cluster access from CI runners, eliminating external attack surfaces against Kubernetes APIs. |
| **Secret Management** | **HashiCorp Vault & Cloud KMS** | Replaced static Kubernetes secrets with dynamic, short-lived tokens (TTL <= 1 hr) bound to Kubernetes ServiceAccounts via OIDC. |
| **Traffic Engineering** | **Istio Service Mesh (mTLS STRICT)** | Guarantees zero-trust encryption and cryptographic pod identity across services with automated 90/10 Canary progressive rollouts. |
| **Policy-as-Code Gatekeeper** | **Open Policy Agent (OPA) / Conftest** | Automatically blocks any Terraform plan or Kubernetes manifest violating CIS benchmarks (e.g., non-root containers, unencrypted storage, open 0.0.0.0/0 CIDRs). |

---

## Verified Test Execution

Automated test suite verifying OPA Rego policy syntax, Helm chart values security contexts, ArgoCD namespace destination configuration, and Terraform multi-cloud provider definitions:

```text
============================= test session starts =============================
platform win32 -- Python 3.11.0, pytest-9.1.1, pluggy-1.6.0 -- C:\Python311\python.exe
cachedir: .pytest_cache
rootdir: C:\Users\FreeF\projects\enterprise-multicloud-gitops-zerotrust
plugins: anyio-4.14.2
collecting ... collected 4 items

tests/test_policies.py::test_rego_policies_structure PASSED              [ 25%]
tests/test_policies.py::test_helm_chart_and_values PASSED                [ 50%]
tests/test_policies.py::test_argocd_manifest PASSED                      [ 75%]
tests/test_policies.py::test_terraform_structure PASSED                  [100%]

============================== 4 passed in 0.07s ==============================
```

---

## Zero-Trust & GitOps Operational Edge Cases

### 1. ArgoCD Destination Namespace Provisioning
When ArgoCD deploys to a target cluster where the destination namespace (`production-workloads`) does not yet exist, default sync cycles fail with `namespaces "production-workloads" not found`. In the GitOps spec, `syncOptions: [CreateNamespace=true]` is explicitly declared alongside `Validate=true` to ensure atomic prerequisite namespace bootstrapping without requiring out-of-band cluster administrative intervention.

### 2. OPA Policy Pre-Evaluation vs Rendered Manifests
Evaluating raw Helm templates directly with Conftest can yield false violations because Helm template interpolation expressions (e.g. `{{ .Values.securityContext.runAsNonRoot }}`) are not valid YAML. CI pipelines render the templates via `helm template` first into temporary manifests, ensuring Conftest and OPA evaluate real Kubernetes AST definitions.

### 3. Dynamic Vault Secret Token Leases & Mesh Connection Pools
When pods authenticate to HashiCorp Vault via Kubernetes ServiceAccount tokens (JWTs), Vault issues dynamic database credentials with 1-hour leases. If an application maintains long-lived TCP connection pools (e.g. SQLAlchemy or HikariCP), existing connections outlive the credential expiration without error, but new scale-out pods fail to connect if token renewal background tasks crash. The deployment manifests include Vault Agent sidecars with automated SIGHUP reloads on lease expiration.

---

## Repository Directory Structure

```text
enterprise-multicloud-gitops-zerotrust/
├── terraform/                      # Multi-Cloud Terraform IaC
│   ├── environments/
│   │   ├── dev/                    # Dev environment values & backend
│   │   └── prod/                   # Production environment values & remote state
│   ├── modules/
│   │   ├── aws_eks/                # Hardened AWS EKS cluster module
│   │   ├── gcp_gke/                # GCP GKE cluster with Workload Identity
│   │   └── vault/                  # HashiCorp Vault server & secret backend
│   ├── variables.tf                # Input variables
│   └── main.tf                     # Root coordinator module
├── helm/                           # Parameterized Helm 3 Application Charts
│   └── enterprise-app/
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/              # Deployments, Services, VirtualServices, mTLS
├── argocd/                         # Declarative ArgoCD GitOps Configurations
│   ├── application.yaml            # ArgoCD Application resource
│   └── appproject.yaml             # Multi-tenant RBAC project boundaries
├── policy/                         # Policy-as-Code Rules (OPA / Conftest)
│   ├── cis_kubernetes.rego         # CIS Kubernetes Benchmark compliance rules
│   └── cis_terraform.rego          # CIS Cloud Infrastructure compliance rules
├── tests/                          # Policy & Manifest validation test suite
│   └── test_policies.py
├── .github/workflows/              # Automated DevSecOps CI/CD Matrix
│   └── pipeline.yml                # Lint, Trivy Scan, OPA Conftest, and GitOps push
└── Makefile                        # Developer automation interface
```

---

## Security & Reliability Controls

1. **Zero-Trust Cryptographic Identity:** Every inter-service HTTP/gRPC request requires strict mutual TLS verification (`mTLS: STRICT`) managed by Istio sidecars.
2. **Least-Privilege Cloud IAM:** Node groups execute with minimal IAM permissions via AWS IAM Roles for Service Accounts (IRSA) and GCP Workload Identity.
3. **Automated Rollback & Pod Disruption:** Pod Disruption Budgets (`PDB`) ensure minimum 80% availability during cluster node draining; ArgoCD auto-reverts out-of-sync drifts.
4. **Shift-Left CIS Benchmark Gate:** Pull requests are automatically blocked if Trivy detects CVEs (CRITICAL/HIGH) or if OPA rules detect non-compliant infrastructure.

---

## Quickstart: Deployment & Verification

### 1. Prerequisites
* Terraform `>= 1.8.0`
* `kubectl` `>= 1.29`
* `helm` `>= 3.14`
* `python` `>= 3.10`

### 2. Validate Policy-as-Code & Manifests
```bash
# Run pytest test suite
pytest tests/ -v

# Run Makefile linters
make lint
make policy-test
```

### 3. Deploy Multi-Cloud Cluster & GitOps
```bash
# Initialize & Provision Multi-Cloud Infrastructure
make tf-init
make tf-plan
make tf-apply

# Bootstrap ArgoCD Controller
make gitops-bootstrap
```

---

## Author & Contact

**William Free Hall (Free)**  
*Principal Cloud & AI Architect • DevSecOps Lead*  
*18Z / 18F, U.S. Army Special Forces (Ret.)*  
Email: [whall4.wh@gmail.com](mailto:whall4.wh@gmail.com)  
GitHub: [https://github.com/FreeFades2Black](https://github.com/FreeFades2Black)  
LinkedIn: [https://linkedin.com/in/william-free-hall](https://linkedin.com/in/william-free-hall)
