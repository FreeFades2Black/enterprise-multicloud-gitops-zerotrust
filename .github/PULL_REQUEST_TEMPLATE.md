## Operational Summary
*Describe what infrastructure or policy change is introduced and the operational motivation.*

- [ ] Infrastructure Provisioning (Terraform / Provider)
- [ ] Policy-as-Code Rule (OPA / Rego / Conftest)
- [ ] Application Delivery / Helm Manifest (ArgoCD)
- [ ] Zero-Trust Identity (Vault / SPIFFE / mTLS)

## Architectural Impact & Blast Radius
- **Target Environments:** `AWS-EKS-us-east-1` / `GCP-GKE-us-central1` / Management Hub
- **Security & Compliance Impact:** Any modifications to CIS Benchmarks or IAM boundaries?
- **Rollback Plan:** Exact commands to restore prior state upon synchronization failure.

## Verification Evidence
- [ ] Conftest CIS benchmarks passed: `make policy-test`
- [ ] Helm template rendered cleanly: `helm template helm/enterprise-app`
- [ ] Trivy vulnerability scan clean (0 High/Critical): `make security-scan`
- [ ] Unit & policy test suite verified: `pytest tests/`
- [ ] Infracost monthly differential reviewed (no unbudgeted cloud spend)
