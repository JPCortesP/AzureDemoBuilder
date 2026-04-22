# Azure Virtual Desktop (AVD) Terraform Demo Environment

This Terraform configuration provides a complete, production-ready Azure Virtual Desktop demo environment with the following components:
## Windows Subsystem for Linux (WSL) Support

This project automatically detects and supports Terraform installed in WSL. If you don't have Terraform installed natively on Windows but have it in WSL, simply run the deployment script - it will automatically use the WSL version.

**WSL Setup (one-time):**
```bash
wsl sudo apt-get update
wsl sudo apt-get install terraform
```

The PowerShell deploy script will handle the rest automatically!
## Architecture Overview

The deployment creates three resource groups with the following naming pattern:
- **Control Plane**: `[prefix]-AVD.ControlPlane` - Contains host pool, app group, workspace, and monitoring
- **Compute**: `[prefix]-AVD.Compute` - Contains session host VMs, networking, and no Bastion
- **Profiles**: `[prefix]-AVD.Profiles` - Contains FSLogix profile storage and backups (optional)

## Components Included

### Control Plane (`[prefix]-AVD.ControlPlane`)
- AVD Host Pool (Pooled or Personal)
- AVD Application Group (Desktop)
- AVD Workspace
- Log Analytics Workspace (for monitoring)
- Host Pool Registration Token

### Compute (`[prefix]-AVD.Compute`)
- Virtual Network (VNet)
- Compute Subnet
- Network Security Group
- Session Host Virtual Machines (Windows 10/11 with AVD)
- Network Interfaces

### Profiles (`[prefix]-AVD.Profiles`) - Optional
- Storage Account (Premium or Standard)
- File Share (for FSLogix profiles)
- Backup Vault (optional, for file share backup)
- Diagnostics Configuration

## Prerequisites

Before deploying, ensure you have:

1. **Azure Subscription**: An active Azure subscription
2. **Terraform**: Installed locally (version 1.0 or later) OR in WSL
3. **Azure CLI**: Installed and authenticated (`az login`)
4. **Required Permissions**: 
   - Owner or Contributor role on the subscription
   - Ability to create resource groups, VMs, and storage accounts
5. **Azure Provider**: Terraform will automatically download required providers

### Terraform Installation

**Option A: Native Windows Installation**
```bash
# Download from https://www.terraform.io/downloads
# Or use Chocolatey
choco install terraform
```

**Option B: WSL Installation (Windows Subsystem for Linux)**
```bash
wsl sudo apt-get update
wsl sudo apt-get install terraform
```

The deployment script automatically detects which installation you have and uses it accordingly!

## Installation

### 1. Clone or Download the Configuration

```bash
git clone <repository-url>
cd AzureDemoBuilder/Terraform/"AVD Simple and Quick"
```

### 2. Update Configuration Values

Edit `terraform.tfvars` with your specific values:

```hcl
subscription_id = "your-subscription-id-here"
resource_group_prefix = "your-prefix"  # e.g., "prod", "dev", "demo"
admin_password = "YourSecurePassword@123"  # Must meet Azure requirements
```

### 3. Initialize Terraform

```bash
terraform init
```

This downloads the required providers and initializes the working directory.

## Configuration Options

All configuration is managed through `terraform.tfvars`. Key variables include:

### General Configuration
- `subscription_id`: Your Azure Subscription ID (required)
- `resource_group_prefix`: Prefix for resource groups (default: "demo")
- `azure_region`: Azure region for deployment (default: "eastus")
- `environment`: Environment name for tagging (default: "demo")

### Control Plane Configuration
- `control_plane_enabled`: Enable/disable control plane (default: true)
- `multisession_enabled`: Multi-session pooled (true) or single-session personal (false, default: true)
- `load_balancer_type`: "BreadthFirst" or "DepthFirst" (default: "BreadthFirst")
- `host_pool_name`: Name for the host pool
- `app_group_name`: Name for the application group
- `workspace_name`: Name for the workspace

