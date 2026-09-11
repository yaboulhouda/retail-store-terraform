resource "aws_security_group" "rds-postgres-sg" {
  name_prefix = "retail-store-rds-${var.environment_name}-"
  vpc_id      = module.vpc.vpc_id
  ingress {
    from_port       = 5432
    to_port         = 5432
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

resource "aws_security_group" "rds-mariadb-sg" {
  name_prefix = "retail-store-rds-${var.environment_name}-"
  vpc_id      = module.vpc.vpc_id
  ingress {
    from_port       = 3306
    to_port         = 3306
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


module "orders-postgres" {
  source                 = "./modules/rds"
  db_name                = "orders"
  username               = "postgres"
  engine                 = "postgres"
  engine_version         = "16.15"
  port                   = 5432
  parameter_group_name   = "default.postgres16"
  db_subnet_group_name   = module.vpc.database_subnet_group_name
  vpc_security_group_ids = [aws_security_group.rds-postgres-sg.id]
  instance_class         = "db.t4g.micro"
  identifier             = "orders-postgres-${var.environment_name}"
}

module "catalog-mysql" {
  source                 = "./modules/rds"
  db_name                = "catalogdb"
  username               = "catalog_user"
  engine                 = "mariadb"
  engine_version         = "10.11.19"
  port                   = 3306
  parameter_group_name   = "default.mariadb10.11"
  db_subnet_group_name   = module.vpc.database_subnet_group_name
  vpc_security_group_ids = [aws_security_group.rds-mariadb-sg.id]
  instance_class         = "db.t4g.micro"
  identifier             = "catalog-mysql-${var.environment_name}"
}
