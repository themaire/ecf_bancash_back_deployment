# Deployment and service declaration to the cluster
## Source inspiration : https://github.com/shivalkarrahul/DevOps/blob/master/aws/terraform/terraform-kubernetes-deployment/nodejs-application/
## Majors subsetps :
# 1_ : Create a namespace
# 2_ : Deploy our Docker image
# 3_ : Serve the NestJS app : ecf_bancask_back
# 4_ : Done!! >:-)

resource "kubernetes_deployment" "this" {
  metadata {
    name      = "ecf-bancash-back"
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

          port {
            name           = "http"
            container_port = 3000
            protocol       = "TCP"
          }

          env {
            name = "PGDATABASE"
            value_from {
              secret_key_ref {
                name = "postgres-creds"
                key = "PGDATABASE"
              }
            }
          }
          env {
            name = "PGPASSWORD"
            value_from {
              secret_key_ref {
                name = "postgres-creds"
                key = "PGPASSWORD"
              }
            }
          }
          env {
            name = "PGUSER"
            value_from {
              secret_key_ref {
                name = "postgres-creds"
                key = "PGUSER"
              }
            }
          }
        }
  	  }
    }
  }
}

resource "kubernetes_service" "this" {
  metadata {
    name      = "ecf-bancash-back"
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