### Compute Configuration
- `compute_enabled`: Enable/disable compute resources (default: true)
- `session_host_count`: Number of VMs to create (default: 2)
- `session_host_vm_size`: Azure VM size (default: "Standard_D2s_v3")
- `admin_username`: Local admin username for VMs
- `admin_password`: Local admin password for VMs (sensitive)
- `os_disk_type`: "Premium_LRS", "Standard_LRS", or "StandardSSD_LRS"

### Entra ID & Domain Configuration
- `entra_id_join`: Enable Azure Entra ID join (default: true)
- `hybrid_join`: Enable hybrid join with on-premises AD (default: false)
- `domain_name`: AD domain name (required if hybrid_join = true)
- `domain_username`: Domain admin username
- `domain_password`: Domain admin password
- `domain_ou_path`: OU path for hybrid-joined computers

### Profiles/Storage Configuration (Optional)
- `fslogix_enabled`: Enable FSLogix storage (default: false)
- `storage_account_tier`: "Standard" or "Premium"
- `storage_account_replication`: "LRS", "GRS", "RAGRS", or "ZRS"
- `file_share_quota_gb`: Storage quota in GB (100-102400)
- `enable_file_share_backup`: Enable backup vault (default: true)

### Networking Configuration
- `vnet_address_space`: VNet address space (default: ["10.0.0.0/16"])
- `subnet_address_space`: Subnet address space (default: ["10.0.1.0/24"])

### Monitoring
- `enable_monitoring`: Enable Log Analytics and diagnostics (default: true)
- `log_analytics_retention_days`: Log retention (7-730 days, default: 30)

## Deployment

### Plan the Deployment

Review what Terraform will create:

```bash
terraform plan -out=tfplan
```

This creates a plan file showing all resources to be created/modified/destroyed.

### Apply the Configuration

Deploy the infrastructure:

```bash
terraform apply tfplan
```

**Warning**: Deployment can take 15-30 minutes for full infrastructure setup.

### Monitor Deployment

Check deployment status in Azure Portal:
1. Navigate to the created resource groups
2. View deployment history for detailed status
3. Check Activity Log for any errors

## Outputs

After successful deployment, Terraform outputs useful information:

```bash
terraform output
```

Key outputs include:
- Resource group names and IDs
- Host Pool ID and registration token
- Workspace name and ID
- Session host names and private IPs
- Storage account name and file share UNC path (if FSLogix enabled)
- Log Analytics workspace ID

To get specific outputs:

```bash
terraform output host_pool_registration_token
terraform output file_share_unc_path
terraform output session_host_names
```

## Post-Deployment Configuration

### Register Session Hosts to Host Pool

1. Obtain the registration token:
   ```bash
   terraform output host_pool_registration_token
   ```

2. Connect to each session host via RDP or your preferred method

3. Download and run the AVD agent installer with the token

### Configure FSLogix Profiles (if enabled)

1. Get the file share UNC path:
   ```bash
   terraform output file_share_unc_path
   ```

2. Grant Azure AD users access to the file share

3. Configure FSLogix via Group Policy on session hosts

### Assign Users to Application Group

1. In Azure Portal, navigate to the Application Group
2. Add Azure AD users or groups with "Desktop Application User" role
3. Users will see the desktop in their AVD client

## Common Operations

### Scale Session Hosts

To increase the number of session hosts, update `terraform.tfvars`:

```hcl
session_host_count = 5  # Increase from 2 to 5
```

Then apply:

```bash
terraform apply
```

### Change VM Size

Update `session_host_vm_size` in `terraform.tfvars`:

```hcl
session_host_vm_size = "Standard_D4s_v3"  # Larger VM
```

### Enable FSLogix Profiles

Update `terraform.tfvars`:

```hcl
fslogix_enabled = true
```

Then apply to create the storage infrastructure.

