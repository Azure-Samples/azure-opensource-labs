@description('Location for all resources.')
param location string = resourceGroup().location
param firewallRuleIp string = '127.0.0.1'
@allowed([
  'small'
  'medium'
])
param size string = 'small'

var rand = substring(uniqueString(resourceGroup().id), 0, 6)
var postgresName = 'postgres-${rand}'

var sizeMap = {
  small: {
    sku: {
      name: 'Standard_B1ms'
      tier: 'Burstable'
    }
    storageSizeGB: 128
  }
  medium: {
    sku: {
      name: 'Standard_B2s'
      tier: 'Burstable'
    }
    storageSizeGB: 256
  }
}

resource postgres 'Microsoft.DBforPostgreSQL/flexibleServers@2022-12-01' = {
  name: postgresName
  location: location
  sku: sizeMap[size].sku
  properties: {
    version: '14'
    //administratorLogin: administratorLogin
    //administratorLoginPassword: administratorLoginPassword
    storage: {
      storageSizeGB: sizeMap[size].storageSizeGB
    }
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    highAvailability: {
      mode: 'Disabled'
    }
    authConfig: {
      activeDirectoryAuth: 'Enabled'
      passwordAuth: 'Disabled'
      tenantId: subscription().tenantId
    }
  }
}

resource postgresFirewallRule 'Microsoft.DBforPostgreSQL/flexibleServers/firewallRules@2021-06-01' = {
  parent: postgres
  name: 'DefaultAllowRule'
  properties: {
    endIpAddress: firewallRuleIp
    startIpAddress: firewallRuleIp
  }
}

output postgresName string = postgresName
output postgresUrl string = 'postgres://$PGUSER:$PGPASSWORD@${postgresName}.postgres.database.azure.com/postgres?sslmode=require'
