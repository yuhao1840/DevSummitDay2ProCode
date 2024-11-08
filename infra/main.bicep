targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param name string


param location string


param openAILocation string

param openAISku string = 'S0'
param openAIApiVersion string ='2024-08-01-preview'

// param chatGptDeploymentCapacity int = 30
// param chatGptDeploymentName string = 'gpt-4o'
// param chatGptModelName string = 'gpt-4o'
// param chatGptModelVersion string = '2024-05-13'
// param embeddingDeploymentName string = 'embedding'
// param embeddingDeploymentCapacity int = 120
// param embeddingModelName string = 'text-embedding-ada-002'

param searchServiceIndexName string = 'icecream-chat'
param searchServiceSkuName string = 'standard'
param apimSkuName string = 'developer'

param storageServiceSku object = { name: 'Standard_LRS' } 
param storageServiceImageContainerName string = 'images'

var resourceToken = toLower(uniqueString(subscription().id, name, location))
var resourceGroupName = 'rg-${name}-${resourceToken}'
var tags = { 'Fed-dev-Summit': name }


// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${name}-${resourceToken}-rg'
  location: location
  tags: tags
}

module resources 'resources.bicep' = {
  name: 'all-resources'
  scope: rg
  params: {
    name: name
    resourceToken: resourceToken
    tags: tags
    openai_api_version: openAIApiVersion
    openAiLocation: openAILocation
    openAiSkuName: openAISku
//    chatGptDeploymentCapacity: chatGptDeploymentCapacity
//    chatGptDeploymentName: chatGptDeploymentName
//    chatGptModelName: chatGptModelName
//    chatGptModelVersion: chatGptModelVersion
//    embeddingDeploymentName: embeddingDeploymentName
//    embeddingDeploymentCapacity: embeddingDeploymentCapacity
//    embeddingModelName: embeddingModelName
    searchServiceIndexName: searchServiceIndexName
    searchServiceSkuName: searchServiceSkuName
    storageServiceSku: storageServiceSku
    storageServiceImageContainerName: storageServiceImageContainerName
    apimSkuName: apimSkuName
    location: location
  }
}

output APP_URL string = resources.outputs.url
output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
