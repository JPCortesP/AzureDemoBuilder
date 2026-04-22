targetScope = 'resourceGroup'

param location string
param resourceGroupPrefix string
param hostPoolName string
param appGroupName string
param workspaceName string
param logAnalyticsWorkspaceName string
param enableMonitoring bool
param logAnalyticsRetentionDays int
param customRdpProperties string
param tags object

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = if (enableMonitoring) {
  name: logAnalyticsWorkspaceName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: logAnalyticsRetentionDays
    features: {
      searchVersion: 1
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

resource hostPool 'Microsoft.DesktopVirtualization/hostPools@2024-04-03' = {
  name: hostPoolName
  location: location
  tags: tags
  properties: {
    hostPoolType: 'Pooled'
    loadBalancerType: 'BreadthFirst'
    preferredAppGroupType: 'Desktop'
    maxSessionLimit: 10
    validationEnvironment: false
    friendlyName: '${resourceGroupPrefix} AVD Host Pool'
    description: 'Opinionated Azure Virtual Desktop PoC host pool.'
    customRdpProperty: customRdpProperties
    publicNetworkAccess: 'Enabled'
    startVMOnConnect: false
  }
}

resource appGroup 'Microsoft.DesktopVirtualization/applicationGroups@2024-04-03' = {
  name: appGroupName
  location: location
  tags: tags
  properties: {
    applicationGroupType: 'Desktop'
    hostPoolArmPath: hostPool.id
    friendlyName: '${resourceGroupPrefix} Desktop App Group'
    description: 'Opinionated Azure Virtual Desktop desktop application group.'
  }
}

resource workspace 'Microsoft.DesktopVirtualization/workspaces@2024-04-03' = {
  name: workspaceName
  location: location
  tags: tags
  properties: {
    friendlyName: '${resourceGroupPrefix} Workspace'
    description: 'Opinionated Azure Virtual Desktop workspace.'
    applicationGroupReferences: [
      appGroup.id
    ]
    publicNetworkAccess: 'Enabled'
  }
}

output hostPoolResourceId string = hostPool.id
output workspaceResourceId string = workspace.id
output applicationGroupResourceId string = appGroup.id
output logAnalyticsWorkspaceResourceId string = enableMonitoring ? logAnalyticsWorkspace.id : ''