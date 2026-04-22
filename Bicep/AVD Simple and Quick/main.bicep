targetScope = 'subscription'

@description('Azure region for all resources in this PoC deployment.')
param location string = 'eastus'

@description('Short prefix used for resource groups and workload resource names.')
@minLength(3)
@maxLength(12)
param resourceGroupPrefix string = 'demo'

@description('Environment tag value applied across resources.')
param environment string = 'demo'

@description('Deploy everything into a single resource group for faster PoC cleanup. Set to false to use separate control-plane, compute, and profiles resource groups.')
param singleResourceGroupDeployment bool = true

@description('Number of session host VMs to deploy.')
@minValue(1)
@maxValue(10)
param sessionHostCount int = 2

@description('Azure VM size for each session host.')
param sessionHostVmSize string = 'Standard_D2s_v3'

@description('Local administrator username for all session hosts.')
param adminUsername string = 'azureadmin'

@secure()
@description('Local administrator password for all session hosts.')
param adminPassword string

@description('Deploy a dedicated FSLogix storage account and file share.')
param fslogixEnabled bool = false

@description('Azure Files quota in GiB when FSLogix is enabled.')
@minValue(100)
@maxValue(102400)
param fileShareQuotaGiB int = 100

@description('Enable a Log Analytics workspace for basic diagnostics.')
param enableMonitoring bool = false

@description('Retention in days for Log Analytics when monitoring is enabled.')
@minValue(7)
@maxValue(730)
param logAnalyticsRetentionDays int = 30

@description('Address space for the virtual network.')
param vnetAddressSpace string = '10.0.0.0/16'

@description('Address prefix for the session host subnet.')
param computeSubnetAddressPrefix string = '10.0.1.0/24'

@description('Optional custom tags to merge with the standard PoC tags.')
param customTags object = {}

var sharedResourceGroupName = '${resourceGroupPrefix}-AVD'
var controlPlaneResourceGroupName = singleResourceGroupDeployment ? sharedResourceGroupName : '${resourceGroupPrefix}-AVD.ControlPlane'
var computeResourceGroupName = singleResourceGroupDeployment ? sharedResourceGroupName : '${resourceGroupPrefix}-AVD.Compute'
var profilesResourceGroupName = singleResourceGroupDeployment ? sharedResourceGroupName : '${resourceGroupPrefix}-AVD.Profiles'

var hostPoolName = '${resourceGroupPrefix}-hostpool'
var appGroupName = '${resourceGroupPrefix}-app-group'
var workspaceName = '${resourceGroupPrefix}-workspace'
var vnetName = '${resourceGroupPrefix}-avd-vnet'
var computeSubnetName = '${resourceGroupPrefix}-compute-subnet'
var computeNsgName = '${resourceGroupPrefix}-compute-nsg'
var logAnalyticsWorkspaceName = '${resourceGroupPrefix}-avd-law'
var commonTags = union({
  Environment: environment
  ManagedBy: 'Bicep'
  Purpose: 'AVD-PoC'
  Architecture: 'AVD-Simple-And-Quick'
}, customTags)
var customRdpProperties = 'drivestoredirect:s:;audiomode:i:0;videoplaybackmode:i:1;redirectclipboard:i:1;redirectprinters:i:1;devicestoredirect:s:*;redirectcomports:i:1;redirectsmartcards:i:1;usbdevicestoredirect:s:*;enablecredsspsupport:i:1;redirectwebauthn:i:1;'

resource sharedRg 'Microsoft.Resources/resourceGroups@2024-03-01' = if (singleResourceGroupDeployment) {
  name: sharedResourceGroupName
  location: location
  tags: commonTags
}

resource controlPlaneRg 'Microsoft.Resources/resourceGroups@2024-03-01' = if (!singleResourceGroupDeployment) {
  name: controlPlaneResourceGroupName
  location: location
  tags: commonTags
}

resource computeRg 'Microsoft.Resources/resourceGroups@2024-03-01' = if (!singleResourceGroupDeployment) {
  name: computeResourceGroupName
  location: location
  tags: commonTags
}

resource profilesRg 'Microsoft.Resources/resourceGroups@2024-03-01' = if (!singleResourceGroupDeployment && fslogixEnabled) {
  name: profilesResourceGroupName
  location: location
  tags: commonTags
}

module controlPlaneSingle './modules/control-plane.bicep' = if (singleResourceGroupDeployment) {
  name: 'control-plane-single'
  scope: sharedRg
  params: {
    location: location
    resourceGroupPrefix: resourceGroupPrefix
    hostPoolName: hostPoolName
    appGroupName: appGroupName
    workspaceName: workspaceName
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    enableMonitoring: enableMonitoring
    logAnalyticsRetentionDays: logAnalyticsRetentionDays
    customRdpProperties: customRdpProperties
    tags: commonTags
  }
}

