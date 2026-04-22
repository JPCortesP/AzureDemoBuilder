# ===== LOCAL VARIABLES =====
locals {
  control_plane_rg_name = "${var.resource_group_prefix}-AVD.ControlPlane"
  compute_rg_name       = "${var.resource_group_prefix}-AVD.Compute"
  fslogix_rg_name       = "${var.resource_group_prefix}-AVD.Profiles"
  
  # Determine host pool type based on multisession_enabled
  host_pool_type = var.multisession_enabled ? "Pooled" : "Personal"
  
  common_tags = merge(
    var.common_tags,
    {
      CreatedDate = timestamp()
    }
  )
}

# ===== RESOURCE GROUPS =====
resource "azurerm_resource_group" "control_plane" {
  count       = var.control_plane_enabled ? 1 : 0
  name        = local.control_plane_rg_name
  location    = var.azure_region
  tags        = local.common_tags
  
  lifecycle {
    ignore_changes = [tags["CreatedDate"]]
  }
}

resource "azurerm_resource_group" "compute" {
  count       = var.compute_enabled ? 1 : 0
  name        = local.compute_rg_name
  location    = var.azure_region
  tags        = local.common_tags
  
  lifecycle {
    ignore_changes = [tags["CreatedDate"]]
  }
}

resource "azurerm_resource_group" "profiles" {
  count       = var.fslogix_enabled ? 1 : 0
  name        = local.fslogix_rg_name
  location    = var.azure_region
  tags        = local.common_tags
  
  lifecycle {
    ignore_changes = [tags["CreatedDate"]]
  }
}

# ===== LOGGING AND MONITORING =====
resource "azurerm_log_analytics_workspace" "avd" {
  count                          = var.control_plane_enabled && var.enable_monitoring ? 1 : 0
  name                           = "${var.resource_group_prefix}-avd-law"
  location                       = var.azure_region
  resource_group_name            = azurerm_resource_group.control_plane[0].name
  sku                            = "PerGB2018"
  retention_in_days              = var.log_analytics_retention_days
  tags                           = local.common_tags
}

# ===== NETWORKING =====
resource "azurerm_virtual_network" "avd" {
  count               = var.compute_enabled ? 1 : 0
  name                = "${var.resource_group_prefix}-avd-vnet"
  address_space       = var.vnet_address_space
  location            = var.azure_region
  resource_group_name = azurerm_resource_group.compute[0].name
  tags                = local.common_tags
}

resource "azurerm_subnet" "compute" {
  count                = var.compute_enabled ? 1 : 0
  name                 = "${var.resource_group_prefix}-compute-subnet"
  resource_group_name  = azurerm_resource_group.compute[0].name
  virtual_network_name = azurerm_virtual_network.avd[0].name
  address_prefixes     = var.subnet_address_space
}

# ===== NETWORK SECURITY GROUPS =====
resource "azurerm_network_security_group" "compute" {
  count               = var.compute_enabled ? 1 : 0
  name                = "${var.resource_group_prefix}-compute-nsg"
  location            = var.azure_region
  resource_group_name = azurerm_resource_group.compute[0].name
  tags                = local.common_tags
}

resource "azurerm_subnet_network_security_group_association" "compute" {
  count                     = var.compute_enabled ? 1 : 0
  subnet_id                 = azurerm_subnet.compute[0].id
  network_security_group_id = azurerm_network_security_group.compute[0].id
}

# ===== AVD HOST POOL =====
resource "azurerm_virtual_desktop_host_pool" "avd" {
  count                    = var.control_plane_enabled ? 1 : 0
  resource_group_name      = azurerm_resource_group.control_plane[0].name
  location                 = var.azure_region
  name                     = var.host_pool_name
  type                     = local.host_pool_type
  load_balancer_type       = local.host_pool_type == "Pooled" ? var.load_balancer_type : null
  friendly_name            = "${var.resource_group_prefix} AVD Host Pool"
  description              = "AVD Host Pool for ${var.environment} environment"
  validate_environment     = false
  custom_rdp_properties    = "drivestoredirect:s:;audiomode:i:0;videoplaybackmode:i:1;redirectclipboard:i:1;redirectprinters:i:1;devicestoredirect:s:*;redirectcomports:i:1;redirectsmartcards:i:1;usbdevicestoredirect:s:*;enablecredsspsupport:i:1;redirectwebauthn:i:1;"
  
  tags = local.common_tags
  
  depends_on = [azurerm_resource_group.control_plane[0]]
}

# ===== AVD APPLICATION GROUP =====
resource "azurerm_virtual_desktop_application_group" "avd" {
  count               = var.control_plane_enabled ? 1 : 0
  resource_group_name = azurerm_resource_group.control_plane[0].name
  location            = var.azure_region
  name                = var.app_group_name
  type                = "Desktop"
  host_pool_id        = azurerm_virtual_desktop_host_pool.avd[0].id
  friendly_name       = "${var.resource_group_prefix} App Group"
  description         = "AVD Application Group for ${var.environment} environment"
  
  tags = local.common_tags
  
  depends_on = [azurerm_virtual_desktop_host_pool.avd[0]]
}

