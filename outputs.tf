output "elasticache_cluster_address" {
  description = "The address of the Elasticache cluster"
  value       = aws_elasticache_replication_group.this[0].primary_endpoint_address
}

output "elasticache_cluster-subnet-group-name" {
  description = "The name of the Elasticache subnet group"
  value = aws_elasticache_subnet_group.this[0].name
}

output "elasticache_cluster-security-group-id" {
  description = "The ID of the Elasticache security group"
  value = aws_security_group.this[0].id
}