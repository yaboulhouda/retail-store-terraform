data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  cluster_full_name = "${var.cluster_name}-${var.environment_name}"
  azs               = slice(data.aws_availability_zones.available.names, 0, 2)
  public_subnets    = [for s, az in local.azs : cidrsubnet(var.vpc_cidr, var.subnet_newbits, s)]
  database_subnets  = [for s, az in local.azs : cidrsubnet(var.vpc_cidr, var.subnet_newbits, s + 5)]
  private_subnets   = [for s, az in local.azs : cidrsubnet(var.vpc_cidr, var.subnet_newbits, s + 10)]
}
