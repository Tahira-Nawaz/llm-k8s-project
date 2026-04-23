variable "vpc_id" {
  description = "Existing VPC ID"
  type        = string
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "List of public subnet CIDRs"
  type        = list(string)
}

variable "availability_zones" {
  description = "List of AZs"
  type        = list(string)
}