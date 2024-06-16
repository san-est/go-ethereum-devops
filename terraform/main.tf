data "google_client_config" "default" {}

# Configurng GCP as provider
provider "google" {
  project     = "go-ethereum-devops"
  region      = "us-central1"
}

# Declaring resources for my GCP k8s Cluster
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

# Configuring k8s as provider
provider "kubernetes" {
  host                   = "https://${google_container_cluster.primary.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth[0].cluster_ca_certificate)

  ignore_annotations = [
    "^autopilot\\.gke\\.io\\/.*",
    "^cloud\\.google\\.com\\/.*"
  ]
}

# Declaring resourecs for my k8s deployment and pointing the containers to get the image we built in previous tasks
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

# Creating a loadbalancer service so that the application is accessble from outside of the cluster
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