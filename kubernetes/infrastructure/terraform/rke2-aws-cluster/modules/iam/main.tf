# =============================================================================
# IAM Module - EC2 Node Role for Rancher / RKE2 Cluster
# =============================================================================

# -------------------------------------------------------------------
# Trust Policy (EC2 can assume this role)
# -------------------------------------------------------------------
resource "aws_iam_role" "node" {
  name = "${var.project_name}-${var.environment}-node-profile"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-node-profile"
    Project     = var.project_name
    Environment = var.environment
  }
}

# -------------------------------------------------------------------
# AWS Managed Policies List
# -------------------------------------------------------------------
locals {
  managed_policies = [
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy",
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AutoScalingFullAccess",
    "arn:aws:iam::aws:policy/AWSCloudFormationFullAccess",
    "arn:aws:iam::aws:policy/AWSKeyManagementServicePowerUser",
    "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess",
    "arn:aws:iam::aws:policy/IAMFullAccess"
  ]
}

# -------------------------------------------------------------------
# Attach Policies to IAM Role
# -------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "node_policies" {
  for_each = toset(local.managed_policies)

  role       = aws_iam_role.node.name
  policy_arn = each.value
}

# -------------------------------------------------------------------
# Instance Profile (required for EC2 instances)
# -------------------------------------------------------------------
resource "aws_iam_instance_profile" "node" {
  name = "${var.project_name}-${var.environment}-node-profile"
  role = aws_iam_role.node.name

  tags = {
    Name        = "${var.project_name}-${var.environment}-node-profile"
    Project     = var.project_name
    Environment = var.environment
  }
}