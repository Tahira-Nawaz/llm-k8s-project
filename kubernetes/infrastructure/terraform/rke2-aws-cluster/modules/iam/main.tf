# =============================================================================
# IAM Module – EC2 Node Role, Policy, Instance Profile
# =============================================================================

# ---- Trust Policy ----
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# ---- Node IAM Role ----
resource "aws_iam_role" "node" {
  name               = "${var.project_name}-${var.environment}-node-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
  description        = "IAM role for K8s cluster EC2 nodes"
}

# ---- Inline Policy – Node Permissions ----
data "aws_iam_policy_document" "node_permissions" {
  # EC2 metadata & describe (required by cloud-provider and RKE2)
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeAccountAttributes",
      "ec2:DescribeAddresses",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceTopology",
      "ec2:DescribeInternetGateways",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeRegions",
      "ec2:DescribeRouteTables",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeTags",
      "ec2:DescribeVolumes",
      "ec2:DescribeVolumesModifications",
      "ec2:DescribeVpcs",

      "ec2:ModifyInstanceAttribute",
      "ec2:ModifyNetworkInterfaceAttribute",
      "ec2:ModifyVolume",

      "ec2:CreateRoute",
      "ec2:DeleteRoute",

      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:CreateSecurityGroup",
      "ec2:DeleteSecurityGroup",
      "ec2:RevokeSecurityGroupIngress",

      "ec2:CreateTags",
      "ec2:DeleteTags",

      "ec2:AttachVolume",
      "ec2:CreateVolume",
      "ec2:DeleteVolume",
      "ec2:DetachVolume",
    ]
    resources = ["*"]
  }

  # ELB / NLB / ALB permissions
  statement {
    effect = "Allow"
    actions = [
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:ApplySecurityGroupsToLoadBalancer",
      "elasticloadbalancing:AttachLoadBalancerToSubnets",
      "elasticloadbalancing:ConfigureHealthCheck",
      "elasticloadbalancing:CreateListener",
      "elasticloadbalancing:CreateLoadBalancer",
      "elasticloadbalancing:CreateLoadBalancerListeners",
      "elasticloadbalancing:CreateTargetGroup",
      "elasticloadbalancing:DeleteListener",
      "elasticloadbalancing:DeleteLoadBalancer",
      "elasticloadbalancing:DeleteLoadBalancerListeners",
      "elasticloadbalancing:DeleteTargetGroup",
      "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
      "elasticloadbalancing:DeregisterTargets",
      "elasticloadbalancing:DescribeInstanceHealth",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeLoadBalancerAttributes",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeTags",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeTargetHealth",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:ModifyLoadBalancerAttributes",
      "elasticloadbalancing:ModifyTargetGroup",
      "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:SetLoadBalancerPoliciesForBackendServer",
      "elasticloadbalancing:SetLoadBalancerPoliciesOfListener",

      "elasticloadbalancing:RemoveTags",
      "elasticloadbalancing:DescribeListenerCertificates",
      "elasticloadbalancing:DescribeRules",
      "elasticloadbalancing:DescribeTargetGroupAttributes",
      "elasticloadbalancing:ModifyTargetGroupAttributes",
      "elasticloadbalancing:ModifyRule",
      "elasticloadbalancing:SetIpAddressType",
      "elasticloadbalancing:SetSecurityGroups",
      "elasticloadbalancing:SetSubnets",
      "elasticloadbalancing:CreateRule",
      "elasticloadbalancing:DeleteRule",
      "elasticloadbalancing:DescribeListenerAttributes",
    ]
    resources = ["*"]
  }

  # Autoscaling describe
  statement {
    effect = "Allow"
    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
    ]
    resources = ["*"]
  }

  # ECR for private image pulling
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
    ]
    resources = ["*"]
  }

  # IAM service linked role creation
  statement {
    effect = "Allow"
    actions = [
      "iam:CreateServiceLinkedRole",
    ]
    resources = ["*"]
  }

  # S3 – cluster artifacts
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
    resources = [var.artifact_bucket_arn, "${var.artifact_bucket_arn}/*"]
  }

  # SSM Session Manager
  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:PutParameter",
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel",
      "ec2messages:AcknowledgeMessage",
      "ec2messages:DeleteMessage",
      "ec2messages:FailMessage",
      "ec2messages:GetEndpoint",
      "ec2messages:GetMessages",
      "ec2messages:SendReply",
    ]
    resources = ["*"]
  }

  #Route53 support for TXT-only changes (useful for cert-manager DNS01)
  dynamic "statement" {
    for_each = var.zone_id != null && var.zone_id != "" ? [1] : []

    content {
      effect = "Allow"
      actions = [
        "route53:GetChange",
      ]
      resources = ["arn:aws:route53:::change/*"]
    }
  }

  dynamic "statement" {
    for_each = var.zone_id != null && var.zone_id != "" ? [1] : []

    content {
      effect = "Allow"
      actions = [
        "route53:ChangeResourceRecordSets",
        "route53:ListResourceRecordSets",
      ]
      resources = ["arn:aws:route53:::hostedzone/${var.zone_id}"]

      condition {
        test     = "ForAllValues:StringEquals"
        variable = "route53:ChangeResourceRecordSetsRecordTypes"
        values   = ["TXT"]
      }
    }
  }
}

resource "aws_iam_role_policy" "node" {
  name   = "${var.project_name}-${var.environment}-node-policy"
  role   = aws_iam_role.node.id
  policy = data.aws_iam_policy_document.node_permissions.json
}

# ---- Instance Profile ----
resource "aws_iam_instance_profile" "node" {
  name = "${var.project_name}-${var.environment}-node-profile"
  role = aws_iam_role.node.name

  tags = {
    Name = "${var.project_name}-${var.environment}-node-profile"
  }
}