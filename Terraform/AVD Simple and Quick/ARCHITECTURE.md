# AVD Architecture and Naming Conventions

## Resource Group Structure

This deployment follows a segregated architecture pattern with three resource groups:

```
[prefix]-AVD.ControlPlane
├── Azure Virtual Desktop Host Pool
├── Application Group (Desktop)
├── Workspace
├── Log Analytics Workspace
├── Host Pool Registration Token
└── Diagnostics Settings

[prefix]-AVD.Compute
├── Virtual Network (VNet)
├── Compute Subnet
├── Network Security Group
├── Session Host VMs (2-100)
├── Network Interfaces
└── (No Bastion)

[prefix]-AVD.Profiles
├── Storage Account (FSLogix)
├── File Share (FSLogix)
├── Backup Vault
├── Diagnostics Settings
└── Storage Access Keys
```

## Naming Convention

| Resource Type | Naming Pattern | Example |
|---------------|----------------|---------|
| Resource Group - Control Plane | `{prefix}-AVD.ControlPlane` | `demo-AVD.ControlPlane` |
| Resource Group - Compute | `{prefix}-AVD.Compute` | `demo-AVD.Compute` |
| Resource Group - Profiles | `{prefix}-AVD.Profiles` | `demo-AVD.Profiles` |
| Host Pool | `{host_pool_name}` | `demo-hostpool` |
| Application Group | `{app_group_name}` | `demo-app-group` |
| Workspace | `{workspace_name}` | `demo-workspace` |
| Virtual Network | `{prefix}-avd-vnet` | `demo-avd-vnet` |
| Compute Subnet | `{prefix}-compute-subnet` | `demo-compute-subnet` |
| Session Host VMs | `{session_host_name_prefix}-##` | `avd-host-01`, `avd-host-02` |
| Network Interfaces | `{session_host_name_prefix}-nic-##` | `avd-host-nic-01` |
| Storage Account | `{prefix}avdprofiles` | `demoavdprofiles` |
| File Share | `fslogix-profiles` | `fslogix-profiles` |
| Log Analytics WS | `{prefix}-avd-law` | `demo-avd-law` |
| Network Security Group | `{prefix}-compute-nsg` | `demo-compute-nsg` |
| Backup Vault | `{prefix}-backup-vault` | `demo-backup-vault` |

## Control Plane Architecture

The Control Plane resource group contains AVD management resources:

```
Host Pool (Pooled or Personal)
    ↓
Application Group (Desktop type)
    ↓
Workspace
    ↓
Users (via Azure AD/Entra ID)
```

### Host Pool Types

**Pooled** (Default - multisession_enabled = true)
- Multiple users share VMs
- Cost-efficient
- VM resources shared
- Best for task workers or general users
- Requires load balancing

**Personal** (multisession_enabled = false)
- One user per VM
- Persistent desktop experience
- Better for power users
- Higher cost per user
- No load balancing needed

### Load Balancer Types

**BreadthFirst** (Default)
- Distributes users across all available VMs
- Balances resource utilization
- Better for pooled deployments

**DepthFirst**
- Fills one VM to capacity before moving to next
- Can reduce costs by leaving some VMs unused
- Better when scaling up/down frequently

## Compute Architecture

The Compute resource group contains session host infrastructure:

```
Virtual Network (10.0.0.0/16)
├── Compute Subnet (10.0.1.0/24)
│   ├── Session Host VM 1
│   │   └── Network Interface (DHCP)
│   ├── Session Host VM 2
│   │   └── Network Interface (DHCP)
│   └── ... (up to 100 VMs)
└── Network Security Group
    └── Inbound Rules (as configured)
    └── Outbound Rules (as configured)
```

### Session Host VM Configuration

- **Operating System**: Windows 10/11 Enterprise (AVD-optimized)
- **Size**: Configurable (Default: Standard_D2s_v3)
- **OS Disk**: Premium SSD (configurable)
- **Authentication**: Entra ID joined by default; optional hybrid join
- **Image**: Azure Marketplace (Windows-10 22h2-avd-g2)
- **Tags**:
  - `ServerRole: AVD-SessionHost`
  - `HostPool: {host_pool_name}`
  - Standard environment tags

### Networking

- **Public Access**: Not exposed directly (no public RDP endpoints)
- **Outbound Internet**: Full outbound access for Azure services
- **Network Security**: NSG with configurable rules
- **DNS**: Azure-provided DNS
- **IP Allocation**: Dynamic (DHCP)
- **Authentication**: Entra ID join (primary) or hybrid domain join (optional)

### Authentication Methods

**Entra ID Join (Default)**
- VMs authenticated via Azure Entra ID
- Users sign in with Azure AD credentials
- No on-premises domain required
- Modern, cloud-first approach

**Hybrid Join (Optional)**
- VMs registered with on-premises AD and Entra ID
- Requires domain_name, domain_username, domain_password
- Useful for hybrid environments
- Allows group policy from on-premises

## Profiles Architecture

The Profiles resource group manages user profile storage (optional - fslogix_enabled):

```
Storage Account (Hot tier)
├── File Share (Premium or Standard)
│   ├── {User SID}_Profile
│   ├── {User SID}_Profile.VHDX
│   ├── {User SID}_O365
│   └── ... (one per user)
├── Backup Vault
│   └── Daily snapshots (configurable)
└── Diagnostics
    └── Metrics to Log Analytics
```

### Storage Configuration

**Premium Storage (Recommended)**
- Tier: Premium
- Replication: LRS (Locally Redundant)
- Cost: Higher ($20-30/month for 100GB)
- Performance: Better for many concurrent users
- Throughput: 100 MB/s

