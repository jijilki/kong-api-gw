
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~>5.0" //Accept any version greater than or equal to 5.0.0 but less than 6.0.0.
    }
  }
  required_version = ">=1.3.0" //qq what is the use of this? necessary?
}
// configure the aws provider

provider "aws" {
  region = var.region
}


