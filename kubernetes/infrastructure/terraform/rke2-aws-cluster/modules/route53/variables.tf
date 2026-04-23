variable "domain_name" {
  description = "Domain name for Route53 hosted zone"
  type        = string
}

variable "zone_id" {
  description = "Existing hosted zone ID (used if create_zone = false)"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

# variable "record_name" {
#   description = "DNS record name (can be wildcard)"
#   type        = string
# }

variable "ingress_lb_hostname" {
  description = "Load balancer DNS name"
  type        = string
}