**Standard Storage (Cost-effective)**
- Tier: Standard
- Replication: LRS, GRS, or RAGRS
- Cost: Lower ($5-10/month for 100GB)
- Performance: Adequate for <50 users
- Throughput: 60 MB/s

### FSLogix Profile Structure

Standard FSLogix creates:

```
\\storageaccount.file.core.windows.net\fslogix-profiles\
├── {SID}
│   ├── Profile_User.VHD (or VHDX)
│   └── Metadata files
├── {SID}_O365
│   ├── Teams_Profile.VHDX
│   └── Outlook.OST
└── ... (per user)
```

### Backup Configuration

- **Backup Vault**: Azure Backup (Recovery Services)
- **Retention**: As configured
- **Schedule**: Daily snapshots
- **Recovery**: Point-in-time restore available
- **Cost**: Additional storage charges apply

## Monitoring and Logging

### Log Analytics Workspace

Collects:
- **Host Pool Diagnostics**: Connection history, user sessions
- **Session Host Metrics**: CPU, Memory, Disk usage
- **Storage Diagnostics**: File share access, quota alerts
- **Activity Logs**: Resource-level changes
- **Application Insights**: Custom telemetry (optional)

### Retention and Alerts

- **Retention Period**: Configurable (7-730 days, default: 30)
- **Alert Rules**: Create custom alerts
- **Workbooks**: Visual dashboards
- **Queries**: KQL for troubleshooting

## Security Architecture

### Network Security

```
Internet
  ↓
(Blocked - No direct RDP)
  ↓
Azure Network / VPN (Private access)
  ↓
Virtual Network (10.0.0.0/16)
  ↓
Session Hosts (10.0.1.0/24)
  ↓
FSLogix Storage (Private endpoint optional)
```

### Authentication Flow

```
User (Azure AD / Entra ID)
  ↓
Azure Virtual Desktop Client
  ↓
Workspace Assignment
  ↓
Application Group Access Check
  ↓
Session Host Allocation
  ↓
RDP Protocol (encrypted)
  ↓
Session Host Desktop (Entra ID authenticated)
```

### Access Control

1. **Entra ID**: User identity and licensing (primary)
2. **On-Premises AD**: Optional domain join for hybrid scenarios
3. **RBAC**: Workspace and App Group assignments
4. **NSG**: Network-level filtering
5. **Local Admin**: VM-level permissions

## Deployment Sequence

The resources are deployed in this order:

1. **Resource Groups** (all three)
2. **Networking** (VNet, Subnets, NSG)
3. **Control Plane Resources** (Host Pool, App Group, Workspace)
4. **Storage** (Storage Account, File Share) - if fslogix_enabled
5. **Monitoring** (Log Analytics Workspace)
6. **Session Hosts** (VMs and Network Interfaces)
7. **Post-Deployment** (Tags, Diagnostics, Registration Token)

## Scaling Considerations

### Horizontal Scaling (Add VMs)

```hcl
session_host_count = 5  # Increase from 2 to 5
```

- **Time**: 15-20 minutes per VM
- **Cost**: Linear increase with VM size
- **Load Balancing**: Automatic (BreadthFirst or DepthFirst)

### Vertical Scaling (Larger VMs)

```hcl
session_host_vm_size = "Standard_D4s_v3"  # 4 vCPU instead of 2
```

- **Time**: Requires recreating VMs (downtime)
- **Cost**: Higher per-VM cost
- **Users per VM**: Can increase density

### Storage Scaling

```hcl
file_share_quota_gb = 200  # Increase from 100 to 200 GB
```

- **Time**: Immediate
- **Cost**: Proportional to quota
- **Automatic**: No manual resizing needed

## Performance Metrics Reference

### Recommended VM Sizing

| Use Case | VM Size | vCPU | RAM | Users/VM |
|----------|---------|------|-----|----------|
| Light (Knowledge Workers) | D2s_v3 | 2 | 8 GB | 4-6 |
| Medium (Mixed) | D4s_v3 | 4 | 16 GB | 6-8 |
| Heavy (Power Users) | D8s_v3 | 8 | 32 GB | 4-6 |
| Graphics (GPU) | NV6 | 6 | 56 GB | 2-4 |

### Storage Performance

| Tier | Type | Throughput | Cost/GB/mo |
|------|------|-----------|-----------|
| Premium | LRS | 100 MB/s | $0.20 |
| Standard | LRS | 60 MB/s | $0.05 |
| Standard | GRS | 60 MB/s | $0.10 |

## Compliance and Governance

The deployment includes:

- **Azure Tags**: Environment, ManagedBy, Purpose, etc.
- **Audit Logging**: Activity Log + Log Analytics
- **Encryption**: TLS 1.2 minimum, encryption at rest
- **Backup**: Optional file share backups
- **RBAC**: Fine-grained access control
- **Network Isolation**: Subnet-level segregation
- **Entra ID**: Modern identity management

## Disaster Recovery

### Backup Strategy

```
Session Hosts
├── Managed by: Managed disk snapshots (optional)
├── Frequency: Manual or scheduled
└── Retention: Configurable

FSLogix Profiles
├── Storage Account: Geo-redundant (optional)
├── File Share: Point-in-time restore (optional)
└── Backup Vault: Daily snapshots (if enabled)

Host Pool Config
├── Stored in: Azure (managed service)
├── Recovery: Recreate via Terraform
└── Backup: Terraform state file
```

### Recovery Time Objectives (RTO)

- **Host Pool**: < 30 minutes (recreate via Terraform)
- **Session Hosts**: < 20 minutes (redeploy)
- **FSLogix Profiles**: < 2 hours (restore from backup)

---

**Architecture Version**: 2.0 (Entra ID Join default, no Bastion)
**Last Updated**: April 2026
**Azure Provider**: >= 3.80
**Terraform**: >= 1.0
