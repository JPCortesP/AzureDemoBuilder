# Azure Subscription and General Configuration
variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
  sensitive   = true
}

variable "resource_group_prefix" {
  description = "Prefix for resource group names (e.g., 'demo', 'prod', 'dev')"
  type        = string
  default     = "demo"
}

variable "azure_region" {
  description = "Azure region for resource deployment"
  type        = string
  default     = "eastus"
}

variable "environment" {
  description = "Environment name for tagging (e.g., 'dev', 'staging', 'prod')"
  type        = string
  default     = "demo"
}

# Common Tags
variable "common_tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default = {
    Environment = "Demo"
    ManagedBy   = "Terraform"
    Purpose     = "AVD-Demo"
  }
}

# ===== CONTROL PLANE CONFIGURATION =====
variable "control_plane_enabled" {
  description = "Enable Control Plane resource group and resources"
  type        = bool
  default     = true
}

variable "host_pool_name" {
  description = "Name of the AVD Host Pool"
  type        = string
  default     = "demo-hostpool"
}

variable "multisession_enabled" {
  description = "Enable multi-session pooled host pool (true) or personal single-session (false)"
  type        = bool
  default     = true
}

variable "load_balancer_type" {
  description = "The type of load balancer to use for the host pool. Valid values are 'BreadthFirst' or 'DepthFirst'"
  type        = string
  default     = "BreadthFirst"
  
  validation {
    condition     = contains(["BreadthFirst", "DepthFirst"], var.load_balancer_type)
    error_message = "Load balancer type must be either 'BreadthFirst' or 'DepthFirst'."
  }
}

variable "app_group_name" {
  description = "Name of the AVD Application Group"
  type        = string
  default     = "demo-app-group"
}

variable "workspace_name" {
  description = "Name of the AVD Workspace"
  type        = string
  default     = "demo-workspace"
}

# ===== COMPUTE CONFIGURATION =====
variable "compute_enabled" {
  description = "Enable Compute resource group and resources"
  type        = bool
  default     = true
}

variable "session_host_count" {
  description = "Number of AVD session hosts to deploy"
  type        = number
  default     = 2
  
  validation {
    condition     = var.session_host_count > 0 && var.session_host_count <= 100
    error_message = "Session host count must be between 1 and 100."
  }
}

variable "session_host_vm_size" {
  description = "Azure VM size for session hosts (e.g., 'Standard_D2s_v3', 'Standard_D4s_v3')"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "session_host_name_prefix" {
  description = "Prefix for session host VM names (e.g., 'avd-host')"
  type        = string
  default     = "avd-host"
}

variable "image_id" {
  description = "Custom managed image ID for session hosts. Leave empty to use Azure Marketplace image"
  type        = string
  default     = ""
}

variable "os_disk_type" {
  description = "Type of OS disk (Premium_LRS, Standard_LRS, StandardSSD_LRS)"
  type        = string
  default     = "Premium_LRS"
  
  validation {
    condition     = contains(["Premium_LRS", "Standard_LRS", "StandardSSD_LRS"], var.os_disk_type)
    error_message = "OS disk type must be Premium_LRS, Standard_LRS, or StandardSSD_LRS."
  }
}

variable "entra_id_join" {
  description = "Enable Azure Entra ID (Azure AD) join for session hosts"
  type        = bool
  default     = true
}

variable "hybrid_join" {
  description = "Enable hybrid join (both Entra ID and on-premises AD). Requires entra_id_join = true"
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "Active Directory domain name (required if hybrid_join is true)"
  type        = string
  default     = ""
}

variable "domain_username" {
  description = "Domain username for hybrid join (required if hybrid_join is true)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "domain_password" {
  description = "Domain password for hybrid join (required if hybrid_join is true)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "domain_ou_path" {
  description = "Organizational Unit path for hybrid-joined computers (optional)"
  type        = string
  default     = ""
}

variable "admin_username" {
  description = "Administrator username for session hosts"
  type        = string
  default     = "azureadmin"
  sensitive   = true
}

variable "admin_password" {
  description = "Administrator password for session hosts"
  type        = string
  sensitive   = true
}

# ===== PROFILES/STORAGE CONFIGURATION =====
variable "fslogix_enabled" {
  description = "Enable FSLogix profile containers for user profile management"
  type        = bool
  default     = false
}

variable "storage_account_tier" {
  description = "Storage account tier (Standard or Premium)"
  type        = string
  default     = "Premium"
  
  validation {
    condition     = contains(["Standard", "Premium"], var.storage_account_tier)
    error_message = "Storage account tier must be either 'Standard' or 'Premium'."
  }
}

variable "storage_account_replication" {
  description = "Storage account replication type (LRS, GRS, RAGRS, ZRS)"
  type        = string
  default     = "LRS"
  
  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS"], var.storage_account_replication)
    error_message = "Replication type must be LRS, GRS, RAGRS, or ZRS."
  }
}

variable "file_share_quota_gb" {
  description = "Quota for FSLogix profile file share in GB"
  type        = number
  default     = 100
  
  validation {
    condition     = var.file_share_quota_gb >= 100 && var.file_share_quota_gb <= 102400
    error_message = "File share quota must be between 100 GB and 102400 GB."
  }
}

variable "enable_file_share_backup" {
  description = "Enable backup for the file share"
  type        = bool
  default     = true
}

# ===== NETWORKING CONFIGURATION =====
variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_address_space" {
  description = "Address space for the compute subnet"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

# ===== LOGGING AND MONITORING =====
variable "log_analytics_retention_days" {
  description = "Log Analytics workspace retention period in days"
  type        = number
  default     = 30
  
  validation {
    condition     = var.log_analytics_retention_days >= 7 && var.log_analytics_retention_days <= 730
    error_message = "Retention days must be between 7 and 730."
  }
}

variable "enable_monitoring" {
  description = "Enable Log Analytics and diagnostics"
  type        = bool
  default     = true
}
