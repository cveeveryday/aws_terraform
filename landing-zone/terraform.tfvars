# terraform.tfvars

region = "us-east-1"
organization_name = "mycompany"
environment      = "prod"
primary_region   = "us-east-1"
secondary_region = "us-west-2"
cost_center      = "IT-Infrastructure"

applications = {
  web_app = {
    name                = "web-application"
    environments        = ["prod", "dev"]
    vpc_cidr_base       = "10.1.0.0/16"
    enable_multi_region = true
  }
  api_service = {
    name                = "api-service"
    environments        = ["prod", "dev"]
    vpc_cidr_base       = "10.2.0.0/16"
    enable_multi_region = true
  }
}