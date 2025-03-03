# Create VPC First
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0"

  name = "eks-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-2a", "us-east-2b", "us-east-2c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
}

# Create IAM Role for EKS Cluster
resource "aws_iam_role" "eks_cluster_role" {
  name               = "eks-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
    }]
  })
}
# Define IAM Role for EKS Cluster
resource "aws_iam_role_policy" "eks_cluster_policy" {
  name   = "eks-cluster-policy"
  role   = aws_iam_role.eks_cluster_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}


# IAM Policy for EKS Cluster Role
resource "aws_iam_role_policy" "eks_cluster_policy" {
  name   = "eks-cluster-policy"
  role   = aws_iam_role.eks_cluster_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = ["logs:CreateLogGroup"]
      Effect   = "Deny"
      Resource = "*"
    }]
  })
}


# Then Create EKS Cluster, Referencing the VPC
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "19.21.0"
    # Cluster name and version
  cluster_name    = var.eks_cluster_name
  cluster_version = "1.32"
    # Specify VPC and Subnets
  vpc_id          = module.vpc.vpc_id              
  subnet_ids      = module.vpc.private_subnets     
    # Allow public access to cluser and specify role
  cluster_endpoint_public_access = true
  iam_role_arn = aws_iam_role.eks_cluster_role.arn

  eks_managed_node_groups = {
    eks_nodes = {
      min_size     = 1
      max_size     = 2
      desired_size = 1
      instance_types = ["t3.small"]  # Used small for cost savings
      capacity_type  = "SPOT"        # Used spot instances for cost savings
    }
  }
}
