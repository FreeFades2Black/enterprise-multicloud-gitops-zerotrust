# Incident Post-Mortem: OPA Admission Webhook Exhaustion During Node Surge

**Incident Date:** 2026-06-14  
**Impact Duration:** 22 minutes (14:02 - 14:24 UTC)  
**Severity:** SEV-2  
**Root Cause:** Gatekeeper admission webhook specified `failurePolicy: Fail` with a 2-second timeout. During a cluster autoscaler surge adding 8 worker nodes, a single un-evacuated Gatekeeper pod hit 100% CPU quota, resulting in API server webhook timeout errors and pod scheduling freeze.

## Timeline
* **14:02 UTC:** Node autoscaler triggered by batch workload surge (+8 nodes).
* **14:05 UTC:** Gatekeeper replica restarted due to node drain; surviving replica saturated at 100% CPU.
* **14:08 UTC:** API server rejects all pod creation with `webhook timeout: validation.gatekeeper.sh`.
* **14:15 UTC:** On-call engineer paged via PagerDuty. Identified webhook client timeouts in kube-apiserver logs.
* **14:22 UTC:** Hotfix applied: tuned webhook timeout to 5s and scaled Gatekeeper deployment to 3 replicas with inter-pod anti-affinity.
* **14:24 UTC:** All pending pods scheduled; cluster nominal.

## Action Items & Preventative Architecture
1. Scaled Gatekeeper deployment to 3 replicas across separate Availability Zones (`topologySpreadConstraints`).
2. Increased admission webhook timeout from 2s to 5s to absorb node autoscaler bursts.
3. Added Prometheus alert `GatekeeperWebhookLatencyHigh` triggering when p99 webhook latency exceeds 1.5s.
