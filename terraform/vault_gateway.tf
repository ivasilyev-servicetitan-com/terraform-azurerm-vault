# ---------------------------------------------------------------------------------------------------------------------
# Resource group
# ---------------------------------------------------------------------------------------------------------------------
resource "azurerm_resource_group" "resource_group" {
  name     = "${var.resource_group_name}"
  location = "${var.resource_group_location}"
}

# ---------------------------------------------------------------------------------------------------------------------
# Vault VNet
# ---------------------------------------------------------------------------------------------------------------------
resource "azurerm_virtual_network" "vault" {
  name                = "${var.vault_vnet_name}"
  location            = "${azurerm_resource_group.resource_group.location}"
  resource_group_name = "${azurerm_resource_group.resource_group.name}"
  address_space       = "${var.rm_vnet_address_space}"
}

resource "azurerm_subnet" "vault" {
  name                 = "Subnet-1"
  resource_group_name  = "${azurerm_resource_group.resource_group.name}"
  virtual_network_name = "${azurerm_virtual_network.vault.name}"
  address_prefix       = "${var.rm_vnet_subnet1_address_space}"
}

resource "azurerm_subnet" "vault_gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = "${azurerm_resource_group.resource_group.name}"
  virtual_network_name = "${azurerm_virtual_network.vault.name}"
  address_prefix       = "${var.rm_vnet_gateway_subnet_address_space}"
}

# ---------------------------------------------------------------------------------------------------------------------
# Vault VNet Gateway
# ---------------------------------------------------------------------------------------------------------------------
resource "azurerm_public_ip" "vault_vnet_gateway" {
  name                = "${var.vault_vnet_gateway_public_ip_name}"
  location            = "${azurerm_resource_group.resource_group.location}"
  resource_group_name = "${azurerm_resource_group.resource_group.name}"

  public_ip_address_allocation = "Dynamic"
}

resource "azurerm_virtual_network_gateway" "vault" {
  name                = "${var.vault_vnet_gateway_name}"
  location            = "${azurerm_resource_group.resource_group.location}"
  resource_group_name = "${azurerm_resource_group.resource_group.name}"

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = false
  enable_bgp    = false
  sku           = "Basic"

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = "${azurerm_public_ip.vault_vnet_gateway.id}"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = "${azurerm_subnet.vault_gateway.id}"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Connection: RM -> Classic
# ---------------------------------------------------------------------------------------------------------------------
resource "azurerm_local_network_gateway" "vault" {
  name                = "${var.vault_local_network_gateway_name}"
  location            = "${azurerm_resource_group.resource_group.location}"
  resource_group_name = "${azurerm_resource_group.resource_group.name}"
  gateway_address     = "${var.classic_vnet_gateway_public_ip}"
  address_space       = "${var.classic_vnet_address_space}"
}

resource "azurerm_virtual_network_gateway_connection" "vault_vnet_to_classic" {
  name                = "RMtoClassic"
  location            = "${azurerm_resource_group.resource_group.location}"
  resource_group_name = "${azurerm_resource_group.resource_group.name}"

  type                       = "IPsec"
  virtual_network_gateway_id = "${azurerm_virtual_network_gateway.vault.id}"
  local_network_gateway_id   = "${azurerm_local_network_gateway.vault.id}"

  shared_key = "${var.rm_vnet_gateway_shared_key}"
}