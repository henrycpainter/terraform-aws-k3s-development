#Set up a k3s server
data "cloudinit_config" "k3s_server" {
  gzip          = true
  base64_encode = true

  # Main cloud-config configuration file.
  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/files/cloud-config-base.yaml",
      {
        ssh_keys = var.ssh_keys
    })
  }

  # Then install k3s
  part {
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/files/k3s-install.sh",
      {
        install_k3s_version    = local.install_k3s_version,
        k3s_exec               = local.server_k3s_exec,
        k3s_cluster_secret     = local.k3s_cluster_secret,
        k3s_url                = local.create_external_nlb == 1 ? aws_lb.lb[0].dns_name : aws_eip.this[0].private_dns,
        k3s_tls_san            = local.k3s_tls_san,
        eip_id                 = var.simplest ? aws_eip.this[0].id : "",
    })
  }

  part {
    content_type = "text/x-shellscript"
    content = templatefile(
      "${path.module}/files/certs-install.sh",
      { certmanager_version     = local.certmanager_version,
        letsencrypt_email       = local.letsencrypt_email,
        letsencrypt_environment = local.letsencrypt_environment,
        install_certmanager     = local.install_certmanager,
    })
  }
}