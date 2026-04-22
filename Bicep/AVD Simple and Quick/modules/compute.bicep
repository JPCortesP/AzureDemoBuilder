targetScope = 'resourceGroup'

param location string
param hostPoolName string
param sessionHostCount int
param sessionHostVmSize string
param adminUsername string
@secure()
param adminPassword string
param vnetName string
param computeSubnetName string
param computeSubnetAddressPrefix string
param vnetAddressSpace string
param computeNsgName string
param tags object

var sessionHostNamePrefix = 'avd-host'

resource computeNsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: computeNsgName
  location: location
  tags: tags
  properties: {
    securityRules: []
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressSpace
      ]
    }
    subnets: [
      {
        name: computeSubnetName
        properties: {
          addressPrefix: computeSubnetAddressPrefix
          networkSecurityGroup: {
            id: computeNsg.id
          }
        }
      }
    ]
  }
}

resource sessionHostNics 'Microsoft.Network/networkInterfaces@2024-05-01' = [for index in range(0, sessionHostCount): {
  name: '${sessionHostNamePrefix}-nic-${padLeft(string(index + 1), 2, '0')}'
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, computeSubnetName)
          }
        }
      }
    ]
  }
}]

resource sessionHosts 'Microsoft.Compute/virtualMachines@2024-03-01' = [for index in range(0, sessionHostCount): {
  name: '${sessionHostNamePrefix}-${padLeft(string(index + 1), 2, '0')}'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  tags: union(tags, {
    ServerRole: 'AVD-SessionHost'
    HostPool: hostPoolName
  })
  properties: {
    hardwareProfile: {
      vmSize: sessionHostVmSize
    }
    osProfile: {
      computerName: '${sessionHostNamePrefix}${padLeft(string(index + 1), 2, '0')}'
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: true
        patchSettings: {
          patchMode: 'AutomaticByPlatform'
          assessmentMode: 'AutomaticByPlatform'
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsDesktop'
        offer: 'windows-ent-cpc'
        sku: 'win11-23h2-avd'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: sessionHostNics[index].id
          properties: {
            primary: true
          }
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
    securityProfile: {
      securityType: 'TrustedLaunch'
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
    }
  }
}]

resource entraIdLoginExtensions 'Microsoft.Compute/virtualMachines/extensions@2024-03-01' = [for index in range(0, sessionHostCount): {
  name: '${sessionHosts[index].name}/AADLoginForWindows'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.ActiveDirectory'
    type: 'AADLoginForWindows'
    typeHandlerVersion: '2.2'
    autoUpgradeMinorVersion: true
  }
}]

output sessionHostNames array = [for index in range(0, sessionHostCount): sessionHosts[index].name]
output virtualNetworkName string = vnet.name