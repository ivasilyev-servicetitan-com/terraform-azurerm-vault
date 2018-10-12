output "vault_cluster_size" {
  value = "${var.num_vault_servers}"
}

output "vault_admin_user_name" {
  value = "${module.vault_servers.admin_user_name}"
}
