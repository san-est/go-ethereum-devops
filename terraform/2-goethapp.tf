data "google_client_config" "default" {}

resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.region

  node_pool {
    name       = "default-pool"
    machine_type = "e2-medium"   # Adjust machine type as needed
    disk_size_gb = 30            # Adjust disk size as needed
    min_count = 1
    max_count = 3
    node_count = 1
  }

  lifecycle {
    ignore_changes = [
      node_pool[0].node_count,
    ]
  }
}

resource "kubernetes_deployment_v1" "primary" {
  metadata {
    name      = "go-eth-app"
    namespace = kubernetes_namespace.default.metadata[0].name
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
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "primary" {
  metadata {
    name      = "go-eth-loadbalancer"
    namespace = kubernetes_namespace.default.metadata[0].name
  }

  spec {
    selector = {
      app = "go-eth-app"
    }
    type = "LoadBalancer"
    port {
      port        = 80
      target_port = 8080
    }
  }
  depends_on = [time_sleep.wait_service_cleanup]
}

# Provide time for Service cleanup
resource "time_sleep" "wait_service_cleanup" {
  depends_on = [google_container_cluster.primary]

  destroy_duration = "180s"
}