#secure
variable "arm_client_id" {}
variable "arm_client_secret" {}
variable "arm_subscription_id" {}
variable "arm_tenant_id" {}

variable "backend_region" {
  type        = string
}

variable "resource_region" {
  type        = string
}

variable "RG" {
  type        = string
}

variable "backend_container" {
  type        = string
}

variable "backend_key" {
  type        = string
}

variable "company" {
  type        = string
}

locals {
  # Common tags to be assigned to all resources
  common_tags = {
    terraform   = "true"
    deployed_by = "Terraform_SP"
  }
}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.9.0"
    }
    curl = {
      source = "anschoewe/curl"
      version = "1.0.2"
    }
  }
  
  backend "azurerm" {
    }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "RG" {
  name     = var.RG
  location = var.resource_region

  tags = local.common_tags
}

module "vnet" {
  source              = "Azure/vnet/azurerm"
  resource_group_name = var.RG
  address_space       = ["10.0.0.0/16"]
  subnet_prefixes     = ["10.0.1.0/24", "10.0.2.0/24"]
  subnet_names        = ["prod", "AzureBastionSubnet"]

  nsg_ids = {
    prod = azurerm_network_security_group.PROD.id
    AzureBastionSubnet = azurerm_network_security_group.bastion.id
  }

  tags = local.common_tags
  depends_on = [azurerm_resource_group.RG]
}


resource "azurerm_network_security_group" "PROD" {
  name                = "PROD"
  location            = var.resource_region
  resource_group_name = var.RG

  security_rule {
    name                       = "HTTP_80_in_allow"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "SSH_22_in_bastion_allow"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "10.0.2.0/24"
    destination_address_prefix = "10.0.1.0/24"
  }

  security_rule {
    name                       = "AllowAzureLoadBalancerInBound-TCP80"
    priority                   = 4093
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "VirtualNetwork"
  }

    security_rule {
    name                       = "BlockAzureLoadBalancerInBound"
    priority                   = 4094
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "BlockVirtualNetwork"
    priority                   = 4095
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

    security_rule {
    name                       = "DenyAllOutBound"
    priority                   = 4096
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = local.common_tags
  depends_on = [azurerm_resource_group.RG]
}

# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#   NSG / Security rules for Azure Bastion Host to Inbound & Outbound traffic
# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
resource "azurerm_network_security_group" "bastion" {
  name                = "bastion"
  location            = var.resource_region
  resource_group_name = var.RG
  
  # * * * * * * IN-BOUND Traffic * * * * * * #

  security_rule {
    # Ingress traffic from Internet on 443 is enabled
    name                       = "AllowIB_HTTPS443_Internet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
  security_rule {
    # Ingress traffic for control plane activity that is GatewayManger to be able to talk to Azure Bastion
    name                       = "AllowIB_TCP443_GatewayManager"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "*"
  }

  security_rule {
    # Ingress traffic for health probes, enabled AzureLB to detect connectivity
    name                       = "AllowIB_TCP443_AzureLoadBalancer"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }
  security_rule {
    # Ingress traffic for data plane activity that is VirtualNetwork service tag
    name                       = "AllowIB_BastionHost_Commn8080"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["8080", "5701"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    # Deny all other Ingress traffic 
    name                       = "DenyIB_any_other_traffic"
    priority                   = 900
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # * * * * * * OUT-BOUND Traffic * * * * * * #
  
  # Egress traffic to the target VM subnets over ports 3389 and 22
  security_rule {
    name                       = "AllowOB_SSHRDP_VirtualNetwork"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["3389", "22"]
    source_address_prefix      = "*"
    destination_address_prefix = "VirtualNetwork"
  }
  # Egress traffic to AzureCloud over 443
  security_rule {
    name                       = "AllowOB_AzureCloud"
    priority                   = 105
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "AzureCloud"
  }
  # Egress traffic for data plane communication between the Bastion and VNets service tags
  security_rule {
    name                       = "AllowOB_BastionHost_Comn"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["8080", "5701"]
    source_address_prefix      = "*"
    destination_address_prefix = "VirtualNetwork"
  }

  # Egress traffic for SessionInformation
  security_rule {
    name                       = "AllowOB_GetSessionInformation"
    priority                   = 120
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }

  tags = local.common_tags
  depends_on = [azurerm_resource_group.RG]
}

resource azurerm_public_ip "public-IP-nginx" {
  name                  = "public-IP-nginx"
  location              = var.resource_region
  resource_group_name   = var.RG
  allocation_method      = "Dynamic"

  tags = local.common_tags
  depends_on = [azurerm_resource_group.RG]
}


resource "azurerm_network_interface" "nginx-net" {
  name = "nginx-net"
  location              = var.resource_region
  resource_group_name   = var.RG

  ip_configuration {
    name                           = "nginx-ipconfig"
    subnet_id                      = module.vnet.vnet_subnets.0
    private_ip_address_allocation  = "Dynamic"
    public_ip_address_id           = azurerm_public_ip.public-IP-nginx.id
  }
  
  tags = local.common_tags
}


resource "azurerm_network_interface_security_group_association" "nginx-nic-PROD" {
  network_interface_id      = azurerm_network_interface.nginx-net.id
  network_security_group_id = azurerm_network_security_group.PROD.id
}

resource "azurerm_resource_group" "nwwatcher-RG" {
  name     = "NetworkWatcherRG"
  location = var.resource_region

  tags = local.common_tags
}

resource "azurerm_network_watcher" "nwwatcher" {
  name                = "NetworkWatcher_${var.resource_region}"
  location            = azurerm_resource_group.nwwatcher-RG.location
  resource_group_name = azurerm_resource_group.nwwatcher-RG.name

  tags = local.common_tags
  depends_on = [azurerm_resource_group.nwwatcher-RG]
}

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_linux_virtual_machine" "nginx" {
  name                            = "nginx-bitnami-vm"
  location                        = var.resource_region
  resource_group_name             = var.RG
  size                            = "Standard_D2d_v4"
  disable_password_authentication = true
  admin_username                  = "adminuser"
  network_interface_ids           = [azurerm_network_interface.nginx-net.id]

  admin_ssh_key {
    username   = "adminuser"
    public_key = tls_private_key.ssh_key.public_key_openssh
  }

  source_image_reference {
    publisher = "bitnami"
    offer     = "nginxstack"
    sku       = "1-9"
    version   = "latest"
  }

  plan {
    name = "1-9"
    publisher = "bitnami"
    product = "nginxstack"
  }
 
  os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  
  tags = local.common_tags
}

output "public_IP_of_the_nginx_VM" {
  value       = "${azurerm_linux_virtual_machine.nginx.public_ip_address}"
}

output "nginx-vm_private_key" {
  value     = tls_private_key.ssh_key.private_key_pem
  sensitive = true
}

# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
#   Bastion related TF resources
# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

resource "azurerm_public_ip" "bastion-ip" {
  name                = "bastion-ip"
  location            = var.resource_region
  resource_group_name = var.RG
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = local.common_tags
  depends_on = [azurerm_resource_group.RG]
}

resource "azurerm_bastion_host" "bastion-host" {
  name                = "bastion-host"
  location            = var.resource_region
  resource_group_name = var.RG
  sku                 = "Basic"

  ip_configuration {
    name                 = "bastion-configuration"
    subnet_id            = module.vnet.vnet_subnets.1
    public_ip_address_id = azurerm_public_ip.bastion-ip.id
  }

  tags = local.common_tags
}
