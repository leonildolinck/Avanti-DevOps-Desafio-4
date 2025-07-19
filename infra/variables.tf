variable "app_name" {
  type    = string
  default = "api-saudacoes-aleatorias"
}

variable "service_name" {
  type    = string
  default = "saudacoes-aleatorias"
}

variable "instance_type" {
  type    = string
  default = "free"
}

variable "container_port" {
  type    = number
  default = 8080
}

variable "docker_image_name" {
  type    = string
  default = "xxxxxx/api-saudacoes-aleatorias"
}

variable "docker_image_tag" {
  type    = string
  default = "latest"
}
  