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
