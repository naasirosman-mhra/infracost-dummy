terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
  skip_provider_registration = true
}

locals {
  common_tags = {
    Environment = var.environment
    Project     = "infracost-poc"
    Owner       = "platform-team"
  }
}

resource "azurerm_resource_group" "main" {
  name     = "rg-infracost-poc-${var.environment}"
  location = var.location
  tags     = local.common_tags
}
