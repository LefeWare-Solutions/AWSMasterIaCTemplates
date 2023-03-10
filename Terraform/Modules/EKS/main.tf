terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.72"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 2.2"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.10"
    }
  }
  backend "s3" {
    bucket = "s3-terraformstate"
    key    = "global/kubernetes.state"
    region = "us-east-1"
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  region  = "us-east-1"
}


provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1alpha1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_id]
  }
}

data "aws_caller_identity" "current" {}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "18.21.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.22"

  vpc_id          = var.vpc_id
  subnet_ids      = var.private_subnets


  eks_managed_node_group_defaults = {
    ami_type       = "AL2_x86_64"
    instance_types = ["t2.small"]
  }

  eks_managed_node_groups = {
    default_node_group = {
      # By default, the module creates a launch template to ensure tags are propagated to instances, etc.,
      # so we need to disable it to use the default template provided by the AWS EKS managed node group service
      create_launch_template = false
      launch_template_name   = ""

      min_size     = 1
      max_size     = 3
      desired_size = 2

      disk_size = 50

      # Remote access cannot be specified with a launch template
      remote_access = {
        ec2_ssh_key               = "EKS-EC2-KeyPAi"
        source_security_group_ids = var.sg_id
      }
    }
  }

  tags = {
    service = "Global",
    project = "TrustedGateway"
    environment = var.environment_name
  }
}

