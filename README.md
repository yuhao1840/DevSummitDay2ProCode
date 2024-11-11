<p align="center">
  <img src="/Images/FedDevSummitBanner.jpg?raw=true" />
</p>

# Microsoft Federal Developer Summit – Day 2 Pro Code Track

# Overview

## Prerequisites
**Github Codespaces** or
1. Bicep v0.30.3 or higher
2. Az CLI (moderately current version)
3. Contributor and User Access Administrator on a subscription (Or Owner)
4. VSCode w/ necessary extensions, or ability to add them

# Getting Started

1. Create a new fork of this repo in your personal GitHub account
2. In newly created repo(in your account) launch a new Codespaces workspace
3. Run `az login` - use Dev Summit provided login and password
4. *Optional* Run `az account set -s <subscriptionId>` if more than one subscription is present
5. Run `az deployment sub create --template-file main.bicep --parameters main.parameters.json --location eastus2 --parameters project="icecream-chat-*YOUR INITALS*"`

After deployment is complete, which will take approximately 30-35 minutes (API Management is the long running process, the environment can start being used before that time but do not close the terminal session), copy the following outputs to a safe place for later use:
`app_url`, `appServcePrincipalKey`, `appServicePrincipalId`, `azure_subscription_id`, `azure_subscripton_name`, and `azure_tenant_Id`
```json
"outputs": {
      "app_url": {
        "type": "String",
        "value": "https://<your-site>.azurewebsites.net"
      },
      "appServicePrincipalId": {
        "type": "String",
        "value": "00000000-0000-0000-0000-000000000000"
      },
      "appServicePrincipalKey": {
        "type": "String",
        "value": "<your-super!secret_.key>"
      },
      "azure_subscription_id": {
        "type": "String",
        "value": "00000000-0000-0000-0000-000000000000"
      },
      "azure_subscription_name": {
        "type": "String",
        "value": "<friendly-subscription-name>"
      },
      "azure_tenant_id": {
        "type": "String",
        "value": "00000000-0000-0000-0000-000000000000"
      }
    },
```

<!-- <img src="/Images/azdoutput.png?raw=true" /> -->
