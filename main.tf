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


provider postgresql {
  host     = "postgres.default-todoapp.svc.cluster.local"
  port     = 5432
  username = "postgres"
  password = var.password
  sslmode  = "require"
}

resource "kubernetes_deployment" "postgres" {
  metadata {
    name      = "postgres"
    namespace = var.context.runtime.kubernetes.namespace
  }

  spec {
    selector {
      match_labels = {
        app = "postgres"
      }
    }

    template {
      metadata {
        labels = {
          app = "postgres"
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

resource "kubernetes_service" "postgres" {
  metadata {
    name      = "postgres"
    namespace = var.context.runtime.kubernetes.namespace
  }

  spec {
    selector = {
      app = "postgres"
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
      host = "postgres.default-todoapp.svc.cluster.local"
      port = "5432"
      database = var.context.resource.name
      username = "postgres"
      password = var.password
    }
  }
}