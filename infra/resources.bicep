param name string = 'icecream-demo'
param resourceToken string

param openai_api_version string

param openAiLocation string
param openAiSkuName string 
// param chatGptDeploymentCapacity int 
// param chatGptDeploymentName string
// param chatGptModelName string 
// param chatGptModelVersion string
// param embeddingDeploymentName string 
// param embeddingDeploymentCapacity int
// param embeddingModelName string 

param searchServiceSkuName string = 'standard'
param searchServiceIndexName string = 'icecream-chat'

param apimSkuName string


param storageServiceSku object
param storageServiceImageContainerName string

param location string = resourceGroup().location

@secure()

param tags object = {}

var openai_name = toLower('${name}-aillm-${resourceToken}')
var acr_name = toLower('${replace(name, '-', '')}acr${resourceToken}')
var search_name = toLower('${name}search${resourceToken}')
var webapp_name = toLower('${name}-webapp-${resourceToken}')
var appservice_name = toLower('${name}-app-${resourceToken}')
var aivision_name = toLower('${name}-vision-${resourceToken}')
var apim_name  = toLower('${name}-apim-${resourceToken}')

// storage name must be < 24 chars, alphanumeric only. 'sto' is 3 and resourceToken is 13
var clean_name = replace(replace(name, '-', ''), '_', '')
var storage_prefix = take(clean_name, 8)
var storage_name = toLower('${storage_prefix}sto${resourceToken}')
// keyvault name must be less than 24 chars - token is 13
var kv_prefix = take(name, 7)
var keyVaultName = toLower('${kv_prefix}-kv-${resourceToken}')
var la_workspace_name = toLower('${name}-la-${resourceToken}')
var diagnostic_setting_name = 'AppServiceConsoleLogs'

// Service Principal and permissions
// var servicePrincipalName = '${name}-sp-${resourceToken}'
// var contributorRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
var keyVaultSecretsOfficerRole = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7')
// var scriptIdentityName = toLower('${name}-mi-${resourceToken}')
var validStorageServiceImageContainerName = toLower(replace(storageServiceImageContainerName, '-', ''))


// var llmDeployments = [
//   {
//     name: chatGptDeploymentName
//     model: {
//       format: 'OpenAI'
//       name: chatGptModelName
//       version: chatGptModelVersion
//     }
//     sku: {
//       name: 'GlobalStandard'
//       capacity: chatGptDeploymentCapacity
//     }
//   }
//   {
//     name: embeddingDeploymentName
//     model: {
//       format: 'OpenAI'
//       name: embeddingModelName
//       version: '2'
//     }
//     capacity: embeddingDeploymentCapacity
//   }
// ]

resource appServicePlan 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: appservice_name
  location: location
  tags: tags
  properties: {
    reserved: true
  }
  sku: {
    name: 'P0v3'
    tier: 'Premium0V3'
    size: 'P0v3'
    family: 'Pv3'
    capacity: 1
  }
  kind: 'linux'
}

resource webApp 'Microsoft.Web/sites@2020-06-01' = {
  name: webapp_name
  location: location
  tags: union(tags, { 'azd-service-name': 'frontend' })
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'node|18-lts'
      alwaysOn: true
      appCommandLine: 'next start'
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      appSettings: [ 
        { 
          name: 'AZURE_KEY_VAULT_NAME'
          value: keyVaultName
        }
        { 
          name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
          value: 'true'
        }
        {
          name: 'AZURE_OPENAI_API_KEY'
          value: '@Microsoft.KeyVault(VaultName=${kv.name};SecretName=${kv::AZURE_OPENAI_API_KEY.name})'
        }
        {
          name: 'AZURE_OPENAI_API_INSTANCE_NAME'
          value: openai_name
        }
        // {
        //   name: 'AZURE_OPENAI_API_DEPLOYMENT_NAME'
        //   value: chatGptDeploymentName
        // }
        // {
        //   name: 'AZURE_OPENAI_API_EMBEDDINGS_DEPLOYMENT_NAME'
        //   value: embeddingDeploymentName
        // }
        {
          name: 'AZURE_OPENAI_API_VERSION'
          value: openai_api_version
        }
        {
          name: 'AZURE_SEARCH_API_KEY'
          value: '@Microsoft.KeyVault(VaultName=${kv.name};SecretName=${kv::AZURE_SEARCH_API_KEY.name})'
        }
        { 
          name: 'AZURE_SEARCH_NAME'
          value: search_name
        }
        { 
          name: 'AZURE_SEARCH_INDEX_NAME'
          value: searchServiceIndexName
        }
        {
          name: 'AZURE_STORAGE_ACCOUNT_NAME'
          value: storage_name
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${acr_name}.azurecr.io'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_USERNAME'
          value: acr.properties.adminUserEnabled ? acr.listCredentials().username : ''
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_PASSWORD'
          value: acr.properties.adminUserEnabled ? acr.listCredentials().passwords[0].value : ''
        }
        {
          name: 'AZURE_STORAGE_ACCOUNT_KEY'
          value: '@Microsoft.KeyVault(VaultName=${kv.name};SecretName=${kv::AZURE_STORAGE_ACCOUNT_KEY.name})'
        }
        {
          name: 'AZURE_VISION_API_KEY'
          value: '@Microsoft.KeyVault(VaultName=${kv.name};SecretName=${kv::AZURE_AI_VISION_KEY.name})'
        }
        {
          name: 'AZURE_VISION_API_ENDPOINT'
          value: aiVisionService.properties.endpoint
        }
        // {
        //   name: 'AZURE_APIM_API_KEY'
        //   value: '@Microsoft.KeyVault(VaultName=${kv.name};SecretName=${kv::APIM_API_KEY.name})'
        // }
        // {
        //   name: 'AZURE_APIM_SERVICE_NAME'
        //   value: apim_name
        // }
      ]
    }
  }
  identity: { type: 'SystemAssigned'}

  resource configLogs 'config' = {
    name: 'logs'
    properties: {
      applicationLogs: { fileSystem: { level: 'Verbose' } }
      detailedErrorMessages: { enabled: true }
      failedRequestsTracing: { enabled: true }
      httpLogs: { fileSystem: { enabled: true, retentionInDays: 1, retentionInMb: 35 } }
    }
  }
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name: la_workspace_name
  location: location
}

