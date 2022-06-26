terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
  required_version = ">= 0.14.9"
}

provider "aws" {
  region = "eu-west-1"
}

provider "aws" {
  region = "us-east-1"
  alias  = "global"
}

module "k3s" {
  source = "../.." # Replace with e.g. "henrycpainter/k3s-development"
  #version = "0.0.1"
  name           = "my-k3s-demo"
  domain         = "myownDomain.com"
  public_subnets = [aws_subnet.public[0].id]
  use_route53    = true
  vpc_id         = aws_vpc.this.id
  providers = {
    aws     = aws
    aws.r53 = aws.global
  }
}