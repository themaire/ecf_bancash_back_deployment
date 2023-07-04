terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.5.0"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-west-2"
}

# Deployment and service declaration to the cluster
## Source inspiration : https://github.com/shivalkarrahul/DevOps/blob/master/aws/terraform/terraform-kubernetes-deployment/nodejs-application/
## Majors subsetps :
# 1_ : Create a namespace
# 2_ : Deploy our Docker image
# 3_ : Serve the NestJS app names ecf_bancask_back
# 4_ : Done!! >:-)

provider "kubernetes" {
  config_path    = "~/.kube/config"

}

resource "kubernetes_namespace" "this" {
  metadata {
    name = "bancash"
  }
}

# Create variables from terraform.tfvars file. 
variable "secret_database_name" {
  type        = string
}
variable "secret_user" {
  type        = string
}
variable "secret_password" {
  type        = string
}

resource "kubernetes_deployment" "this" {
  metadata {
    name      = "ecf-bancash-back"
    namespace = kubernetes_namespace.this.metadata.0.name
  }
  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "ecf-bancash-back"
      }
    }

	strategy {
      type = "Recreate"
    }

    template {
      metadata {
        labels = {
          app = "ecf-bancash-back"
		  name = "ecf-bancash-back"
        }
      }
      spec {
        container {
          image = "071170175291.dkr.ecr.us-west-2.amazonaws.com/studi/ecf_bancask_back:latest"
          name  = "ecf-bancash-back-container"

		  liveness_probe {
            tcp_socket {
              port = 3000
            }

            failure_threshold     = 3
            initial_delay_seconds = 3
            period_seconds        = 10
            success_threshold     = 1
            timeout_seconds       = 2
          }

          readiness_probe {
            tcp_socket {
              port = 3000
            }

            failure_threshold     = 1
            initial_delay_seconds = 10
            period_seconds        = 10
            success_threshold     = 1
            timeout_seconds       = 2
          }

        #   resources {
        #     limits {
        #       cpu    = "200m"
        #       memory = "256M"
        #     }
        #   }

          port {
            name           = "http"
            container_port = 3000
            protocol       = "TCP"
          }

          env {
              name  = "PGDATABASE"
              value = var.secret_database_name
          }
          env {
              name  = "PGUSER"
              value = var.secret_user
          }
		      env {
              name  = "PGPASSWORD"
              value = var.secret_password
            }

        }
      }
  	}
  }
}

resource "kubernetes_service" "this" {
  metadata {
    name      = "ecf-bancash-back"
    namespace = kubernetes_namespace.this.metadata.0.name
  }
  spec {
    selector = {
      app = kubernetes_deployment.this.spec.0.template.0.metadata.0.labels.app
    }
    type = "LoadBalancer"
    port {
      name        = "http"
      port        = 3000
      protocol    = "TCP"
      target_port = 3000
    }
  }
}
