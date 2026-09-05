@description('The deployment environment name (e.g., dev, test, prod)')
@allowed([
  'dev'
  'test'
  'prod'
])
param environmentName string = 'dev'

@description('The Azure region where resources will be deployed')
param location string = resourceGroup().location

@description('Prefix for resource names')
param prefix string = 'copilotstudio'

var resourceSuffix = '${prefix}-${environmentName}-${uniqueString(resourceGroup().id)}'

// 1. Azure OpenAI Service (Cognitive Services)
resource openAiAccount 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: 'cog-openai-${resourceSuffix}'
  location: location
  kind: 'OpenAI'
  sku: {
    name: 'S0'
  }
  properties: {
    customSubDomainName: 'openai-${resourceSuffix}'
    publicNetworkAccess: 'Enabled'
  }
}

// Model Deployment: GPT-4o
resource gpt4oDeployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = {
  parent: openAiAccount
  name: 'gpt-4o'
  sku: {
    name: 'Standard'
    capacity: 20
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4o'
      version: '2024-05-13'
    }
  }
}

// Model Deployment: Embeddings
resource embeddingDeployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = {
  parent: openAiAccount
  name: 'text-embedding-3-large'
  sku: {
    name: 'Standard'
    capacity: 20
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'text-embedding-3-large'
      version: '1'
    }
  }
}

// 2. Azure AI Search (Cognitive Search)
resource searchService 'Microsoft.Search/searchServices@2023-11-01' = {
  name: 'srch-${resourceSuffix}'
  location: location
  sku: {
    name: 'standard'
  }
  properties: {
    replicaCount: 1
    partitionCount: 1
    hostingMode: 'default'
  }
}

// 3. Azure Storage Account (Document store for enterprise RAG)
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: replace('st${resourceSuffix}', '-', '')
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
  }
}

// 4. Azure Key Vault (Store secrets for Power Platform Custom Connectors)
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: 'kv-${take(resourceSuffix, 21)}'
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
  }
}

output openAiEndpoint string = openAiAccount.properties.endpoint
output searchServiceEndpoint string = 'https://${searchService.name}.search.windows.net'
output storageAccountName string = storageAccount.name
output keyVaultUri string = keyVault.properties.vaultUri
