terraform {
  backend "remote" {
    organization = "leonildo-devops" # Substitua pelo nome da sua organização no Terraform Cloud

    workspaces {
      name = "saudacoes-terraform" # Substitua pelo nome do seu workspace
    }
  }

  required_providers {
    koyeb = {
      source = "koyeb/koyeb"
    }
  }
}

provider "koyeb" {
  # Use a variável de ambiente KOYEB_TOKEN para autenticação
}

resource "koyeb_app" "my-app" {
  name = var.app_name
}

resource "koyeb_service" "my-service" {
  app_name = var.app_name
  definition {
    name = var.service_name
    instance_types {
      type = "free"
    }
    ports {
      port     = var.container_port
      protocol = "http"
    }
    scalings {
      min = 0
      max = 1
    }
    routes {
      path = "/"
      port = var.container_port
    }
    health_checks {
      http {
        port = var.container_port
        path = "/api/saudacoes/aleatorio"
      }
    }
    regions = ["was"]
    docker {
      image = "${var.docker_image_name}:${var.docker_image_tag}"
    }
  }

  depends_on = [
    koyeb_app.my-app
  ]
}
