output "vpc_id" {
  value       = aws_vpc.main.id
  description = "ID of the VPC"
}

output "vpc_cidr_block" {
  value       = aws_vpc.main.cidr_block
  description = "CIDR block of the VPC"
}

output "public_subnet_ids" {
  value       = aws_subnet.public[*].id
  description = "IDs of the public subnets"
}

output "private_subnet_ids" {
  value       = aws_subnet.private[*].id
  description = "IDs of the private subnets"
}

output "database_subnet_ids" {
  value       = aws_subnet.database[*].id
  description = "IDs of the database subnets"
}

output "database_subnet_group_name" {
  value       = aws_db_subnet_group.main.name
  description = "Name of the database subnet group"
}

output "internet_gateway_id" {
  value       = aws_internet_gateway.main.id
  description = "ID of the Internet Gateway"
}

output "nat_gateway_ids" {
  value       = aws_nat_gateway.main[*].id
  description = "IDs of the NAT Gateways"
}

