provider "aws" {
  region = "us-west-2"
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
}