### Destroy Infrastructure

⚠️ **Warning**: This permanently deletes all resources.

```bash
terraform destroy
```

## Troubleshooting

### Issue: Authentication Failed

**Error**: `Error: Error authenticating via Azure CLI: No Azure credentials provided`

**Solution**:
```bash
az login
az account set --subscription "your-subscription-id"
```

### Issue: Insufficient Permissions

**Error**: `Error: Authorization failed: user does not have permission...`

**Solution**: Ensure your Azure account has Owner or Contributor role on the subscription.

### Issue: Storage Account Name Already Exists

**Error**: `Error: storage account name must be globally unique`

**Solution**: The storage account name is derived from `resource_group_prefix`. Use a more unique prefix in `terraform.tfvars`.

### Issue: Deployment Timeout

**Solution**: Some resources take time to deploy. Wait and check Azure Portal for status. If stuck, destroy and retry:

```bash
terraform destroy
terraform apply
```

### Obtaining Logs

For detailed deployment logs:

```bash
TF_LOG=DEBUG terraform apply
```

## Security Best Practices

### 1. Protect Sensitive Variables

Never commit `terraform.tfvars` to version control:

```bash
echo "terraform.tfvars" >> .gitignore
```

### 2. Use Terraform Cloud/Enterprise

Consider using Terraform Cloud for state management and secure variable storage.

### 3. Implement Network Security

- Review NSG rules before deployment
- Consider enabling Azure Firewall for network perimeter security
- Implement private endpoints for storage if needed

### 4. Enable Monitoring

Keep `enable_monitoring = true` for security auditing and compliance.

### 5. Regular Backups

Enable `enable_file_share_backup = true` for FSLogix profiles.

### 6. Access Control

- Use Azure AD/Entra ID for user assignment
- Implement Conditional Access policies
- Use Network Security Groups for granular network control

## Cost Estimation

Approximate monthly costs (based on typical configuration):

| Component | Size | Estimated Cost |
|-----------|------|-----------------|
| Session Host VMs (2x D2s_v3) | 2 vCPU, 8 GB RAM | $80-$120 |
| Storage Account (Premium, if enabled) | 100 GB | $20-$30 |
| Log Analytics | 1 GB ingestion | $10-$15 |
| **Total (estimated)** | | **$90-$165/month** |

Costs vary by region. Use [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/) for accurate estimates.

## Support and Troubleshooting

### Check Terraform State

View current infrastructure state:

```bash
terraform state list
terraform state show azurerm_resource_group.control_plane
```

### Validate Configuration

Check for syntax errors:

```bash
terraform validate
```

### Format Configuration

Auto-format HCL files:

```bash
terraform fmt -recursive
```

## Files Overview

- `providers.tf`: Azure and AzureAD provider configuration
- `variables.tf`: All variable definitions with validation
- `terraform.tfvars`: Variable values (customize this file)
- `main.tf`: Resource definitions
- `outputs.tf`: Output definitions
- `README.md`: This documentation

## Next Steps

1. Customize `terraform.tfvars` with your values
2. Run `terraform plan` to review changes
3. Run `terraform apply` to deploy
4. Configure post-deployment settings
5. Assign users to the application group
6. Connect users via AVD client

## Additional Resources

- [Azure Virtual Desktop Documentation](https://learn.microsoft.com/en-us/azure/virtual-desktop/)
- [Terraform Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest)
- [Microsoft AVD Best Practices](https://learn.microsoft.com/en-us/azure/virtual-desktop/overview)
- [FSLogix Documentation](https://learn.microsoft.com/en-us/fslogix/configure-user-profile-containers)
- [Entra ID Documentation](https://learn.microsoft.com/en-us/entra/identity/)

## License

This Terraform configuration is provided as-is for demonstration purposes.

---

**Last Updated**: April 2026
**Terraform Version**: >= 1.0
**Azure Provider Version**: >= 3.80
