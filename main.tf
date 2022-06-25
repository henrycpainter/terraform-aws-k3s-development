terraform {
  required_version = ">= 1"
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.r53]
    }
    random = {
      source = "hashicorp/random"
    }
    cloudinit = {
      source = "hashicorp/cloudinit"
    }
  }
}

locals {
  name                           = var.name
  install_k3s_version            = var.install_k3s_version
  k3s_cluster_secret             = var.k3s_cluster_secret != null ? var.k3s_cluster_secret : random_password.k3s_cluster_secret.result
  server_instance_type           = var.server_instance_types
  server_volume_type             = var.server_volume_type
  server_image_id                = var.server_image_id != null ? var.server_image_id : data.aws_ami.ubuntu.id
  public_subnets                 = var.public_subnets
  ssh_keys                       = var.ssh_keys
  k3s_tls_san                    = "--tls-san ${aws_eip.this[0].public_dns}"
  server_k3s_exec                = var.server_k3s_exec != null ? var.server_k3s_exec : ""
  certmanager_version            = var.certmanager_version
  letsencrypt_email              = var.letsencrypt_email
  letsencrypt_environment        = var.letsencrypt_environment
  domain                         = var.domain
  r53_domain                     = length(var.r53_domain) > 0 ? var.r53_domain : local.domain
  install_certmanager            = var.install_certmanager
  use_route53                    = var.use_route53 ? 1 : 0
  subdomain                      = var.subdomain != null ? var.subdomain : var.name
}

resource "random_password" "k3s_cluster_secret" {
  length  = 30
  special = false
}

#############################
### Create Public DNS
#############################
resource "aws_route53_record" "this" {
  count    = local.use_route53
  zone_id  = data.aws_route53_zone.dns_zone.0.zone_id
  name     = "${local.subdomain}.${local.domain}"
  type     = "CNAME"
  ttl      = 30
  records  = [aws_eip.this[0].public_dns]
  provider = aws.r53
}