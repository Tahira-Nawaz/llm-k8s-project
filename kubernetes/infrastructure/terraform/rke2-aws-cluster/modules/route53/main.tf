
# -----------------------------------------------------------------------------
# DNS Record (Ingress / ALB)
# -----------------------------------------------------------------------------
resource "aws_route53_record" "ingress" {
   zone_id = var.zone_id 
  name    = var.domain_name
  type    = "CNAME"
  ttl     = 300
  records = [var.ingress_lb_hostname]
}