# ADR-0002: OPA Gatekeeper Admission Controller vs Kyverno for Policy Enforcement

**Status:** Accepted
**Date:** 2026-07-02
**Lead Architect:** William Free Hall (Free) <whall4.wh@gmail.com>

## Context & Problem Statement
To meet CIS Kubernetes benchmark compliance across heterogeneous clusters, we must enforce strict admission controls: blocking privileged containers, mandating read-only root filesystems, restricting hostPath mounts, and enforcing internal container registry origins. We needed a declarative Policy-as-Code engine capable of both pre-commit CI validation and admission-time enforcement.

## Options Considered
1. **Option A: Kyverno (Kubernetes Native Policy Engine)**
   - *Pros:* Expressed purely as YAML CRDs; lower learning curve for Kubernetes operators; built-in mutation and generation capabilities.
   - *Cons:* Limited language expressiveness for complex multi-resource relational logic (e.g. cross-referencing Ingress hosts with Service endpoints); lacks portable offline CLI execution identical to CI runner without cluster dependency.
2. **Option B: Open Policy Agent (OPA) with Gatekeeper & Conftest**
   - *Pros:* Declarative Rego language provides Turing-complete relational query power; conftest allows exact same policies to run locally in pre-commit and CI/CD without spinning up a cluster; industry standard for multi-cloud governance.
   - *Cons:* Requires engineering team to learn Rego syntax; admission webhook latency impact during burst deployment spikes.

## Decision & Trade-Off Accepted
We selected **Option B: OPA Gatekeeper with Conftest**. We accept the requirement to author and test Rego policies in exchange for unified shift-left testing (developer local workstation -> CI pipeline -> cluster admission webhook) using identical policy files. Webhook latency is capped at 3000ms with non-blocking failover policies for non-security namespaces.
