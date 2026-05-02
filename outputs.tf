output "elasticache_cluster_endpoint" {
  value = coalesce(
    aws_elasticache_replication_group.this[0].configuration_endpoint_address,
    aws_elasticache_replication_group.this[0].primary_endpoint_address
  )
  description = "Configuration (cluster-mode enabled) or primary (cluster-mode disabled) endpoint of the cluster instance"
}

output "elasticache_cluster-subnet-group-name" {
  description = "The name of the Elasticache subnet group"
  value       = aws_elasticache_subnet_group.this[0].name
}

output "elasticache_cluster-security-group-id" {
  description = "The ID of the Elasticache security group"
  value       = aws_security_group.this[0].id
}
