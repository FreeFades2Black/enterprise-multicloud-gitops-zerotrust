import os
import yaml
import pytest

def test_rego_policies_structure():
    k8s_policy = "policy/cis_kubernetes.rego"
    tf_policy = "policy/cis_terraform.rego"
    assert os.path.exists(k8s_policy), f"{k8s_policy} must exist"
    assert os.path.exists(tf_policy), f"{tf_policy} must exist"

    with open(k8s_policy, "r", encoding="utf-8") as f:
        k8s_content = f.read()
    assert "package main" in k8s_content
    assert "runAsNonRoot" in k8s_content
    assert "privileged" in k8s_content

    with open(tf_policy, "r", encoding="utf-8") as f:
        tf_content = f.read()
    assert "package main" in tf_content
    assert "aws_security_group" in tf_content

def test_helm_chart_and_values():
    chart_file = "helm/enterprise-app/Chart.yaml"
    values_file = "helm/enterprise-app/values.yaml"
    assert os.path.exists(chart_file)
    assert os.path.exists(values_file)

    with open(chart_file, "r", encoding="utf-8") as f:
        chart_data = yaml.safe_load(f)
    assert chart_data["name"] == "enterprise-app"
    assert "version" in chart_data

    with open(values_file, "r", encoding="utf-8") as f:
        values_data = yaml.safe_load(f)
    assert "securityContext" in values_data
    assert values_data["securityContext"]["runAsNonRoot"] is True

def test_argocd_manifest():
    argocd_app = "argocd/application.yaml"
    assert os.path.exists(argocd_app)
    with open(argocd_app, "r", encoding="utf-8") as f:
        app_data = yaml.safe_load(f)
    assert app_data["kind"] == "Application"
    assert app_data["spec"]["destination"]["namespace"] == "production-workloads"

def test_terraform_structure():
    main_tf = "terraform/main.tf"
    vars_tf = "terraform/variables.tf"
    assert os.path.exists(main_tf)
    assert os.path.exists(vars_tf)
    with open(main_tf, "r", encoding="utf-8") as f:
        content = f.read()
    assert "hashicorp/aws" in content
    assert "hashicorp/vault" in content
