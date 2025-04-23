terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0"
    }
  }
}

variable "context" {
  description = "This variable contains Radius recipe context."
  type = any
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
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
          image = "postgres:16-alpine"
          name  = "postgres"
          env {
            name  = "POSTGRES_PASSWORD"
            value = "password"
          }
          env {
            name = "POSTGRES_USER"
            value = "postgres"
          }
          env {
            name  = "POSTGRES_DB"
            value = "postgres_db_test"
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

output "result" {
  value = {
    values = {
      host = "${kubernetes_service.postgres.metadata[0].name}.${kubernetes_service.postgres.metadata[0].namespace}.svc.cluster.local"
      port = "5432"
      database = "postgres_db_test"
      username = "postgres"
      password = "${random_password.password.result}"
    }
  }
}