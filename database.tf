resource "azurerm_mssql_server" "main" {
  name                         = "sql-infracost-poc-${var.environment}"
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = "P@ssw0rd-placeholder-1234!"
  tags                         = local.common_tags
}

resource "azurerm_mssql_database" "main" {
  name        = "sqldb-infracost-poc-${var.environment}"
  server_id   = azurerm_mssql_server.main.id
  sku_name    = "S3"
  max_size_gb = 250
  tags        = local.common_tags
}
