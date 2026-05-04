# -----------------------------------------------------------------------------
# Route53
# -----------------------------------------------------------------------------

output "route53_record_fqdn" {
  description = "Route53 domain used for the project"
  value       = module.route53.record_fqdn
}
