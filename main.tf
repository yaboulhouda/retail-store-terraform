module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.7"

  name = "retail-store-vpc-${var.environment_name}"
  cidr = var.vpc_cidr

  azs                          = local.azs
  public_subnets               = local.public_subnets
  private_subnets              = local.private_subnets
  database_subnets             = local.database_subnets
  create_database_subnet_group = true

  enable_nat_gateway = true
  single_nat_gateway = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = {
    "kubernetes.io/role/elb"                           = "1"
    "kubernetes.io/cluster/${local.cluster_full_name}" = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"                  = "1"
    "kubernetes.io/cluster/${local.cluster_full_name}" = "shared"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = local.cluster_full_name
  kubernetes_version = "1.35"

  addons = {
    coredns = {}
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
    }
  }

  # Optional
  endpoint_public_access = true
  compute_config = {
    enabled = false
  }

  # Optional: Adds the current caller identity as an administrator via cluster access entry
  enable_cluster_creator_admin_permissions = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  # EKS Managed Node Group(s)
  eks_managed_node_groups = {
    nodes = {
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["t3.micro"]

      min_size     = 2
      max_size     = 3
      desired_size = 2
    }
  }
}

module "ecr" {
  source          = "terraform-aws-modules/ecr/aws"
  for_each        = toset(var.services)
  repository_name = "${var.ecr_name}/${each.key}"

  repository_read_write_access_arns = ["arn:aws:iam::745838912158:user/terraform-deployer"]
  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last 30 images",
        selection = {
          tagStatus     = "tagged",
          tagPrefixList = ["v"],
          countType     = "imageCountMoreThan",
          countNumber   = 30
        },
        action = {
          type = "expire"
        }
      }
    ]
  })
}

resource "aws_security_group" "rds-postgres-sg" {
  name_prefix = "retail-store-rds-"
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
  name_prefix = "retail-store-rds-"
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
}

resource "aws_dynamodb_table" "cart" {
  name         = "Items"
  billing_mode = "PROVISIONED"

  read_capacity  = 1
  write_capacity = 1

  hash_key = "id"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "customerId"
    type = "S"
  }

  global_secondary_index {
    name            = "idx_global_customerId"
    hash_key        = "customerId"
    projection_type = "ALL"
    read_capacity   = 1
    write_capacity  = 1
  }
}

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
  replication_group_id = "checkout-valkey"
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
