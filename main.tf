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

# Configure providers with dummy settings and skip validation to avoid auth errors.
provider "aws" {
  region                      = "us-west-2"
  access_key                  = "mock"
  secret_key                  = "mock"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
}

provider "azurerm" {
  features {}
  skip_provider_registration = true
  use_cli                    = true # Explicitly disable CLI auth attempt
}

# This resource will FAIL the S3 encryption policy.
resource "aws_s3_bucket" "bad_bucket" {
  bucket = "my-bad-bucket-for-policy-testing-54321" # Must be globally unique
}

# This resource will FAIL the instance type policy.
resource "aws_instance" "bad_instance" {
  ami           = "ami-0c55b159cbfafe1f0" # A common us-west-2 Amazon Linux 2 AMI
  instance_type = "t2.micro"

  tags = {
    Name = "Policy-Test-Instance"
  }
}

# This resource will FAIL the Azure VM size policy.
resource "azurerm_network_interface" "bad_nic" {
  name                = "bad-nic"
  location            = "West US 2"
  resource_group_name = "fake-rg"

  ip_configuration {
    name                          = "internal"
    subnet_id                     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/fake-rg/providers/Microsoft.Network/virtualNetworks/fake-vnet/subnets/fake-subnet"
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "bad_vm" {
  name                  = "bad-vm"
  resource_group_name   = "fake-rg"
  location              = "West US 2"
  size                  = "Standard_DS1_v2" # This will fail the policy
  admin_username        = "adminuser"
  network_interface_ids = [azurerm_network_interface.bad_nic.id]

  admin_password                  = "P@ssw0rd1234!"
  disable_password_authentication = false

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
