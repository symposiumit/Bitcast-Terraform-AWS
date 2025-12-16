terraform {
  backend "s3" {
    bucket         = "nitro-enclaves-terraform-state"
    key            = "envs/default/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "nitro-enclaves-terraform-locks"
    encrypt        = true
  }
}
