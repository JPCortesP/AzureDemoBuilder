# Azure Demo Builder

A collection of opinionated, fast-track deployment templates for common Azure services. Each template is designed for quick proof-of-concept (PoC) validation and demo scenarios.

## ⚠️ Testing in Progress

This repository is currently in **active testing**. Expect changes to APIs, naming conventions, and deployment patterns as we refine the offerings.

Please report issues or provide feedback via GitHub issues or discussions.

---

## Available Deployments

### AVD Simple and Quick

A complete Azure Virtual Desktop PoC with session hosts, Entra ID login, and optional FSLogix.

**Available in two flavors:**

#### 1. Bicep (Recommended for low-friction setup)
Azure-native deployment with minimal configuration. Single resource group by default for fast cleanup.

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FJPCortesP%2FAzureDemoBuilder%2Fmain%2FBicep%2FAVD%2520Simple%2520and%2520Quick%2Fmain.json)

**Quick start:**
```bash
az login
az account set --subscription <subscription-id>
az deployment sub create \
  --name avd-simple-and-quick \
  --location eastus \
  --template-file Bicep/AVD\ Simple\ and\ Quick/main.bicep \
  --parameters Bicep/AVD\ Simple\ and\ Quick/main.parameters.json
```

See [Bicep/AVD Simple and Quick/README.md](Bicep/AVD%20Simple%20and%20Quick/README.md) for details.

#### 2. Terraform (Recommended for infrastructure teams)
Full-featured Terraform module with complete customization support.

**Quick start:**
```bash
cd Terraform/AVD\ Simple\ and\ Quick
terraform init
terraform plan
terraform apply
```

See [Terraform/AVD Simple and Quick/README.md](Terraform/AVD%20Simple%20and%20Quick/README.md) for details.

---

## Folder Structure

```
AzureDemoBuilder/
├── Bicep/AVD Simple and Quick/          # Azure-native PoC (low-tech lane)
│   ├── main.bicep                       # Main template
│   ├── main.json                        # Compiled ARM template
│   ├── main.parameters.json             # Sample parameters
│   ├── modules/                         # Resource group scoped modules
│   └── README.md                        # Deployment guide
├── Terraform/AVD Simple and Quick/      # Infrastructure as code (advanced lane)
│   ├── main.tf                          # Resource definitions
│   ├── variables.tf                     # Variable definitions
│   ├── terraform.tfvars                 # Sample values
│   ├── deploy.ps1                       # PowerShell deployment helper
│   └── README.md                        # Deployment guide
└── README.md                            # This file
```

---

## Deployment Philosophy

This repo supports a **two-lane delivery model**:

- **Low-friction lane (Bicep)**: Click a button or run one command. Minimal inputs, opinionated defaults, fast PoC setup.
- **Advanced lane (Terraform)**: Fork and customize. Full control over naming, sizing, networking, identity.

Both lanes deploy the same infrastructure on the same opinionated architecture, just with different UX and flexibility.

---

## Prerequisites

### Bicep
- Azure CLI (`az`) installed
- Active Azure subscription
- Sufficient permissions to create resource groups and resources

### Terraform
- Terraform installed (natively or in WSL)
- Azure CLI (`az`) installed
- Active Azure subscription
- Sufficient permissions to create resource groups and resources

---

## Key Features

### AVD Simple and Quick

✅ **Multi-session pooled host pool** (single-session personal mode available via toggle)  
✅ **Azure Entra ID login enabled by default** (no hybrid join required)  
✅ **Optional FSLogix file share** for user profiles  
✅ **Optional Log Analytics workspace** for diagnostics  
✅ **Simplified networking** (no Bastion, no complex routing)  
✅ **Single resource group** by default for fast cleanup  
✅ **Complete tagging and governance** ready for enterprise integration  

---

## Post-Deployment

After deployment, you will need to:

1. **Generate an AVD registration token** from the host pool
2. **Register session hosts** to the host pool using the AVD agent
3. **Assign Azure AD users** to the application group
4. **Configure FSLogix** (if enabled) via Group Policy or MDM

See the deployment guide in each folder for step-by-step instructions.

---

## Cost Considerations

Typical monthly cost for the default configuration (2x Standard_D2s_v3 VMs in eastus):

| Component | Estimated Cost |
|-----------|---|
| Session Host VMs (2x) | $80-$120 |
| Storage (FSLogix, if enabled) | $20-$30 |
| Log Analytics (if enabled) | $10-$15 |
| **Total** | **~$90-$165/month** |

Use the [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/) for accurate estimates in your region.

---

## Troubleshooting

### Azure CLI/Bicep Deployment
- Ensure you're logged in: `az login`
- Check your subscription: `az account show`
- Enable debug logs: `export BICEP_DEBUG=true` (or `$env:BICEP_DEBUG=$true` on Windows)

### Terraform Deployment
- Check Terraform version: `terraform version` (requires >= 1.0)
- Enable debug logs: `export TF_LOG=DEBUG` (or `$env:TF_LOG="DEBUG"` on Windows)
- See [Terraform/AVD Simple and Quick/README.md](Terraform/AVD%20Simple%20and%20Quick/README.md) for WSL-specific instructions

### Session Host Registration
- Verify the registration token hasn't expired (default: 1 year)
- Ensure the AVD agent is installed on session hosts
- Check the session host can reach Azure endpoints (may need NSG rules)

---

## Contributing

This is an opinionated framework. If you find issues or have suggestions, please:

1. Open a GitHub issue with details
2. Include the deployment method used (Bicep vs Terraform)
3. Provide error logs if applicable

---

## License

This work is provided as-is for demonstration and PoC purposes.

---

**Last Updated**: April 2026  
**Status**: Testing in progress  
**Maintainer**: JPCortesP
