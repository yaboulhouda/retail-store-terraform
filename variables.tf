variable "vpc_cidr" {
  description = "vpc cidr block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_newbits" {
  description = "Number of new bits to add to VPC CIDR to generate subnets (e.g., 8 means /24 from /16)"
  type        = number
  default     = 8
}

variable "cluster_name" {
  description = "Name of EKS cluster"
  type        = string
  default     = "retail-store-cluster"

}

variable "ecr_name" {
  description = "Name of ECR"
  type        = string
  default     = "retail-store"

}

variable "environment_name" {
  description = "Environment name used in resource names and tags"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-north-1"
}

variable "services" {
  type    = list(string)
  default = ["catalog", "cart", "orders", "checkout", "ui"]
}
