#insecure
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


terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.9.0"
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

  tags = {
      terraform   = "true"
      deployed_by = "Terraform_SP"
  }
}

module "vnet" {
  source              = "Azure/vnet/azurerm"
  resource_group_name = var.RG
  address_space       = ["10.0.0.0/16"]
  subnet_prefixes     = ["10.0.1.0/24", "10.0.2.0/24"]
  subnet_names        = ["prod", "bastion"]

  nsg_ids = {
    prod = azurerm_network_security_group.TF-NSG.id
    bastion = azurerm_network_security_group.TF-NSG.id
  }


  tags = {
    terraform   = "true"
    deployed_by = "Terraform_SP"
  }

  depends_on = [azurerm_resource_group.RG]
}


resource "azurerm_network_security_group" "TF-NSG" {
  name                = "TF-NSG"
  location            = var.resource_region
  resource_group_name = var.RG

  security_rule {
    name                       = "TCP_80_in_allow"
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
    name                       = "SSH_22_in_allow"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    terraform   = "true"
    deployed_by = "Terraform_SP"
  }

  depends_on = [azurerm_resource_group.RG]
}

resource azurerm_public_ip "public-IP-nginx" {
  name                  = "public-IP-nginx"
  location              = var.resource_region
  resource_group_name   = var.RG
  allocation_method      = "Dynamic"

  tags = {
    terraform   = "true"
    deployed_by = "Terraform_SP"
  }

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
  
  tags = {
    terraform   = "true"
    deployed_by = "Terraform_SP"
  }

  depends_on = [module.vnet]
}

resource "azurerm_network_interface_security_group_association" "nginx-nic-nsg" {
  network_interface_id      = azurerm_network_interface.nginx-net.id
  network_security_group_id = azurerm_network_security_group.TF-NSG.id
}

resource "azurerm_resource_group" "nwwatcher-RG" {
  name     = "NetworkWatcherRG"
  location = var.resource_region

  tags = {
    terraform   = "true"
    deployed_by = "Terraform_SP"
  }
}

resource "azurerm_network_watcher" "nwwatcher" {
  name                = "nwwatcher"
  location            = azurerm_resource_group.nwwatcher-RG.location
  resource_group_name = azurerm_resource_group.nwwatcher-RG.name

  tags = {
    terraform   = "true"
    deployed_by = "Terraform_SP"
  }

  depends_on = [azurerm_resource_group.nwwatcher-RG]
}

resource "azurerm_linux_virtual_machine" "nginx" {
  name                            = "nginx-bitnami-vm"
  location                        = var.resource_region
  resource_group_name             = var.RG
  size                            = "Standard_D2d_v4"
  disable_password_authentication = false
  admin_username                  = "adminuser"
  admin_password                  = "SuperEaseyP4ssword1234!_"
  network_interface_ids           = [azurerm_network_interface.nginx-net.id]

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
  
  
  tags = {
    terraform   = "true"
    deployed_by = "Terraform_SP"
  }
}

output "public_IP_of_the_nginx_VM" {
  value       = "${azurerm_linux_virtual_machine.nginx.public_ip_address}"
}