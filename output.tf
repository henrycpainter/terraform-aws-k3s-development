output "external_dns_name" {
  value = "TODO"
}

output "k3s_cluster_secret" {
  value     = local.k3s_cluster_secret
  sensitive = true
}
