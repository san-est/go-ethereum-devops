data "google_client_config" "default" {}

provider "google" {
  project     = "go-ethereum-devops"
  region      = "us-central1"
}

resource "google_container_cluster" "primary" {
  name       = "go-ethereum-cluster"
  location   = "us-central1"

  initial_node_count = 1

  node_config {
    preemptible  = true
    machine_type = "n1-standard-1"

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring"
    ]
  }
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

resource "kubernetes_deployment" "default" {
  metadata {
    name = "go-eth-app"
  }

  spec {
    replicas = 3

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
          name  = "go-eth-container"
          image = "ghcr.io/san-est/go-eth-hardhat:latest"

          port {
            container_port = 8080
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "default" {
  metadata {
    name = "go-eth-service"
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
}