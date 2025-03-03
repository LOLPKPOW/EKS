variable "region" {
  description = "AWS region"
  default     = "us-east-2"
}

variable "eks_cluster_name" {
  description = "EKS Project Cluster"
  default     = "eks-project-cluster"
}

# Use when specifying an existing VPC
#variable "vpc_id" {
#  description = "VPC ID"
#  type        = string
#}
