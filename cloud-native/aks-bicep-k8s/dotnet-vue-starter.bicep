@secure()
param kubeConfig string
param namespace string = 'default'

import 'kubernetes@1.0.0' with {
  namespace: namespace
  kubeConfig: kubeConfig
}

resource appsDeployment_dotnetVueStarter 'apps/Deployment@v1' = {
  metadata: {
    name: 'dotnet-vue-starter'
  }
  spec: {
    replicas: 1
    selector: {
      matchLabels: {
        app: 'dotnet-vue-starter'
      }
    }
    template: {
      metadata: {
        labels: {
          app: 'dotnet-vue-starter'
        }
      }
      spec: {
        nodeSelector: {
          'kubernetes.io/os': 'linux'
        }
        containers: [
          {
            name: 'dotnet-vue-starter'
            image: 'ghcr.io/asw101/dotnet-vue-starter:latest'
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
                containerPort: 80
              }
            ]
          }
        ]
      }
    }
  }
}

resource coreService_dotnetVueStarter 'core/Service@v1' = {
  metadata: {
    name: 'dotnet-vue-starter'
  }
  spec: {
    type: 'LoadBalancer'
    ports: [
      {
        port: 80
      }
    ]
    selector: {
      app: 'dotnet-vue-starter'
    }
  }
}


output frontendIp string = coreService_dotnetVueStarter.status.loadBalancer.ingress[0].ip