resource webDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: diagnostic_setting_name
  scope: webApp
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        category: 'AppServiceConsoleLogs'
        enabled: true
      }
    ]
    metrics: []
  }
}

resource kvFunctionAppPermissions 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(kv.id, webApp.name, keyVaultSecretsOfficerRole)
  scope: kv
  properties: {
    principalId: webApp.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: keyVaultSecretsOfficerRole
  }
}

resource kv 'Microsoft.KeyVault/vaults@2021-06-01-preview' = {
  name: keyVaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
    enabledForDeployment: false
    enabledForDiskEncryption: true
    enabledForTemplateDeployment: false
  }

  resource AZURE_OPENAI_API_KEY 'secrets' = {
    name: 'AZURE-OPENAI-API-KEY'
    properties: {
      contentType: 'text/plain'
      value: azureopenai.listKeys().key1
    }
  }

  resource AZURE_SEARCH_API_KEY 'secrets' = {
    name: 'AZURE-SEARCH-API-KEY'
    properties: {
      contentType: 'text/plain'
      value: searchService.listAdminKeys().secondaryKey
    }
  }

  resource AZURE_STORAGE_ACCOUNT_KEY 'secrets' = {
    name: 'AZURE-STORAGE-ACCOUNT-KEY'
    properties: {
      contentType: 'text/plain'
      value: storage.listKeys().keys[0].value
    }
  }
  resource AZURE_AI_VISION_KEY 'secrets' = {
    name: 'AZURE-AI-VISION-KEY'
    properties: {
      contentType: 'text/plain'
      value: aiVisionService.listKeys().key1
    }
  }
  // resource APIM_API_KEY 'secrets' = {
  //   name: 'APIM_API_KEY'
  //   properties: {
  //     contentType: 'text/plain'
  //     value: apiManagementService.listkeys().primaryKey
  //   }
  // }
}

resource searchService 'Microsoft.Search/searchServices@2022-09-01' = {
  name: search_name
  location: location
  tags: tags
  properties: {
    partitionCount: 1
    publicNetworkAccess: 'enabled'
    replicaCount: 1
  }
  sku: {
    name: searchServiceSkuName
  }
}
resource aiVisionService 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: aivision_name
  location: location
  tags: tags
  kind: 'ComputerVision'
  properties: {
    customSubDomainName: '${name}-vision-${resourceToken}'
    publicNetworkAccess: 'Enabled'
  }
  sku: {
    name: 'S1'
  }
}

// resource aiVisionApiKey 'Microsoft.CognitiveServices/accounts/listKeys/action@2023-05-01' = {
//   parent: aiVisionService
//   name: 'listKeys'
// }
resource azureopenai 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: openai_name
  location: openAiLocation
  tags: tags
  kind: 'OpenAI'
  properties: {
    customSubDomainName: openai_name
    publicNetworkAccess: 'Enabled'
  }
  sku: {
    name: openAiSkuName
  }
}

resource apiManagementService 'Microsoft.ApiManagement/service@2021-08-01' = {
  name: apim_name
  location: location
  tags: tags
  sku: {
    name: apimSkuName
    capacity: 1
  }
  properties: {
    publisherEmail: 'admin@contoso.com'
    publisherName: 'Contoso'
  }
}

