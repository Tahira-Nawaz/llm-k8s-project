output "public_subnet_ids" {
  description = "List of public subnet IDs."
  value       = aws_subnet.public[*].id
}

output "public_subnet_name" {
  description = "CIDRs of public subnets"
  value       = aws_subnet.public[*].tags["Name"]
}