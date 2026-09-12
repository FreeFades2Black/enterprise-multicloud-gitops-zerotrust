# ADR-0003: Hub-and-Spoke ArgoCD Federation vs Per-Cluster Standalone GitOps Controllers

**Status:** Accepted
**Date:** 2026-07-15
**Lead Architect:** William Free Hall (Free) <whall4.wh@gmail.com>

## Context & Problem Statement
Deploying microservices and baseline platform tooling across multiple Kubernetes clusters in AWS and GCP requires a GitOps synchronization strategy. We evaluated whether to maintain a dedicated ArgoCD control plane in every spoke cluster or deploy a centralized hub ArgoCD instance managing remote target clusters.

## Options Considered
1. **Option A: Decentralized Autonomous ArgoCD in Each Spoke Cluster**
   - *Pros:* Cluster autonomy; network partitions between clouds do not impact local GitOps reconciliation.
   - *Cons:* Management sprawl; fragmented audit trails; requires duplicating Git credentials, RBAC policies, and notification hooks across 5+ clusters.
2. **Option B: Hub-and-Spoke Centralized ArgoCD Control Plane**
   - *Pros:* Single pane of glass for all multi-cloud deployments; centralized RBAC and SSO integration; unified sync wave orchestration and compliance telemetry.
   - *Cons:* Requires cross-cloud Kubernetes API server connectivity; central cluster failure delays syncs across all regions.

## Decision & Trade-Off Accepted
We adopted **Option B: Hub-and-Spoke Centralized ArgoCD Control Plane** hosted in a dedicated management cluster. We mitigate cross-cloud API exposure by utilizing AWS DirectConnect / GCP Cloud Interconnect with private endpoint IP restrictions and mutual TLS tunnels.
