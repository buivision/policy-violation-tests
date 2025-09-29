terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# Configure providers with dummy regions/settings for planning
provider "aws" {
  region = "us-west-2"
}

provider "azurerm" {
  features {}
}

# This resource will FAIL the S3 encryption policy.
# It is missing the server_side_encryption_configuration block.
resource "aws_s3_bucket" "bad_bucket" {
  bucket = "my-bad-bucket-for-policy-testing-12345" # Must be globally unique
}

# This resource will FAIL the instance type policy.
# Its instance_type is "t2.micro", not "t3.*".
resource "aws_instance" "bad_instance" {
  ami           = "ami-0c55b159cbfafe1f0" # A common us-west-2 Amazon Linux 2 AMI
  instance_type = "t2.micro"

  tags = {
    Name = "Policy-Test-Instance"
  }
}

# This resource will FAIL the Azure VM size policy.
# Its vm_size is "Standard_DS1_v2", not "Standard_B*".
# NOTE: To plan this, you need a resource group. We'll just reference a fake one.
data "azurerm_resource_group" "fake" {
  name = "fake-rg"
}

resource "azurerm_network_interface" "bad_nic" {
  name                = "bad-nic"
  location            = data.azurerm_resource_group.fake.location
  resource_group_name = data.azurerm_resource_group.fake.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/fake-rg/providers/Microsoft.Network/virtualNetworks/fake-vnet/subnets/fake-subnet"
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "bad_vm" {
  name                  = "bad-vm"
  resource_group_name   = data.azurerm_resource_group.fake.name
  location              = data.azurerm_resource_group.fake.location
  size                  = "Standard_DS1_v2" # This will fail the policy
  admin_username        = "adminuser"
  network_interface_ids = [azurerm_network_interface.bad_nic.id]

  admin_ssh_key {
    username   = "adminuser"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQD..."
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}
