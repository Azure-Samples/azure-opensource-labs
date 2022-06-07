param administratorLogin string = 'username'
@secure()
param administratorLoginPassword string = newGuid()
param firewallRuleIp string = '127.0.0.1'
param storageSizeGb int = 256
param location string = resourceGroup().location

var rand = substring(uniqueString(resourceGroup().id), 0, 6)
var postgresName = 'postgres-${rand}'

resource postgres 'Microsoft.DBforPostgreSQL/flexibleServers@2021-06-01' = {
  name: postgresName
  location: location
  sku: {
    name: 'Standard_B2s'
    tier: 'Burstable'
  }
  properties: {
    version: '13'
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    storage: {
      storageSizeGB: storageSizeGb
    }
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    highAvailability: {
      mode: 'Disabled'
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
output postgresUrl string = 'postgres://${administratorLogin}:$PGPASSWORD@${postgresName}.postgres.database.azure.com/postgres?sslmode=require'
