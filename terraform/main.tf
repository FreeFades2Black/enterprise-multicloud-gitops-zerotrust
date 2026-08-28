# ============================================================================
# Enterprise Multi-Cloud GitOps & Zero-Trust Infrastructure Engine
# Lead Architect: William Free Hall (Free) <whall4.wh@gmail.com>
# ============================================================================

terraform {
  required_version = ">= 1.8.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.50"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 5.30"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.2"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
  }

  backend "s3" {
    bucket         = "enterprise-tf-state-prod-01"
    key            = "multicloud/gitops/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "enterprise-tf-locks"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Architect   = "William Free Hall (Free)"
      Compliance  = "CIS-Benchmark-Strict"
    }
  }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

# ----------------------------------------------------------------------------
# 1. AWS EKS Kubernetes Cluster Module
# ----------------------------------------------------------------------------
module "aws_eks" {
  source = "./modules/aws_eks"

  cluster_name    = "${var.project_name}-eks-${var.environment}"
  cluster_version = var.kubernetes_version
  vpc_cidr        = var.aws_vpc_cidr
  environment     = var.environment
}

# ----------------------------------------------------------------------------
# 2. GCP GKE Kubernetes Cluster Module
# ----------------------------------------------------------------------------
module "gcp_gke" {
  source = "./modules/gcp_gke"

  cluster_name       = "${var.project_name}-gke-${var.environment}"
  kubernetes_version = var.kubernetes_version
  gcp_project_id     = var.gcp_project_id
  gcp_region         = var.gcp_region
  environment        = var.environment
}

# ----------------------------------------------------------------------------
# 3. HashiCorp Vault Zero-Trust Secret Engine
# ----------------------------------------------------------------------------
module "vault" {
  source = "./modules/vault"

  environment = var.environment
  eks_oidc_issuer = module.aws_eks.cluster_oidc_issuer_url
  gke_workload_pool = module.gcp_gke.workload_identity_pool
}
