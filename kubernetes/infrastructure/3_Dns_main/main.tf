# -----------------------------------------------------------------------------
# Route 53 – DNS management
# -----------------------------------------------------------------------------
module "route53" {
  source       = "../1_Core_Infra_Modules/route53"
  domain_name  = var.domain_name_prefix
  zone_id      = var.zone_id
  project_name = var.project_name
  environment  = var.environment
  # ingress_record_name = var.ingress_record_name
  ingress_lb_hostname = var.ingress_lb_hostname
}

