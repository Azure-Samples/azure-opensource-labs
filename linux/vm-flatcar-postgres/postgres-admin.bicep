param postgresName string
param principalName string
param principalId string

resource postgresAdministrator 'Microsoft.DBforPostgreSQL/flexibleServers/administrators@2022-12-01' = {
  name: '${postgresName}/${principalId}'
  properties: {
    principalName: principalName
    principalType: 'ServicePrincipal'
    tenantId: subscription().tenantId
  }
}