module controlPlaneSplit './modules/control-plane.bicep' = if (!singleResourceGroupDeployment) {
  name: 'control-plane-split'
  scope: controlPlaneRg
  params: {
    location: location
    resourceGroupPrefix: resourceGroupPrefix
    hostPoolName: hostPoolName
    appGroupName: appGroupName
    workspaceName: workspaceName
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    enableMonitoring: enableMonitoring
    logAnalyticsRetentionDays: logAnalyticsRetentionDays
    customRdpProperties: customRdpProperties
    tags: commonTags
  }
}

module computeSingle './modules/compute.bicep' = if (singleResourceGroupDeployment) {
  name: 'compute-single'
  scope: sharedRg
  params: {
    location: location
    hostPoolName: hostPoolName
    sessionHostCount: sessionHostCount
    sessionHostVmSize: sessionHostVmSize
    adminUsername: adminUsername
    adminPassword: adminPassword
    vnetName: vnetName
    computeSubnetName: computeSubnetName
    computeSubnetAddressPrefix: computeSubnetAddressPrefix
    vnetAddressSpace: vnetAddressSpace
    computeNsgName: computeNsgName
    tags: commonTags
  }
}

module computeSplit './modules/compute.bicep' = if (!singleResourceGroupDeployment) {
  name: 'compute-split'
  scope: computeRg
  params: {
    location: location
    hostPoolName: hostPoolName
    sessionHostCount: sessionHostCount
    sessionHostVmSize: sessionHostVmSize
    adminUsername: adminUsername
    adminPassword: adminPassword
    vnetName: vnetName
    computeSubnetName: computeSubnetName
    computeSubnetAddressPrefix: computeSubnetAddressPrefix
    vnetAddressSpace: vnetAddressSpace
    computeNsgName: computeNsgName
    tags: commonTags
  }
}

module profilesSingle './modules/profiles.bicep' = if (singleResourceGroupDeployment && fslogixEnabled) {
  name: 'profiles-single'
  scope: sharedRg
  params: {
    location: location
    resourceGroupPrefix: resourceGroupPrefix
    fileShareQuotaGiB: fileShareQuotaGiB
    tags: commonTags
  }
}

module profilesSplit './modules/profiles.bicep' = if (!singleResourceGroupDeployment && fslogixEnabled) {
  name: 'profiles-split'
  scope: profilesRg
  params: {
    location: location
    resourceGroupPrefix: resourceGroupPrefix
    fileShareQuotaGiB: fileShareQuotaGiB
    tags: commonTags
  }
}

output controlPlaneResourceGroup string = controlPlaneResourceGroupName
output computeResourceGroup string = computeResourceGroupName
output profilesResourceGroup string = fslogixEnabled ? profilesResourceGroupName : ''
output singleResourceGroupName string = singleResourceGroupDeployment ? sharedResourceGroupName : ''
output hostPoolResourceId string = singleResourceGroupDeployment ? controlPlaneSingle!.outputs.hostPoolResourceId : controlPlaneSplit!.outputs.hostPoolResourceId
output workspaceResourceId string = singleResourceGroupDeployment ? controlPlaneSingle!.outputs.workspaceResourceId : controlPlaneSplit!.outputs.workspaceResourceId
output applicationGroupResourceId string = singleResourceGroupDeployment ? controlPlaneSingle!.outputs.applicationGroupResourceId : controlPlaneSplit!.outputs.applicationGroupResourceId
output sessionHostNames array = singleResourceGroupDeployment ? computeSingle!.outputs.sessionHostNames : computeSplit!.outputs.sessionHostNames
output virtualNetworkName string = singleResourceGroupDeployment ? computeSingle!.outputs.virtualNetworkName : computeSplit!.outputs.virtualNetworkName
output fslogixFileSharePath string = !fslogixEnabled ? '' : (singleResourceGroupDeployment ? profilesSingle!.outputs.fslogixFileSharePath : profilesSplit!.outputs.fslogixFileSharePath)
output deploymentNotes array = [
  singleResourceGroupDeployment ? 'This deployment uses a single resource group for faster PoC cleanup.' : 'This deployment uses separate control-plane, compute, and profiles resource groups.'
  'This Bicep deployment creates the AVD control plane, networking, session hosts, and optional FSLogix storage.'
  'Session hosts are Entra ID login enabled, but AVD host registration is intentionally left as a guided post-deployment step in v1.'
  'Use the companion README in this folder for the recommended operator flow.'
]