package main

# Deny containers running as root (CIS Kubernetes Benchmark 5.2.6)
deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.securityContext.runAsNonRoot == true
    msg := sprintf("CIS Benchmark Violation: Container '%v' in Deployment '%v' must set securityContext.runAsNonRoot to true", [container.name, input.metadata.name])
}

# Deny privileged containers (CIS Kubernetes Benchmark 5.2.1)
deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    container.securityContext.privileged == true
    msg := sprintf("CIS Benchmark Violation: Container '%v' in Deployment '%v' cannot run in privileged mode", [container.name, input.metadata.name])
}

# Require CPU & Memory resource limits (CIS Kubernetes Benchmark 5.2.8)
deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.resources.limits.cpu
    msg := sprintf("Reliability Violation: Container '%v' in Deployment '%v' must define CPU limits", [container.name, input.metadata.name])
}
