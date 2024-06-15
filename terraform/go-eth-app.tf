data "google_client_config" "default" {}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "kubernetes" {
  host                   = "https://${google_container_cluster.primary.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
}



resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.region

  initial_node_count = 1

  node_config {
    machine_type = "e2-medium"

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }
}

resource "google_container_node_pool" "primary_nodes" {
  cluster    = google_container_cluster.primary.name
  location   = google_container_cluster.primary.location
  node_count = 1

  node_config {
    preemptible  = false
    machine_type = "e2-medium"

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }
}

resource "kubernetes_namespace" "example" {
  metadata {
    name = "go-eth-namespace"
  }
}

resource "kubernetes_deployment_v1" "primary" {
  metadata {
    name = "go-eth-app"
    namespace = kubernetes_namespace.example.metadata[0].name
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
    name = "go-eth-loadbalancer"
    namespace = kubernetes_namespace.example.metadata[0].name
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