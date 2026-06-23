terraform {
  backend "s3" {
    bucket  = "tf-aws-policy"
    key     = "terraform.tfstate"
    region  = "eu-central-1"
    encrypt = true
  }
}
