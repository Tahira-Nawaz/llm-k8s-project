# =============================================================================
# General Configuration
# =============================================================================
aws_region   = "us-east-2"
project_name = "llm-k8s"
environment  = "dev"
owner        = "ai-team"

# =============================================================================
# VPC / Networking Configuration
# =============================================================================
vpc_cidr = "10.0.0.0/16"
vpc_id   = "vpc-0bd263ec43ecb3acf"
public_subnet_cidrs = [
  "10.0.1.0/24",
  "10.0.2.0/24"
]
availability_zones = [
  "us-east-2a",
  "us-east-2b"
]

# =============================================================================
# Security Configuration
# =============================================================================
admin_ssh_cidr = "0.0.0.0/0" # restrict in production

# =============================================================================
# S3 Configuration
# =============================================================================
artifact_bucket_name = "llm-k8s-artifacts"

# =============================================================================
# Route53 / DNS Configuration
# =============================================================================
domain_name_prefix = "llm-k8s"
zone_id            = "Z02745981J3FQC8Y0Z4P7"

# ingress_record_name = "*.llm-k8s.awssolutionsprovider.com"
ingress_lb_hostname = "k8s-test-traefik-dd67347f98-bc4cb8c2aae783c5.elb.us-east-2.amazonaws.com"