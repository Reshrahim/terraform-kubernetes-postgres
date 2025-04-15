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

resource "kubernetes_deployment" "postgres" {
  metadata {
    name      = "postgres-${random_id.suffix.hex}"
    namespace = var.context.runtime.kubernetes.namespace

  }

  spec {
    selector {
      match_labels = {
        app = "postgres"
        resource = var.context.resource.name
      }
    }

    template {
      metadata {
        labels = {
          app = "postgres"
          resource = var.context.resource.name
        }
      }

      spec {
        container {
          image = "ghcr.io/radius-project/mirror/postgres:latest"
          name  = "postgres"

          env {
            name  = "POSTGRES_PASSWORD"
            value = var.password
          }

          port {
            container_port = 5432
          }
        }
      }
    }
  }
}

resource "random_id" "suffix" {
  byte_length = 4
}

resource "kubernetes_service" "postgres" {
  metadata {
    name      = "postgres-${random_id.suffix.hex}"
    namespace = var.context.runtime.kubernetes.namespace
  }

  spec {
    type = "ClusterIP"
    selector = {
      app = "postgres"
      resource = var.context.resource.name
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
  name = var.context.resource.name
}

output "result" {
  value = {
    values = {
      host = "${kubernetes_service.postgres.metadata[0].name}.${kubernetes_service.postgres.metadata[0].namespace}.svc.cluster.local"
      port = "5432"
      database = var.context.resource.name
      username = "postgres"
      password = var.password
    }
  }
}