# ===== AVD WORKSPACE =====
resource "azurerm_virtual_desktop_workspace" "avd" {
  count               = var.control_plane_enabled ? 1 : 0
  resource_group_name = azurerm_resource_group.control_plane[0].name
  location            = var.azure_region
  name                = var.workspace_name
  friendly_name       = "${var.resource_group_prefix} Workspace"
  description         = "AVD Workspace for ${var.environment} environment"
  
  tags = local.common_tags
  
  depends_on = [azurerm_resource_group.control_plane[0]]
}

# ===== WORKSPACE APPLICATION GROUP ASSOCIATION =====
resource "azurerm_virtual_desktop_workspace_application_group_association" "avd" {
  count                    = var.control_plane_enabled ? 1 : 0
  workspace_id             = azurerm_virtual_desktop_workspace.avd[0].id
  application_group_id     = azurerm_virtual_desktop_application_group.avd[0].id
}

# ===== STORAGE ACCOUNT FOR FSLogix PROFILES =====
resource "azurerm_storage_account" "profiles" {
  count                    = var.fslogix_enabled ? 1 : 0
  name                     = replace("${var.resource_group_prefix}avdprofiles", "-", "")
  resource_group_name      = azurerm_resource_group.profiles[0].name
  location                 = var.azure_region
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_account_replication
  access_tier              = "Hot"
  https_traffic_only_enabled = true
  min_tls_version          = "TLS1_2"
  
  tags = local.common_tags
  
  depends_on = [azurerm_resource_group.profiles[0]]
}

# ===== FILE SHARE FOR FSLogix PROFILES =====
resource "azurerm_storage_share" "profiles" {
  count                = var.fslogix_enabled ? 1 : 0
  name                 = "fslogix-profiles"
  storage_account_name = azurerm_storage_account.profiles[0].name
  quota                = var.file_share_quota_gb
  enabled_protocol     = "SMB"
  
  depends_on = [azurerm_storage_account.profiles[0]]
}

# ===== STORAGE ACCOUNT BACKUP =====
resource "azurerm_backup_vault" "profiles" {
  count               = var.fslogix_enabled && var.enable_file_share_backup ? 1 : 0
  name                = "${var.resource_group_prefix}-backup-vault"
  resource_group_name = azurerm_resource_group.profiles[0].name
  location            = var.azure_region
  sku                 = "Standard"
  
  tags = local.common_tags
  
  depends_on = [azurerm_resource_group.profiles[0]]
}

# ===== STORAGE ACCOUNT DIAGNOSTICS =====
resource "azurerm_monitor_diagnostic_setting" "storage_account" {
  count                      = var.fslogix_enabled && var.enable_monitoring ? 1 : 0
  name                       = "${var.resource_group_prefix}-storage-diag"
  target_resource_id         = azurerm_storage_account.profiles[0].id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.avd[0].id
  
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# ===== SESSION HOST NETWORK INTERFACES =====
resource "azurerm_network_interface" "session_hosts" {
  count               = var.compute_enabled ? var.session_host_count : 0
  name                = "${var.session_host_name_prefix}-nic-${format("%02d", count.index + 1)}"
  location            = var.azure_region
  resource_group_name = azurerm_resource_group.compute[0].name
  
  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.compute[0].id
    private_ip_address_allocation = "Dynamic"
  }
  
  tags = local.common_tags
  
  depends_on = [azurerm_subnet.compute[0]]
}

# ===== SESSION HOST VIRTUAL MACHINES =====
resource "azurerm_windows_virtual_machine" "session_hosts" {
  count                        = var.compute_enabled ? var.session_host_count : 0
  name                         = "${var.session_host_name_prefix}-${format("%02d", count.index + 1)}"
  computer_name                = "${var.session_host_name_prefix}${format("%02d", count.index + 1)}"
  location                     = var.azure_region
  resource_group_name          = azurerm_resource_group.compute[0].name
  network_interface_ids        = [azurerm_network_interface.session_hosts[count.index].id]
  size                         = var.session_host_vm_size
  admin_username               = var.admin_username
  admin_password               = var.admin_password
  allow_extension_operations   = true
  patch_mode                   = "AutomaticByPlatform"
  
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.os_disk_type
  }
  
  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-10"
    sku       = "22h2-avd-g2"
    version   = "latest"
  }
  
  tags = merge(
    local.common_tags,
    {
      ServerRole = "AVD-SessionHost"
      HostPool   = var.host_pool_name
    }
  )
  
  depends_on = [azurerm_resource_group.compute[0]]
}

# ===== HOST POOL REGISTRATION TOKEN =====
resource "azurerm_virtual_desktop_host_pool_registration_info" "avd" {
  count           = var.control_plane_enabled ? 1 : 0
  hostpool_id     = azurerm_virtual_desktop_host_pool.avd[0].id
  expiration_date = timeadd(timestamp(), "8760h")  # 1 year validity
  
  depends_on = [azurerm_virtual_desktop_host_pool.avd[0]]
}
