param name string
param location string
param tags object

@description('https://learn.microsoft.com/en-us/cli/azure/release-notes-azure-cli')
param azCliVersion string = '2.40.0'

@allowed([
  'Always'
  'OnExpiration'
  'OnSuccess'
])
param cleanupPreference string = 'OnSuccess'
param scriptContent string

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: 'uid-${name}'
  location: location
}

// Get the role definition resource by name, to find the name for the role Contributor, you can look 
// it up at the following url: https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#contributor
resource contributorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
  scope: subscription()
}

resource roleAssignmentDeploymentContributor 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(managedIdentity.id, 'Contributor')
  properties: {
    roleDefinitionId: contributorRoleDefinition.id
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource deploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: name
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  kind: 'AzureCLI'
  properties: {
    azCliVersion: azCliVersion
    cleanupPreference: cleanupPreference
    containerSettings: {
      containerGroupName: 'deploymentScript'
    }
    retentionInterval: 'PT1H'
    scriptContent: scriptContent
    timeout: 'PT1H'
  }

  dependsOn: [
    roleAssignmentDeploymentContributor
  ]
}
