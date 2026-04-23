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
# VPC / Networking Configuration
# =============================================================================
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
}

variable "availability_zones" {
  description = "Availability zones for subnets"
  type        = list(string)
}

variable "vpc_id" {
  description = "Existing VPC ID"
  type        = string
}

# =============================================================================
# Security Configuration
# =============================================================================
variable "admin_ssh_cidr" {
  description = "CIDR block allowed to SSH into instances"
  type        = string
}

# =============================================================================
# S3 Configuration
# =============================================================================
variable "artifact_bucket_name" {
  description = "S3 bucket name for storing artifacts"
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

# variable "ingress_record_name" {
#   description = "DNS record name for ingress"
#   type        = string
# }

variable "ingress_lb_hostname" {
  description = "Load balancer hostname for ingress"
  type        = string
}
variable "cluster_name" {
  description = "Load balancer hostname for ingress"
  type        = string
}