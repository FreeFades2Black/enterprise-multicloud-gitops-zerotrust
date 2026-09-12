# ADR-0001: Workload Identity Federation via SPIFFE/SPIRE over Static Service Account Tokens

**Status:** Accepted
**Date:** 2026-06-18
**Lead Architect:** William Free Hall (Free) <whall4.wh@gmail.com>

## Context & Problem Statement
Our multi-cloud Kubernetes deployment (AWS EKS and GCP GKE) requires microservices to authenticate cross-cloud to shared databases, Vault secrets engines, and message queues without persisting long-lived credentials. Standard Kubernetes ServiceAccount tokens are bound to a single cluster OIDC provider, forcing brittle manual IAM trust relationship maps or long-lived API keys that risk exfiltration.

## Options Considered
1. **Option A: Static Cloud IAM Credentials Stored in Kubernetes Secrets**
   - *Pros:* Trivial initial setup, native SDK support.
   - *Cons:* Violates CIS benchmarks, requires external rotation automation, vulnerability to exfiltration on pod compromise.
2. **Option B: Dual-Cloud Native Workload Identity (AWS IRSA + GCP Workload Identity)**
   - *Pros:* Cloud-native, zero secret storage.
   - *Cons:* Disjointed identity providers require services to maintain distinct authentication logic depending on host cloud; cannot issue unified cryptographically verifiable identity for cross-cloud mTLS.
3. **Option C: Unified SPIFFE/SPIRE Workload Attestation with Short-Lived X.509 SVIDs**
   - *Pros:* Platform-agnostic, cryptographically attested workload identities (SVIDs) with 1-hour TTLs, automatic mTLS sidecar integration, unified trust domain (spiffe://enterprise.net).
   - *Cons:* Operational complexity of running SPIRE server cluster and node agents with privileged host socket mounts.

## Decision & Trade-Off Accepted
We adopted **Option C: Unified SPIFFE/SPIRE Workload Attestation**. We accept the operational overhead of managing SPIRE server synchronization and node agent DaemonSets in exchange for eliminating static secrets and enabling zero-trust cross-cloud pod-to-pod mutual TLS.
