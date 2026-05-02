additional_ingress_cidrs        = ["10.50.0.0/16"] // management vpc cidr

# Terraform Redis

- Example 1
```
module "redis_cluster" {
  source                      = "github.com/wrasdf/terraform-redis?ref=v1.0.0"
  
  environment                 = "labs"
  elasticache_cluster_name    = "labs-elasticache-test-cluster"
  engine_version              = "7.0"
  replicas_per_node_group     = 0   // replica count per shard && Muti-AZ enabled if > 0
  node_type                   = "cache.t3.small"
  snapshot_retention_limit    = 2
  num_node_groups             = 1   // (shards)
}
```

- Example 2
```
module "redis_cluster" {
  source                      = "github.com/wrasdf/terraform-redis?ref=v1.0.0"
  
  environment                 = "labs"
  elasticache_cluster_name    = "labs-elasticache-test-cluster"
  engine_version              = "7.0"
  replicas_per_node_group     = 1
  node_type                   = "cache.t3.small"
  snapshot_retention_limit    = 2
  num_node_groups             = 2
  additional_ingress_cidrs    = ["10.50.0.0/16"] // management vpc cidr
  parameters = [
    { name = "notify-keyspace-events", value = "KA" }
  ]
  preferred_cache_cluster_azs = ["ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"]
 
  log_delivery_configuration = {
    slow-log = {
      destination_type = "cloudwatch-logs"
      log_format       = "json"
    }
    engine-log = {
      destination_type = "cloudwatch-logs"
      log_format       = "text"
    }
  }  

  tags = {
    Team = "Platform"
    Description = "Elasticache replication group for testing Elasticache module"
  }
}
```



### Notes
- `concat`
  - The concat() Function: concat() combines two or more lists into one single list.
  - eg: Concat: ["172.31.0.0/16", "8.8.8.8/32", "", "9.9.9.9/32"]

- `compact`
  - The compact() Function: This is the "safety filter." It looks at the final list and removes any empty strings ("").
  - eg: Compact: ["172.31.0.0/16", "8.8.8.8/32", "9.9.9.9/32"] (The empty string is gone!)

- `coalesce`
  - The coalesce() function takes a list of arguments and returns the first one that is not null and not an empty string.  
  - eg: coalesce(var.port, <result_of_conditional>)
