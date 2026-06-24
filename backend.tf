terraform {
  backend "s3" {
    bucket  = "tf-eks-state-01"
    key     = "terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
