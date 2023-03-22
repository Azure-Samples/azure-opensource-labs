@secure()
param kubeConfig string
param namespace string = 'default'

import 'kubernetes@1.0.0' with {
  namespace: namespace
  kubeConfig: kubeConfig
}

resource appsDeployment_postgres 'apps/Deployment@v1' = {
  metadata: {
    name: 'postgres'
  }
  spec: {
    replicas: 1
    selector: {
      matchLabels: {
        app: 'postgres'
      }
    }
    template: {
      metadata: {
        labels: {
          app: 'postgres'
        }
      }
      spec: {
        nodeSelector: {
          'kubernetes.io/os': 'linux'
        }
        containers: [
          {
            name: 'postgres'
            image: 'postgres:15.0-alpine'
            env: [
              {
                name: 'POSTGRES_PASSWORD'
                value: 'mypassword'
              }
            ]
            resources: {
              requests: {
                cpu: '100m'
                memory: '128Mi'
              }
              limits: {
                cpu: '250m'
                memory: '256Mi'
              }
            }
            ports: [
              {
                containerPort: 5432
                name: 'postgres'
              }
            ]
          }
        ]
      }
    }
  }
}

resource coreService_postgres 'core/Service@v1' = {
  metadata: {
    name: 'postgres'
  }
  spec: {
    ports: [
      {
        port: 5432
      }
    ]
    selector: {
      app: 'postgres'
    }
  }
}

resource appsDeployment_azureVotingAppRust 'apps/Deployment@v1' = {
  metadata: {
    name: 'azure-voting-app-rust'
  }
  spec: {
    replicas: 1
    selector: {
      matchLabels: {
        app: 'azure-voting-app-rust'
      }
    }
    template: {
      metadata: {
        labels: {
          app: 'azure-voting-app-rust'
        }
      }
      spec: {
        nodeSelector: {
          'kubernetes.io/os': 'linux'
        }
        containers: [
          {
            name: 'azure-voting-app-rust'
            image: 'ghcr.io/asw101/azure-voting-app-rust:latest'
            resources: {
              requests: {
                cpu: '100m'
                memory: '128Mi'
              }
              limits: {
                cpu: '250m'
                memory: '256Mi'
              }
            }
            ports: [
              {
                containerPort: 8080
              }
            ]
            env: [
              {
                name: 'DATABASE_SERVER'
                value: 'postgres'
              }
              {
                name: 'DATABASE_PASSWORD'
                value: 'mypassword'
              }
              {
                name: 'FIRST_VALUE'
                value: 'Go'
              }
              {
                name: 'SECOND_VALUE'
                value: 'Rust'
              }
            ]
          }
        ]
      }
    }
  }
}

resource coreService_azureVotingAppRust 'core/Service@v1' = {
  metadata: {
    name: 'azure-voting-app-rust'
  }
  spec: {
    type: 'LoadBalancer'
    ports: [
      {
        protocol: 'TCP'
        port: 80
        targetPort: 8080
      }
    ]
    selector: {
      app: 'azure-voting-app-rust'
    }
  }
}


output frontendIp string = coreService_azureVotingAppRust.status.loadBalancer.ingress[0].ip
