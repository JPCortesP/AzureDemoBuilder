# ===== RESOURCE GROUP OUTPUTS =====
output "control_plane_resource_group_name" {
  description = "Name of the Control Plane resource group"
  value       = var.control_plane_enabled ? azurerm_resource_group.control_plane[0].name : null
}

output "control_plane_resource_group_id" {
  description = "ID of the Control Plane resource group"
  value       = var.control_plane_enabled ? azurerm_resource_group.control_plane[0].id : null
}

output "compute_resource_group_name" {
  description = "Name of the Compute resource group"
  value       = var.compute_enabled ? azurerm_resource_group.compute[0].name : null
}

output "compute_resource_group_id" {
  description = "ID of the Compute resource group"
  value       = var.compute_enabled ? azurerm_resource_group.compute[0].id : null
}

output "profiles_resource_group_name" {
  description = "Name of the Profiles resource group"
  value       = var.fslogix_enabled ? azurerm_resource_group.profiles[0].name : null
}

output "profiles_resource_group_id" {
  description = "ID of the Profiles resource group"
  value       = var.fslogix_enabled ? azurerm_resource_group.profiles[0].id : null
}

# ===== AVD CONTROL PLANE OUTPUTS =====
output "host_pool_id" {
  description = "The ID of the AVD Host Pool"
  value       = var.control_plane_enabled ? azurerm_virtual_desktop_host_pool.avd[0].id : null
}

output "host_pool_name" {
  description = "The name of the AVD Host Pool"
  value       = var.control_plane_enabled ? azurerm_virtual_desktop_host_pool.avd[0].name : null
}

output "host_pool_registration_token" {
  description = "The registration token for adding session hosts to the host pool"
  value       = var.control_plane_enabled ? azurerm_virtual_desktop_host_pool_registration_info.avd[0].token : null
  sensitive   = true
}

output "application_group_id" {
  description = "The ID of the AVD Application Group"
  value       = var.control_plane_enabled ? azurerm_virtual_desktop_application_group.avd[0].id : null
}

output "workspace_id" {
  description = "The ID of the AVD Workspace"
  value       = var.control_plane_enabled ? azurerm_virtual_desktop_workspace.avd[0].id : null
}

output "workspace_name" {
  description = "The name of the AVD Workspace"
  value       = var.control_plane_enabled ? azurerm_virtual_desktop_workspace.avd[0].name : null
}

# ===== COMPUTE OUTPUTS =====
output "session_host_ids" {
  description = "IDs of the AVD session host virtual machines"
  value       = var.compute_enabled ? azurerm_windows_virtual_machine.session_hosts[*].id : []
}

output "session_host_names" {
  description = "Names of the AVD session host virtual machines"
  value       = var.compute_enabled ? azurerm_windows_virtual_machine.session_hosts[*].name : []
}

output "session_host_private_ips" {
  description = "Private IP addresses of the session hosts"
  value       = var.compute_enabled ? azurerm_windows_virtual_machine.session_hosts[*].private_ip_address : []
}

output "virtual_network_id" {
  description = "ID of the AVD virtual network"
  value       = var.compute_enabled ? azurerm_virtual_network.avd[0].id : null
}

output "virtual_network_name" {
  description = "Name of the AVD virtual network"
  value       = var.compute_enabled ? azurerm_virtual_network.avd[0].name : null
}

output "compute_subnet_id" {
  description = "ID of the compute subnet"
  value       = var.compute_enabled ? azurerm_subnet.compute[0].id : null
}

# ===== PROFILES/STORAGE OUTPUTS =====
output "storage_account_id" {
  description = "ID of the storage account for FSLogix profiles"
  value       = var.fslogix_enabled ? azurerm_storage_account.profiles[0].id : null
}

output "storage_account_name" {
  description = "Name of the storage account for FSLogix profiles"
  value       = var.fslogix_enabled ? azurerm_storage_account.profiles[0].name : null
}

output "storage_account_primary_blob_endpoint" {
  description = "Primary blob endpoint of the storage account"
  value       = var.fslogix_enabled ? azurerm_storage_account.profiles[0].primary_blob_endpoint : null
}

output "file_share_id" {
  description = "ID of the FSLogix profile file share"
  value       = var.fslogix_enabled ? azurerm_storage_share.profiles[0].id : null
}

output "file_share_name" {
  description = "Name of the FSLogix profile file share"
  value       = var.fslogix_enabled ? azurerm_storage_share.profiles[0].name : null
}

output "file_share_unc_path" {
  description = "UNC path to the FSLogix profile file share"
  value       = var.fslogix_enabled ? "\\\\${azurerm_storage_account.profiles[0].name}.file.core.windows.net\\${azurerm_storage_share.profiles[0].name}" : null
}

output "backup_vault_id" {
  description = "ID of the backup vault for file share backups (if enabled)"
  value       = var.fslogix_enabled && var.enable_file_share_backup ? azurerm_backup_vault.profiles[0].id : null
}

# ===== MONITORING OUTPUTS =====
output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace (if monitoring enabled)"
  value       = var.control_plane_enabled && var.enable_monitoring ? azurerm_log_analytics_workspace.avd[0].id : null
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace (if monitoring enabled)"
  value       = var.control_plane_enabled && var.enable_monitoring ? azurerm_log_analytics_workspace.avd[0].name : null
}

output "log_analytics_customer_id" {
  description = "Workspace (customer) ID of the Log Analytics workspace (if monitoring enabled)"
  value       = var.control_plane_enabled && var.enable_monitoring ? azurerm_log_analytics_workspace.avd[0].workspace_id : null
}

# ===== DEPLOYMENT SUMMARY =====
output "deployment_summary" {
  description = "Summary of the AVD deployment"
  value = {
    resource_group_prefix     = var.resource_group_prefix
    azure_region              = var.azure_region
    environment               = var.environment
    control_plane_enabled     = var.control_plane_enabled
    compute_enabled           = var.compute_enabled
    fslogix_enabled           = var.fslogix_enabled
    multisession_enabled      = var.multisession_enabled
    session_host_count        = var.compute_enabled ? var.session_host_count : 0
    session_host_vm_size      = var.session_host_vm_size
    entra_id_join             = var.entra_id_join
    hybrid_join               = var.hybrid_join
    storage_account_tier      = var.storage_account_tier
    monitoring_enabled        = var.enable_monitoring
  }
}
