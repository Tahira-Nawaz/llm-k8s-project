# =============================================================================
# Root Main – Orchestrates all modules
# =============================================================================


module "subnets" {
  aws_internet_gateway = var.aws_internet_gateway_id
  source              = "./modules/subnet"
  cluster_name        = var.cluster_name
  environment         = var.environment
  vpc_id              = var.vpc_id
  project_name        = var.project_name
  public_subnet_cidrs = var.public_subnet_cidrs
  availability_zones  = var.availability_zones
}
# -----------------------------------------------------------------------------
# S3 - Artifact bucket only (state bucket created manually)
# -----------------------------------------------------------------------------
module "s3" {
  source = "./modules/s3"

  artifact_bucket_name = var.artifact_bucket_name
  project_name         = var.project_name
  environment          = var.environment
}

# -----------------------------------------------------------------------------
# IAM – Instance roles and profiles for EC2 nodes
# -----------------------------------------------------------------------------
module "iam" {
  source              = "./modules/iam"
  project_name        = var.project_name
  environment         = var.environment
  artifact_bucket_arn = module.s3.artifact_bucket_arn
  zone_id             = var.zone_id
}

# -----------------------------------------------------------------------------
# Security Groups – Access rules for master and worker nodes
# -----------------------------------------------------------------------------
module "security_groups" {
  source = "./modules/security_group"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = var.vpc_id
}

# -----------------------------------------------------------------------------
# Route 53 – DNS management
# -----------------------------------------------------------------------------
module "route53" {
  source       = "./modules/route53"
  domain_name  = var.domain_name_prefix
  zone_id      = var.zone_id
  project_name = var.project_name
  environment  = var.environment
  # ingress_record_name = var.ingress_record_name
  ingress_lb_hostname = var.ingress_lb_hostname
}

