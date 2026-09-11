resource "aws_security_group" "valkey-sg" {
  name_prefix = "retail-store-valkey-"
  vpc_id      = module.vpc.vpc_id
  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_elasticache_subnet_group" "valkey" {
  name       = "retail-store-valkey-subnets"
  subnet_ids = module.vpc.database_subnets
}

resource "aws_elasticache_replication_group" "checkout" {
  replication_group_id = "checkout-valkey-${var.environment_name}"
  description          = "Valkey cache for checkout"

  engine               = "valkey"
  engine_version       = "8.1"
  node_type            = "cache.t4g.micro"
  parameter_group_name = "default.valkey8"
  port                 = 6379

  num_cache_clusters = 1

  subnet_group_name  = aws_elasticache_subnet_group.valkey.name
  security_group_ids = [aws_security_group.valkey-sg.id]
}
