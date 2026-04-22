# ===== REQUIRED VALUES =====
# Update these with your actual values
subscription_id = "e977ad4d-b68c-462d-8bd2-135320a64572"  # Replace with your Azure Subscription ID

# ===== GENERAL CONFIGURATION =====
resource_group_prefix = "demo"
azure_region          = "eastus"
environment           = "demo"

common_tags = {
  Environment = "Demo"
  ManagedBy   = "Terraform"
  Purpose     = "AVD-Demo"
  CostCenter  = "IT"
}

# ===== CONTROL PLANE CONFIGURATION =====
control_plane_enabled  = true
multisession_enabled   = true  # true = Pooled (multi-session), false = Personal (single-session)
host_pool_name         = "demo-hostpool"
load_balancer_type     = "BreadthFirst"  # Options: BreadthFirst, DepthFirst (ignored for Personal)
app_group_name         = "demo-app-group"
workspace_name         = "demo-workspace"

# ===== COMPUTE CONFIGURATION =====
compute_enabled          = true
session_host_count       = 2
session_host_vm_size     = "Standard_D2s_v3"  # Adjust based on workload requirements
session_host_name_prefix = "avd-host"
os_disk_type             = "Premium_LRS"

# Administrator credentials for session hosts
admin_username = "azureadmin"
admin_password = "ChangeMe!@123456"  # Change this to a strong password

# Entra ID Join Configuration
entra_id_join  = true  # Enable Azure Entra ID join
hybrid_join    = false # Set to true to enable hybrid join with on-premises AD

# Hybrid Join Configuration (only used if hybrid_join = true)
domain_name     = ""  # e.g., "corp.contoso.com"
domain_username = ""  # e.g., "CORP\\domainadmin"
domain_password = ""
domain_ou_path  = ""  # e.g., "OU=AVD,OU=Computers,DC=corp,DC=contoso,DC=com"

# ===== PROFILES/STORAGE CONFIGURATION =====
fslogix_enabled              = false  # Set to true to enable FSLogix profile containers
storage_account_tier         = "Premium"
storage_account_replication  = "LRS"
file_share_quota_gb          = 100
enable_file_share_backup     = true

# ===== NETWORKING CONFIGURATION =====
vnet_address_space   = ["10.0.0.0/16"]
subnet_address_space = ["10.0.1.0/24"]

# ===== MONITORING =====
log_analytics_retention_days = 30
enable_monitoring            = false
