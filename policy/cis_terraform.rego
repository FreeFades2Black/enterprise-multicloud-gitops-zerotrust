package main

# Deny AWS Security Groups with open ingress on port 22 or 3389 from 0.0.0.0/0 (CIS AWS 4.1, 4.2)
deny[msg] {
    resource := input.resource.aws_security_group[_]
    rule := resource.ingress[_]
    rule.cidr_blocks[_] == "0.0.0.0/0"
    rule.from_port <= 22
    rule.to_port >= 22
    msg := sprintf("CIS Benchmark Violation: Security Group '%v' allows unrestricted SSH (port 22) ingress from 0.0.0.0/0", [resource])
}

# Require S3 Bucket Server-Side Encryption (CIS AWS 2.1.1)
deny[msg] {
    bucket := input.resource.aws_s3_bucket[_]
    not input.resource.aws_s3_bucket_server_side_encryption_configuration
    msg := sprintf("CIS Benchmark Violation: S3 Bucket '%v' must have server-side encryption enabled", [bucket])
}
