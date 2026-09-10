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
      instance_types = ["m7i-flex.large"]

      min_size     = 2
      max_size     = 3
      desired_size = 2
    }
  }
}


resource "aws_iam_role" "cart" {
  name = "cart_pod_identity"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AllowEksAuthToAssumeRoleForPodIdentity",
        "Effect" : "Allow",
        "Principal" : { "Service" : "pods.eks.amazonaws.com" },
        "Action" : ["sts:AssumeRole", "sts:TagSession"]
      }
    ]
  })
}

resource "aws_iam_policy" "cart_policy" {
  name        = "cart_pod_policy"
  path        = "/"
  description = "cart pod policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Effect = "Allow"
        Resource = [
          aws_dynamodb_table.cart.arn,
          "${aws_dynamodb_table.cart.arn}/index/*"
        ]
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cart" {
  role       = aws_iam_role.cart.name
  policy_arn = aws_iam_policy.cart_policy.arn
}

resource "aws_eks_pod_identity_association" "cart_association" {
  cluster_name    = module.eks.cluster_name
  namespace       = "default"
  service_account = "cart"
  role_arn        = aws_iam_role.cart.arn
}
