param location string = 'eastus'
param environment string = 'prod'
param appName string = 'college-management'

// Storage account for backups
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: '${appName}storage${uniqueString(resourceGroup().id)}'
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    accessTier: 'Hot'
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
  }
}

// PostgreSQL Server
resource postgresServer 'Microsoft.DBforPostgreSQL/servers@2017-12-01' = {
  name: '${appName}-db-${environment}'
  location: location
  sku: {
    name: 'B_Gen5_2'
    tier: 'Basic'
    capacity: 2
    family: 'Gen5'
  }
  properties: {
    createMode: 'Default'
    version: '14'
    administratorLogin: 'dbadmin'
    administratorLoginPassword: uniqueString(resourceGroup().id, deployment().name)
    storageProfile: {
      storageMB: 51200
      backupRetentionDays: 35
      geoRedundantBackup: 'Enabled'
      storageAutogrow: 'Enabled'
    }
    sslEnforcement: 'ENABLED'
    minimalTlsVersion: 'TLS1_2'
    publicNetworkAccess: 'Enabled'
  }
}

// PostgreSQL Database
resource postgresDatabase 'Microsoft.DBforPostgreSQL/servers/databases@2017-12-01' = {
  parent: postgresServer
  name: '${appName}_${environment}_db'
  properties: {
    charset: 'UTF8'
    collation: 'en_US.utf8'
  }
}

// PostgreSQL Firewall Rule
resource postgresFirewall 'Microsoft.DBforPostgreSQL/servers/firewallRules@2017-12-01' = {
  parent: postgresServer
  name: 'AllowAllAzureIps'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

// Container Registry
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-09-01' = {
  name: '${appName}${uniqueString(resourceGroup().id)}'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    adminUserEnabled: true
    publicNetworkAccess: 'Enabled'
    networkRuleBypassOptions: 'AzureServices'
    policies: {
      quarantinePolicy: {
        status: 'disabled'
      }
      trustPolicy: {
        type: 'Notary'
        status: 'disabled'
      }
      retentionPolicy: {
        days: 30
        status: 'enabled'
      }
    }
  }
}

// Key Vault for secrets
resource keyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' = {
  name: '${appName}-kv-${uniqueString(resourceGroup().id)}'
  location: location
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: false
    accessPolicies: []
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

// Log Analytics Workspace
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: '${appName}-logs-${environment}'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// Application Insights
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: '${appName}-insights-${environment}'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
    RetentionInDays: 30
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// Container App Environment
resource containerAppEnv 'Microsoft.App/managedEnvironments@2022-03-01' = {
  name: '${appName}-env-${environment}'
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: reference(logAnalytics.id, '2021-06-01').customerId
        sharedKey: listKeys(logAnalytics.id, '2021-06-01').primarySharedKey
      }
    }
  }
}

// Container App
resource containerApp 'Microsoft.App/containerApps@2022-03-01' = {
  name: '${appName}-${environment}'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    managedEnvironmentId: containerAppEnv.id
    configuration: {
      ingress: {
        external: true
        targetPort: 8080
        allowInsecure: false
        traffic: [
          {
            latestRevision: true
            weight: 100
          }
        ]
      }
      registries: [
        {
          server: '${containerRegistry.properties.loginServer}'
          username: containerRegistry.properties.loginServer
          passwordSecretRef: 'registry-password'
        }
      ]
      secrets: [
        {
          name: 'registry-password'
          value: listCredentials(containerRegistry.id, '2021-09-01').passwords[0].value
        }
        {
          name: 'db-password'
          value: postgresServer.properties.administratorLoginPassword
        }
      ]
    }
    template: {
      containers: [
        {
          name: appName
          image: '${containerRegistry.properties.loginServer}/${appName}:latest'
          resources: {
            cpu: '0.5'
            memory: '1.0Gi'
          }
          env: [
            {
              name: 'SPRING_DATASOURCE_URL'
              value: 'jdbc:postgresql://${postgresServer.properties.fullyQualifiedDomainName}:5432/${postgresDatabase.name}'
            }
            {
              name: 'SPRING_DATASOURCE_USERNAME'
              value: '${postgresServer.properties.administratorLogin}@${postgresServer.name}'
            }
            {
              name: 'SPRING_DATASOURCE_PASSWORD'
              secretRef: 'db-password'
            }
            {
              name: 'SPRING_PROFILES_ACTIVE'
              value: environment
            }
            {
              name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
              value: reference(appInsights.id, '2020-02-02').ConnectionString
            }
          ]
          probes: [
            {
              type: 'liveness'
              httpGet: {
                path: '/actuator/health'
                port: 8080
              }
              initialDelaySeconds: 30
              periodSeconds: 10
            }
            {
              type: 'readiness'
              httpGet: {
                path: '/actuator/health/readiness'
                port: 8080
              }
              initialDelaySeconds: 20
              periodSeconds: 5
            }
          ]
        }
      ]
      scale: {
        minReplicas: 2
        maxReplicas: 5
        rules: [
          {
            name: 'cpu'
            custom: {
              query: 'cpu'
              metadata: {
                type: 'cpu'
                value: '70'
              }
            }
          }
          {
            name: 'memory'
            custom: {
              query: 'memory'
              metadata: {
                type: 'memory'
                value: '80'
              }
            }
          }
        ]
      }
    }
  }
}

// Outputs
output postgresHost string = postgresServer.properties.fullyQualifiedDomainName
output postgresDatabase string = postgresDatabase.name
output registryUrl string = containerRegistry.properties.loginServer
output containerAppUrl string = containerApp.properties.configuration.ingress.fqdn
output keyVaultName string = keyVault.name
output logAnalyticsId string = logAnalytics.id
