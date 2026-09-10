resource "aws_db_instance" "rds" {
  allocated_storage           = var.allocated_storage
  db_name                     = var.db_name
  engine                      = var.engine
  engine_version              = var.engine_version
  port                        = var.port
  instance_class              = var.instance_class
  username                    = var.username
  manage_master_user_password = true
  parameter_group_name        = var.parameter_group_name
  skip_final_snapshot         = true
  deletion_protection         = false
  vpc_security_group_ids      = var.vpc_security_group_ids
  db_subnet_group_name        = var.db_subnet_group_name
  multi_az                    = false
  storage_encrypted           = true
  identifier                  = var.identifier
}
