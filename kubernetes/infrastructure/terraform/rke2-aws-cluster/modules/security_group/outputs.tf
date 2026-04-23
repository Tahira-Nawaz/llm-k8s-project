output "security_group_id" {
  description = "ID of the created security group"
  value       = aws_security_group.rke2_sg.id
}
output "security_group_name" {
  description = "ID of the created security group"
  value       = aws_security_group.rke2_sg.name
}