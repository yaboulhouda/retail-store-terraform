terraform {
  backend "s3" {
    bucket       = "retail-store-tfstate-745838912158"
    key          = "retail-store/terraform.tfstate"
    region       = "eu-north-1"
    use_lockfile = true
    encrypt      = true
  }
}
