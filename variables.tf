variable "context" {
  description = "This variable contains Radius recipe context."
  type = any
}

variable "password" {
  description = "The password for the PostgreSQL database"
  type        = string
  default     = "password"
}

variable "namespace" {
  description = "This variable contains Radius recipe context."
  type        = string
  default = var.context.runtime.kubernetes.namespace
}
