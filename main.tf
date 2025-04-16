terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0"
    }
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "1.25.0"
    }
  }
}

provider "postgresql" {
  host     = "postgres.reabdul.svc.cluster.local"
  port     = 5432
  username = "postgres"
  password = "password"
  database = "postgres"
  sslmode = "disable"
}

resource "kubernetes_deployment" "postgres" {
  metadata {
    name      = "postgres"
    namespace = "reabdul"

  }

  spec {
    selector {
      match_labels = {
        app = "postgres"
        resource = "postgres"
      }
    }

    template {
      metadata {
        labels = {
          app = "postgres"
          resource = "postgres"
        }
      }

      spec {
        container {
          image = "ghcr.io/radius-project/mirror/postgres:latest"
          name  = "postgres"

          env {
            name  = "POSTGRES_PASSWORD"
            value = "password"
          }

          port {
            container_port = 5432
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "postgres" {
  metadata {
    name      = "postgres"
    namespace = "reabdul"
  }

  spec {
    selector = {
      app = "postgres"
      resource = "postgres"
    }

    port {
      port        = 5432
      target_port = 5432
    }
  }
}

resource "time_sleep" "wait_120_seconds" {
  depends_on = [kubernetes_service.postgres]
  create_duration = "120s"
}

resource postgresql_database "postgres" {
  depends_on = [time_sleep.wait_120_seconds]
  name = "postgres"
}

output "result" {
  value = {
    values = {
      host = "${kubernetes_service.postgres.metadata[0].name}.${kubernetes_service.postgres.metadata[0].namespace}.svc.cluster.local"
      port = "5432"
      database = "postgres"
      username = "postgres"
      password = var.password
    }
  }
}