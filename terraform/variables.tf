# ============================================================================
# Terraform Variables Specification
# ============================================================================

variable "project_name" {
  type        = string
  description = "Project and resource prefix"
  default     = "enterprise-zero-trust"
}

variable "environment" {
  type        = string
  description = "Deployment environment (dev, staging, prod)"
  default     = "prod"
}

variable "aws_region" {
  type        = string
  description = "Primary AWS region"
  default     = "us-east-1"
}

variable "aws_vpc_cidr" {
  type        = string
  description = "VPC IP range CIDR"
  default     = "10.100.0.0/16"
}

variable "gcp_project_id" {
  type        = string
  description = "GCP Project Identifier"
  default     = "enterprise-cloud-defense"
}

variable "gcp_region" {
  type        = string
  description = "Primary GCP Region"
  default     = "us-central1"
}

variable "kubernetes_version" {
  type        = string
  description = "Target Kubernetes cluster version across EKS and GKE"
  default     = "1.29"
}
