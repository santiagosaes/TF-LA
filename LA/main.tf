terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

module "web_app_1" {
  source = "../LA-modules"

# Input Variables
 # bucket_prefix    = "web-app-1-data"
 # domain           = "devopsdeployed.com"
  app_name         = "web-app-1"
 # environment_name = "production"
  instance_type    = "t2.micro"
 # create_dns_zone  = true
  #db_name          = "webapp1db"
 # db_user          = "foo"
 # db_pass          = var.db_pass_1
}