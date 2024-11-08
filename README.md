<p align="center">
  <img src="/Images/FedDevSummitBanner.jpg?raw=true" />
</p>

# Microsoft Federal Developer Summit – Day 2 Pro Code Track

# Overview

# Getting Started

1. Create a new fork of this repo in your personal GitHub account
2. In newly created repo(in your account) launch a new Codespaces workspace
3. Run az login - use Dev Summit provided login and password
4. Run az deployment sub create --template-file main.bicep --parameters main.parameters.json --location eastus2 --name Icecream-chatsolution-*YOUR INITALS*

After deployment is complete, which will take several minutes, copy the following outputs to a safe place for later use:
app_url,appRegId,appRegKey,apSpId,and azure_tenant_Id

<img src="/Images/azdoutput.png?raw=true" />
