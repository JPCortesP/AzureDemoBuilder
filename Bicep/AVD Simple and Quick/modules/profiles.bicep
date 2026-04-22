targetScope = 'resourceGroup'

param location string
param resourceGroupPrefix string
param fileShareQuotaGiB int
param tags object

var sanitizedPrefix = take('${toLower(replace(resourceGroupPrefix, '-', ''))}xxx', 14)
var fslogixStorageAccountName = take('${sanitizedPrefix}avdprofiles', 24)
var fslogixShareName = 'fslogix-profiles'

resource fslogixStorageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: fslogixStorageAccountName
  location: location
  sku: {
    name: 'Premium_LRS'
  }
  kind: 'FileStorage'
  tags: tags
  properties: {
    allowBlobPublicAccess: false
    allowCrossTenantReplication: false
    allowSharedKeyAccess: true
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    largeFileSharesState: 'Disabled'
  }
}

resource fileService 'Microsoft.Storage/storageAccounts/fileServices@2023-05-01' = {
  parent: fslogixStorageAccount
  name: 'default'
}

resource fslogixShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2023-05-01' = {
  parent: fileService
  name: fslogixShareName
  properties: {
    accessTier: 'Premium'
    enabledProtocols: 'SMB'
    shareQuota: fileShareQuotaGiB
  }
}

output storageAccountName string = fslogixStorageAccount.name
output fslogixFileSharePath string = '\\${fslogixStorageAccount.name}.file.${environment().suffixes.storage}\${fslogixShareName}'