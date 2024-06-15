data "google_client_config" "default" {}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "kubernetes" {
  host                   = "https://${google_container_cluster.default.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.default.master_auth[0].cluster_ca_certificate)

  ignore_annotations = [
    "^autopilot\\.gke\\.io\\/.*",
    "^cloud\\.google\\.com\\/.*"
  ]
}

resource "kubernetes_namespace" "example" {
  metadata {
    name = "go-eth-namespace"
  }
}

resource "kubernetes_deployment_v1" "default" {
  metadata {
    name = "go-eth-app"
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "go-eth-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "go-eth-app"
        }
      }

      spec {
        container {
          image = "ghcr.io/san-est/go-eth-hardhat:latest"
          name  = "go-eth-app-container"

          port {
            container_port = 8080
            name           = "go-eth-svc"
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "default" {
  metadata {
    name = "go-eth-loadbalancer"
    namespace = kubernetes_namespace.example.metadata[0].name
  }

  spec {
    selector = {
      app = "go-eth-app"
    }

    port {
      port        = 80
      target_port = 8080
    }

    type = "LoadBalancer"
  }

  depends_on = [time_sleep.wait_service_cleanup]
}

# Provide time for Service cleanup
resource "time_sleep" "wait_service_cleanup" {
  depends_on = [google_container_cluster.default]

  destroy_duration = "180s"
}