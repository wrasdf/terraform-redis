module "redis_cluster" {
  source = "../"
  # source                      = "github.com/wrasdf/terraform-redis?ref=v1.0.0"

  environment              = "labs"
  elasticache_cluster_name = "labs-elasticache-test-cluster"
  engine_version           = "7.0"
  replicas_per_node_group  = 0 // replica count per shard && Muti-AZ enabled if > 0
  node_type                = "cache.t3.small"
  snapshot_retention_limit = 2
  num_node_groups          = 1 // (shards) cluster count, must be >= 2 if replicas_per_node_group > 0

}
