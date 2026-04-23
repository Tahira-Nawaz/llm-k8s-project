# =============================================================================
# Root Outputs - Resource Names
# =============================================================================

# -----------------------------------------------------------------------------
# S3
# -----------------------------------------------------------------------------
output "artifact_bucket_name" {
  description = "S3 bucket name used for Terraform artifacts"
  value       = module.s3.artifact_bucket_name
}

# -----------------------------------------------------------------------------
# IAM
# -----------------------------------------------------------------------------
output "node_iam_role_name" {
  description = "IAM role name for cluster nodes"
  value       = module.iam.role_name
}

# -----------------------------------------------------------------------------
# Subnets
# -----------------------------------------------------------------------------
# output "public_subnet_ids" {
#   description = "Names of public subnets"
#   value       = module.subnets.public_subnet_ids
# }

output "public_subnet_name" {
  description = "CIDRs of public subnets"
  value       = module.subnets.public_subnet_name
}

# -----------------------------------------------------------------------------
# Security Groups
# -----------------------------------------------------------------------------
output "rancher_node_sg_name" {
  description = "Security Group name for Rancher nodes"
  value       = module.security_groups.security_group_name
}

# -----------------------------------------------------------------------------
# Route53
# -----------------------------------------------------------------------------

output "route53_record_fqdn" {
  description = "Route53 domain used for the project"
  value       = module.route53.record_fqdn
}
