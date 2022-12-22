// SCOPE
targetScope = 'subscription' //Deploying at Subscription scope to allow resource groups to be created and resources in one deployment

// PARAMETERS
@description('Required. Specifies the name of the resource group that must be created.')
param resourceGroupName string

@description('Required. Specifies the location of the resource group that must be created.')
param location string

@description('Required. Specifies the location of the resource group that must be created.')
param environmentType string


// VARIABLES
var tags = { Environment: environmentType }


// RESOURCE DEPLOYMENTS
resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}
