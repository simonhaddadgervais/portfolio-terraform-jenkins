####### AWS #######
provider "aws" {
  region = var.my_region
}

####### DOCKER VERSION #######
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "2.15.0"
    }
  }
}

###### DOCKER WITH ECR #######
data "aws_ecr_authorization_token" "token" {}

locals {
  aws_ecr_url = "${var.accountId}.dkr.ecr.${var.my_region}.amazonaws.com"
}
#provider "docker" {
#  registry_auth {
#    address  = local.aws_ecr_url
#    username = data.aws_ecr_authorization_token.token.user_name
#    password = data.aws_ecr_authorization_token.token.password
#  }
#}

