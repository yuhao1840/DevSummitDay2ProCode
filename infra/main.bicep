// Allows use of microsoft.graph namespace for bicep and creation of App registration and Service Principal. 
// Requires Bicep v0.30.3 or later.
extension microsoftGraphV1_0

targetScope = 'subscription'
// Set deployment name in main.parameters.json
@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param name string
param project string

param location string = 'eastus2' // Pulled from deployment or main.parameters.json

// OpenAI settings
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


// Search and APIM SKU
param searchServiceIndexName string = 'icecream-chat'
param searchServiceSkuName string = 'standard'
param apimSkuName string = 'developer'
// Storage
param storageServiceSku object = { name: 'Standard_LRS' } 
param storageServiceImageContainerName string = 'images'

// Generate a unique token for the resource group
var resourceToken = toLower(uniqueString(subscription().id, project, location))
var resourceGroupName = 'rg-${project}-${resourceToken}'
var appreg_name = 'appreg-${project}-${resourceToken}'
var tags = { 'Fed-dev-Summit': project }

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${name}-${resourceToken}-rg'
  location: location
  tags: tags
}
// Generate App Registration and Service Principal + secret
resource appReg 'Microsoft.Graph/applications@v1.0' = {
  uniqueName: appreg_name
  displayName: appreg_name
  signInAudience: 'AzureADMyOrg'
  passwordCredentials: [
    {
      displayName: 'appRegKey'
    }
  ]
}
resource appSp 'Microsoft.Graph/servicePrincipals@v1.0' = {
  appId: appReg.appId
  servicePrincipalType: 'Application'
  displayName: appreg_name
  accountEnabled: true
  appRoleAssignmentRequired: false
}

// Deploy all resources
module resources 'resources.bicep' = {
  name: 'all-resources'
  scope: rg
  params: {
    project: project
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
    appSpId: appSp.id
    location: location
    locationAI: 'eastus'
  }
}

// Output settings for the deployment
output app_url string = resources.outputs.url // URL for the deployed app
output appSpId string = appSp.id // Object ID for Enterprise Application, Is assigned Contributor to Resource Group
output appRegId string = appReg.id // Object ID for App Registration
output appServicePrincipalKey string = appReg.passwordCredentials[0].secretText // Secret for Service Principal
output appServicePrincipalId string = appReg.appId // Application (Client) ID for Service Principal
output azure_tenant_id string = tenant().tenantId // Tenant ID
output azure_subscription_id string = subscription().subscriptionId // Subscription ID
output azure_subscription_name string = subscription().displayName // Subscription ID


