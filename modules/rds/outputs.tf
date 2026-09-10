output "secret_arn" {
  value = aws_db_instance.rds.master_user_secret[0].secret_arn
}

output "address" {
  value = aws_db_instance.rds.address
}

output "port" {
  value = aws_db_instance.rds.port
}

output "username" {
  value = aws_db_instance.rds.username
}


output "db_name" {
  value = aws_db_instance.rds.db_name
}
