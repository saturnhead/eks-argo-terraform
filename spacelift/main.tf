provider "spacelift" {}

terraform {
  required_providers {
    spacelift = {
      source = "spacelift-io/spacelift"
    }
  }
}


resource "spacelift_stack" "k8s-cluster" {
  branch            = "main"
  description       = "Provisions a Kubernetes cluster"
  name              = "Terraform Kubernetes Cluster"
  project_root      = "terraform"
  repository        = "eks-argo-terraform"
  terraform_version = "1.5.7"

  labels = ["terraform-argocd"]
}

resource "spacelift_stack" "argocd" {
  kubernetes {
    namespace = "default"
  }
  branch       = "main"
  description  = "Deploys an ArgoCD application"
  name         = "ArgoCD application"
  project_root = "argocd/config"
  repository   = "eks-argo-terraform"
  labels       = ["terraform-argocd"]
  before_init  = ["$AWS_LOGIN"]
}

resource "spacelift_aws_integration_attachment" "k8s-cluster" {
  integration_id = var.integration_id
  stack_id       = spacelift_stack.k8s-cluster.id
  read           = true
  write          = true
}

resource "spacelift_aws_integration_attachment" "argocd" {
  integration_id = var.integration_id
  stack_id       = spacelift_stack.k8s-cluster.id
  read           = true
  write          = true
}

resource "spacelift_stack_dependency" "cluster-argo" {
  stack_id            = spacelift_stack.argocd.id
  depends_on_stack_id = spacelift_stack.k8s-cluster.id
}

resource "spacelift_stack_dependency_reference" "output" {
  stack_dependency_id = spacelift_stack_dependency.cluster-argo.id
  output_name         = "eks_connect"
  input_name          = "AWS_LOGIN"
}
