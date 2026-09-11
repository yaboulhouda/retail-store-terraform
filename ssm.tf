resource "aws_ssm_parameter" "orders-host" {
  name  = "/retail-store/${var.environment_name}/orders/host"
  type  = "String"
  value = module.orders-postgres.address
}

resource "aws_ssm_parameter" "orders-port" {
  name  = "/retail-store/${var.environment_name}/orders/port"
  type  = "String"
  value = module.orders-postgres.port
}

resource "aws_ssm_parameter" "orders-username" {
  name  = "/retail-store/${var.environment_name}/orders/username"
  type  = "String"
  value = module.orders-postgres.username
}

resource "aws_ssm_parameter" "orders-dbname" {
  name  = "/retail-store/${var.environment_name}/orders/dbname"
  type  = "String"
  value = module.orders-postgres.db_name
}

resource "aws_ssm_parameter" "catalog-host" {
  name  = "/retail-store/${var.environment_name}/catalog/host"
  type  = "String"
  value = module.catalog-mysql.address
}

resource "aws_ssm_parameter" "catalog-port" {
  name  = "/retail-store/${var.environment_name}/catalog/port"
  type  = "String"
  value = module.catalog-mysql.port
}

resource "aws_ssm_parameter" "catalog-username" {
  name  = "/retail-store/${var.environment_name}/catalog/username"
  type  = "String"
  value = module.catalog-mysql.username
}

resource "aws_ssm_parameter" "catalog-dbname" {
  name  = "/retail-store/${var.environment_name}/catalog/dbname"
  type  = "String"
  value = module.catalog-mysql.db_name
}

resource "aws_ssm_parameter" "redis-url" {
  name  = "/retail-store/${var.environment_name}/checkout/redis-url"
  type  = "String"
  value = "redis://${aws_elasticache_replication_group.checkout.primary_endpoint_address}:${aws_elasticache_replication_group.checkout.port}"
}