resource apiManagementApi 'Microsoft.ApiManagement/service/apis@2021-08-01' = {
  parent: apiManagementService
  name: 'icecream-api'
  properties: {
    displayName: 'Icecream API'
    serviceUrl: 'https://${webApp.properties.defaultHostName}'
    path: 'icapi'
    protocols: [
      'https'
    ]
  }
}
// Dont think I need this, and can have key vault grab this
// resource apimServiceKeys 'Microsoft.ApiManagement/service/listKeys/action@2021-08-01' = {
//   name: 'listKeys'
//   parent: apiManagementService
// }
//
// resource apimApiKey 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' = {
//   parent: kv
//   name: 'APIM-API-KEY'
//   properties: {
//     contentType: 'text/plain'
//     value: apimServiceKeys.properties.primaryKey
//   }
// }
// @batchSize(1)
// resource llmdeployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = [for deployment in llmDeployments: {
//   parent: azureopenai
//   name: deployment.name
//   properties: {
//     model: deployment.model
//     raiPolicyName: contains(deployment, 'raiPolicyName') ? deployment.raiPolicyName : null
//   }
//   sku: contains(deployment, 'sku') ? deployment.sku : {
//     name: 'Standard'
//     capacity: deployment.capacity
//   }
// }]


// TODO: define good default Sku and settings for storage account
resource storage 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: storage_name
  location: location
  tags: tags
  kind: 'StorageV2'
  sku: storageServiceSku

  resource blobServices 'blobServices' = {
    name: 'default'
    resource container 'containers' = {
      name: validStorageServiceImageContainerName
      properties: {
        publicAccess: 'None'
      }
    }
  }
}
resource acr 'Microsoft.ContainerRegistry/registries@2022-12-01' = {
  name: acr_name
  location: location
  tags: tags
  sku: {
    name: 'Premium'
  }
  properties: {
    adminUserEnabled: true

      }
  }
// Create user assigned identity to execute the deployment script
// resource scriptIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
//   name: scriptIdentityName
//   location: location
//   dependsOn: [
//     subscription()
//   ]
// }
// output scriptIdentityId string = scriptIdentity.properties.principalId

// var scriptContent = '''
// #!/bin/bash
// set -e
// # Create the application
// app=$(az ad app create --display-name "${servicePrincipalName}" --query "{appId: appId, objectId: objectId}" --output json)
// appId=$(echo $app | jq -r '.appId')
// objectId=$(echo $app | jq -r '.objectId')
// # Create the service principal
// sp=$(az ad sp create --id $appId --query "{spId: appId}" --output json)
// spId=$(echo $sp | jq -r '.spId')
// # Output the results
// echo "Application ID: $appId"
// echo "Object ID: $objectId"
// echo "Service Principal ID: $spId"
// '''
  // var scriptContent = '''
  // $ErrorActionPreference = "Stop"
  // # Create the application
  // $app = az ad app create --display-name "${servicePrincipalName}" --query "{appId: appId, objectId: objectId}" | ConvertFrom-Json
  // # Create the service principal
  // $sp = az ad sp create --id $app.appId --query "{spId: appId}" | ConvertFrom-Json
  // # Output the results
  // Write-Output "Application ID: $($app.appId)"
  // Write-Output "Object ID: $($app.objectId)"
  // Write-Output "Service Principal ID: $($sp.spId)"
  // '''
  
  // resource deploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  //   name: 'createAadAppAndSp'
  //   location: location
  //   kind: 'AzureCLI'
  //   identity: {
  //     type: 'UserAssigned'
  //     userAssignedIdentities: {
  //       '${scriptIdentity.id}': {}
  //     }
  //   }
  //   properties: {
  //     azCliVersion: '2.60.0'
  //     timeout: 'PT30M'
  //     scriptContent: scriptContent
  //     cleanupPreference: 'OnSuccess'
  //     retentionInterval: 'P1D'
  //   }
  //   dependsOn: [
  //     scriptIdentity
  //   ]
  // }

  // resource miRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  //   scope: resourceGroup()
  //   name: guid(resourceGroup().id, 'miRoleAssignment', contributorRoleId)
  //   properties: {
  //     roleDefinitionId: contributorRoleId
  //     principalId: deploymentScript.identity.userAssignedIdentities[scriptIdentity.id].principalId
  //     principalType: 'ServicePrincipal'
  //   }
  //   dependsOn: [
  //     scriptIdentity
  //   ]
  // }
  // resource spRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  //   name: guid(resourceGroup().id, deploymentScript.name, contributorRoleId)
  //   scope: resourceGroup()
  //   properties: {
  //     roleDefinitionId: contributorRoleId
  //     principalId: deploymentScript.properties.outputs.spId
  //     principalType: 'ServicePrincipal'
  //   }
  // }
  
  resource AcrPullRole 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
    name: guid(webApp.id, 'AcrPull')
    scope: acr
    properties: {
      roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
      principalId: webApp.identity.principalId
      principalType: 'ServicePrincipal'
    }
    dependsOn: [
      acr
    ]
  }
output url string = 'https://${webApp.properties.defaultHostName}'
// output applicationId string = deploymentScript.properties.outputs.appId
// output objectId string = deploymentScript.properties.outputs.objectId
// output servicePrincipalId string = deploymentScript.properties.outputs.spId
