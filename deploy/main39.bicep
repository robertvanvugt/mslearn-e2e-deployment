@description('The location into which your Azure resources should be deployed.')
param location string = resourceGroup().location

@description('Select the type of environment you want to provision. Allowed values are Production and Test.')
@allowed([
  'Prod'
  'Test'
])
param environmentType string

@description('A unique suffix to add to resource names that need to be globally unique.')
@maxLength(13)
param resourceNameSuffix string = uniqueString(resourceGroup().id)

@description('The URL to the product review API.')
param reviewApiUrl string

@secure()
@description('The API key to use when accessing the product review API.')
param reviewApiKey string

// Define the names for resources.
var appServiceAppName = 'toy-website-${resourceNameSuffix}'
var appServicePlanName = 'toy-website'
var applicationInsightsName = 'toywebsite'
var storageAccountName = 'mystorage${resourceNameSuffix}'
var storageAccountImagesBlobContainerName = 'toyimages'

// Define the SKUs for each component based on the environment type.
var environmentConfigurationMap = {
  Prod: {
    appServicePlan: {
      sku: {
        name: 'S1'
        capacity: 1
      }
    }
    storageAccount: {
      sku: {
        name: 'Standard_LRS'
      }
    }
  }
  Test: {
    appServicePlan: {
      sku: {
        name: 'F1'
      }
    }
    storageAccount: {
      sku: {
        name: 'Standard_GRS'
      }
    }
  }
}

resource appServicePlan 'Microsoft.Web/serverfarms@2021-01-15' = {
  name: appServicePlanName
  location: location
  sku: environmentConfigurationMap[environmentType].appServicePlan.sku
}

resource appServiceApp 'Microsoft.Web/sites@2021-01-15' = {
  name: appServiceAppName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: applicationInsights.properties.InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: applicationInsights.properties.ConnectionString
        }
        {
          name: 'ReviewApiUrl'
          value: reviewApiUrl
        }
        {
          name: 'ReviewApiKey'
          value: reviewApiKey
        }
        {
          name: 'StorageAccountName'
          value: storageAccount.name
        }
        {
          name: 'StorageAccountBlobEndpoint'
          value: storageAccount.properties.primaryEndpoints.blob
        }
        {
          name: 'StorageAccountImagesContainerName'
          value: storageAccount::blobService::storageAccountImagesBlobContainer.name
        }
      ]
    }
  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Request_Source: 'rest'
    Flow_Type: 'Bluefield'
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: environmentConfigurationMap[environmentType].storageAccount.sku

  resource blobService 'blobServices' = {
    name: 'default'

    resource storageAccountImagesBlobContainer 'containers' = {
      name: storageAccountImagesBlobContainerName

      properties: {
        publicAccess: 'Blob'
      }
    }
  }
}

// OUTPUTS
output appServiceAppName string = appServiceApp.name // Needed to publish the website content to Azure App Service.
output appServiceAppHostName string = appServiceApp.properties.defaultHostName // Needed for smoke tests.
output storageAccountName string = storageAccount.name // Expose the name of the storage account.
output storageAccountImagesBlobContainerName string = storageAccount::blobService::storageAccountImagesBlobContainer.name //Expose the name of the blob container.
