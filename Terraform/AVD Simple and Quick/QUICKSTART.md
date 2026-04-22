# QUICK START GUIDE
# Azure Virtual Desktop Terraform Demo Environment

## WSL Users (Windows Subsystem for Linux)

If Terraform is only installed in WSL, the deployment script will automatically detect and use it.

**Setup (one-time):**
```bash
# In WSL, ensure Terraform is installed
wsl sudo apt-get update
wsl sudo apt-get install terraform

# Verify
wsl terraform version
```

The PowerShell script will handle everything else automatically!

## 1. Initial Setup (One-time)

### Step 1: Set Your Azure Subscription ID
Open `terraform.tfvars` and update:
```hcl
subscription_id = "00000000-0000-0000-0000-000000000000"  # Replace with YOUR subscription ID
```

To find your subscription ID:
```bash
az account list --output table
```

### Step 2: Update Configuration Values
Edit `terraform.tfvars` and update:
- `resource_group_prefix` - Prefix for your resource groups (e.g., "demo", "prod", "test")
- `admin_password` - Strong password for VMs (must meet Azure requirements)
- `azure_region` - Azure region for deployment

### Step 3: Authenticate to Azure
```bash
az login
```

## 2. Deploy Infrastructure

### Option A: Using PowerShell Script (Recommended for Windows)

```powershell
# Initialize Terraform
.\deploy.ps1 -Action init

# Validate configuration
.\deploy.ps1 -Action validate

# Plan the deployment
.\deploy.ps1 -Action plan

# Apply the deployment
.\deploy.ps1 -Action apply
```

### Option B: Using Terraform CLI Directly

```bash
# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Plan the deployment
terraform plan -out=tfplan

# Apply the deployment
terraform apply tfplan
```

## 3. View Deployment Results

```bash
# See all outputs
terraform output

# Get specific output
terraform output host_pool_registration_token
terraform output file_share_unc_path
terraform output session_host_names
```

## 4. Resource Group Naming Convention

Your deployment will create these resource groups:

- `{prefix}-AVD.ControlPlane` - Contains Host Pool, App Group, Workspace
- `{prefix}-AVD.Compute` - Contains Session Host VMs and Networking
- `{prefix}-AVD.Profiles` - Contains Storage for FSLogix Profiles (if enabled)

Example with prefix "demo":
- `demo-AVD.ControlPlane`
- `demo-AVD.Compute`
- `demo-AVD.Profiles` (optional)

## 5. Customization Options

### Scale Up Session Hosts
Edit `terraform.tfvars`:
```hcl
session_host_count = 5  # Change from 2 to 5 (or any number 1-100)
```

Then apply:
```bash
terraform apply
```

### Change VM Size
```hcl
session_host_vm_size = "Standard_D4s_v3"  # Larger VM for more users
```

Sizes:
- `Standard_D2s_v3` - 2 vCPU, 8 GB RAM (small/demo)
- `Standard_D4s_v3` - 4 vCPU, 16 GB RAM (medium)
- `Standard_D8s_v3` - 8 vCPU, 32 GB RAM (large)

### Enable Entra ID Join
The default configuration joins VMs to Entra ID automatically. To disable:
```hcl
entra_id_join = false
```

### Configure Hybrid Join (On-Premises AD)
```hcl
hybrid_join      = true
domain_name      = "corp.contoso.com"
domain_username  = "CORP\\domainadmin"
domain_password  = "DomainAdminPassword"
domain_ou_path   = "OU=AVD,OU=Computers,DC=corp,DC=contoso,DC=com"
```

### Enable FSLogix Profiles
```hcl
fslogix_enabled = true  # Default is false
```

### Disable Components
Disable specific components by setting to `false`:
```hcl
control_plane_enabled = true   # Host Pool, App Group, Workspace
compute_enabled       = true   # Session Hosts, Networking
enable_monitoring     = true   # Log Analytics
```

## 6. Post-Deployment Steps

### Register Session Hosts to Host Pool

1. Get the registration token:
```bash
terraform output host_pool_registration_token
```

2. On each session host VM:
   - Connect via RDP
   - Download AVD agent from: https://aka.ms/avdagent
   - Install with your registration token

### Configure FSLogix Profiles (if enabled)

1. Get the file share path:
```bash
terraform output file_share_unc_path
```

2. Share example output: `\\mystorageacct.file.core.windows.net\fslogix-profiles`

3. Grant Azure AD user access in Azure Portal

4. Configure on session hosts via Group Policy

### Assign Users to Desktop

1. Go to Azure Portal
2. Find Application Group: `{prefix}-app-group`
3. Add Azure AD users/groups
4. Assign "Desktop Application User" role

## 7. Common Commands

```bash
# Plan changes without applying
terraform plan

# Apply with auto-approval (skip prompt)
terraform apply -auto-approve

# Destroy everything (careful!)
terraform destroy

# View state
terraform state list
terraform state show azurerm_resource_group.control_plane

# Validate syntax
terraform validate

# Format code
terraform fmt -recursive

# Show specific output
terraform output -json | jq .session_host_names.value
```

## 8. Troubleshooting

### Not authenticated
```bash
az login
az account set --subscription "your-subscription-id"
```

### Terraform init fails
```bash
# Clear and retry
rm -r .terraform/
terraform init
```

### WSL Terraform Issues
```bash
# Install Terraform in WSL
wsl sudo apt-get update
wsl sudo apt-get install terraform

# Verify installation
wsl terraform version

# The PowerShell script will automatically detect and use WSL terraform
```

### Resource naming conflicts
Storage account names must be globally unique. If you get naming errors:
- Use a more unique prefix in `terraform.tfvars`
- Try a different azure_region

### Plan shows unexpected changes
This usually means your state is out of sync. Refresh it:
```bash
terraform refresh
terraform plan
```

## 9. Cost Management

Monitor costs:
```bash
# Check what you're paying for
terraform output deployment_summary
```

Typical costs (US East, per month):
- Session Host VMs: $80-$120
- Storage (if enabled): $20-$30
- Monitoring: $10-$15
- **Total: ~$90-$165/month**

To reduce costs:
- Reduce `session_host_count`
- Use `Standard_D2s_v3` instead of larger VMs
- Set `fslogix_enabled = false` if not needed
- Use Standard storage: `storage_account_tier = "Standard"`
- Set `enable_monitoring = false` if not needed

## 10. Next Steps

1. ✓ Update `terraform.tfvars` with your values
2. ✓ Run `.\deploy.ps1 -Action init`
3. ✓ Run `.\deploy.ps1 -Action plan`
4. ✓ Review the plan output
5. ✓ Run `.\deploy.ps1 -Action apply`
6. ✓ Wait for deployment (15-30 minutes)
7. ✓ Get outputs: `terraform output`
8. ✓ Register session hosts to host pool
9. ✓ Configure FSLogix profiles (if enabled)
10. ✓ Assign users to application group

## Need Help?

- Review `README.md` for detailed documentation
- Check Azure Portal for deployment status
- Review Terraform logs: `TF_LOG=DEBUG terraform plan`
- See errors in Activity Log in Azure Portal

## Files Included

- `terraform.tfvars` - Configuration values (EDIT THIS!)
- `variables.tf` - Variable definitions
- `main.tf` - Resource definitions
- `outputs.tf` - Output definitions
- `providers.tf` - Provider configuration
- `deploy.ps1` - PowerShell helper script
- `README.md` - Full documentation
- `.gitignore` - Git configuration
- `QUICKSTART.md` - This file

---

**Ready?** Start with: `.\deploy.ps1 -Action init`
