# ADR-0001: Workload Identity Federation via SPIFFE/SPIRE over Static Cloud Tokens

**Status:** Accepted  
**Date:** 2026-06-18  
**Lead Architect:** William Free Hall (Free) <whall4.wh@gmail.com>

## 1. Context & Operational Challenge
Our multi-cloud Kubernetes deployment (AWS EKS `us-east-1` and GCP GKE `us-central1`) requires pods to securely communicate cross-cloud and access shared HashiCorp Vault secrets engines. Static Kubernetes ServiceAccount tokens are bound to a single cluster OIDC provider, leading to complex cloud IAM mapping tables and persistent secrets exfiltration risks.

## 2. Options Considered
* **Option A: Static Long-Lived Cloud IAM Credentials in K8s Secrets**
  - *Evaluation:* Simple initial rollout, but directly violates CIS Benchmark 5.1.2 and introduces high risk during lateral cluster traversal.
* **Option B: Dual-Cloud Native Workload Identity (AWS IRSA + GCP Workload Identity)**
  - *Evaluation:* Platform native, but creates a bifurcated identity model where services must know which cloud they are executing on; impossible to issue unified cryptographic identities for cross-cloud mTLS without mutual trust CA hierarchies.
* **Option C: Unified SPIFFE/SPIRE Workload Attestation with Short-Lived SVIDs**
  - *Evaluation:* Implements open standard (`spiffe://enterprise.net`), automatic 1-hour X.509 SVID rotations via SPIRE node agent UNIX domain sockets, and native Envoy/Istio secret discovery service (SDS) integration.

## 3. Decision & Trade-Off Accepted
We adopted **Option C (SPIFFE/SPIRE)**.  
**Trade-Off Accepted:** We accept the operational overhead of running high-availability SPIRE Server StatefulSets and hostPath UNIX socket DaemonSets across clusters to gain cryptographically verifiable, zero-trust cross-cloud service identities.
