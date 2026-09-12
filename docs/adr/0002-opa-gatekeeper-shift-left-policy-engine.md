# ADR-0002: OPA Gatekeeper Admission Controller with Conftest Pre-Commit Gating

**Status:** Accepted  
**Date:** 2026-07-02  
**Lead Architect:** William Free Hall (Free) <whall4.wh@gmail.com>

## 1. Context & Operational Challenge
We must enforce strict CIS Kubernetes and CIS Terraform compliance rules: disallow privileged containers, mandate read-only root filesystems, restrict hostPath mounts to approved paths, and enforce tagged container registries. We needed an engine that executes identical policies in local pre-commit, CI pull requests, and live cluster admission webhooks.

## 2. Options Considered
* **Option A: Kyverno CRD-Based Policy Controller**
  - *Evaluation:* YAML-native syntax lowers learning curve, but lacks a clean, standalone offline CLI runner matching CI environments without cluster mocking.
* **Option B: Open Policy Agent (OPA) Gatekeeper + Conftest**
  - *Evaluation:* Declarative Rego language provides relational expressiveness across resources; `conftest` CLI runs offline in under 0.1s during CI; industry benchmark standard.

## 3. Decision & Trade-Off Accepted
We adopted **Option B (OPA Gatekeeper + Conftest)**.  
**Trade-Off Accepted:** The engineering team must maintain Rego policy definitions rather than standard YAML. We mitigate webhook admission latency by capping webhook timeouts at 3000ms with fail-open policies on non-sensitive workloads.
