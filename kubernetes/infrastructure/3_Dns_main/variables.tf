# =============================================================================
# General Configuration
# =============================================================================
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (used for tagging only)"
  type        = string
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
}


# =============================================================================
# Route53 / DNS Configuration
# =============================================================================
variable "domain_name_prefix" {
  description = "Domain name for Route53"
  type        = string
}

variable "zone_id" {
  description = "Existing Route53 Hosted Zone ID (if not creating)"
  type        = string
}


variable "ingress_lb_hostname" {
  description = "Load balancer hostname for ingress"
  type        = string
}