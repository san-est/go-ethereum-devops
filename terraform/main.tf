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
  host  = google_container_cluster.primary.endpoint 
  client_certificate     = base64decode(google_container_cluster.primary.master_auth.0.client_certificate)
  client_key             = base64decode(google_container_cluster.primary.master_auth.0.client_key)
  cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth.0.cluster_ca_certificate)
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
      app = kubernetes_deployment.default.metadata[0].labels.app
    }

    port {
      port        = 80
      target_port = 8080
    }

    type = "LoadBalancer"
  }
}