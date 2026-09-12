# Operational Runbook: ArgoCD Application Sync Drift & Gatekeeper Rejection Triage

**Severity:** P2 / Operational Degraded  
**Target Systems:** ArgoCD Controller, OPA Gatekeeper, EKS/GKE API Endpoints

## Diagnostic Workflow

### 1. Check Application Status & Sync State
```bash
# Query application condition and comparison error
argocd app get enterprise-app --refresh
kubectl -n argocd get application enterprise-app -o jsonpath='{.status.conditions}' | jq .
```

### 2. Diff Live Cluster State Against Git Desired State
```bash
# Hard refresh to eliminate stale redis cache
argocd app diff enterprise-app --hard-refresh
```

### 3. Diagnose Admission Webhook Denials
If sync error includes `admission webhook "validation.gatekeeper.sh" denied the request`:
```bash
kubectl -n gatekeeper-system logs -l control-plane=controller-manager --tail=100 \
  | grep -E "(denied|rejection|fail)"
```

### 4. Step-by-Step Remediation
1. **If Spec Drift is Legitimate Emergency Hotfix:**
   ```bash
   argocd app sync enterprise-app --replace --force --prune
   ```
2. **If Gatekeeper Constraint Violated:**
   Run local Conftest validation against failing manifest:
   ```bash
   conftest test helm/enterprise-app/templates/*.yaml -p policy/cis_kubernetes.rego
   ```
   Fix security context (e.g. `runAsNonRoot: true`, `readOnlyRootFilesystem: true`) and push commit to branch.
