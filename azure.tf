provider "azurerm" {}
variable "prefix" {
  default = "tf-vm"
}

variable "ssh_key_path" {}

resource "azurerm_resource_group" "allspark_test" {
  name     = "allsparkTestResources"
  location = "West Europe"
}

resource "azurerm_network_security_group" "allspark_test" {
  name                = "allsparkTestSG"
  location            = "${azurerm_resource_group.allspark_test.location}"
  resource_group_name = "${azurerm_resource_group.allspark_test.name}"
}

resource "azurerm_virtual_network" "allspark_test" {
  name                = "allsparkTestNetwork"
  location            = "${azurerm_resource_group.allspark_test.location}"
  resource_group_name = "${azurerm_resource_group.allspark_test.name}"
  address_space       = ["10.0.0.0/16"]
  dns_servers         = ["10.0.0.4", "10.0.0.5"]

  tags {
    environment = "Test"
  }
}

resource "azurerm_subnet" "allspark_test" {
  name                 = "internal"
  resource_group_name  = "${azurerm_resource_group.allspark_test.name}"
  virtual_network_name = "${azurerm_virtual_network.allspark_test.name}"
  # security_group       = "${azurerm_network_security_group.allspark_test.id}"
  address_prefix       = "10.0.1.0/24"
}

resource "azurerm_public_ip" "allspark_test" {
  name                         = "allsparkTestPublicIP"
  location                     = "West Europe"
  resource_group_name          = "${azurerm_resource_group.allspark_test.name}"
  public_ip_address_allocation = "static"

  tags {
    environment = "Test"
  }
}

resource "azurerm_network_interface" "allspark_test" {
  name                = "${var.prefix}-nic"
  location            = "${azurerm_resource_group.allspark_test.location}"
  resource_group_name = "${azurerm_resource_group.allspark_test.name}"

  ip_configuration {
    name                          = "${var.prefix}-ipconf"
    subnet_id                     = "${azurerm_subnet.allspark_test.id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.allspark_test.id}"
  }
}

resource "azurerm_virtual_machine" "main" {
  name                  = "${var.prefix}-host"
  location              = "${azurerm_resource_group.allspark_test.location}"
  resource_group_name   = "${azurerm_resource_group.allspark_test.name}"
  network_interface_ids = ["${azurerm_network_interface.allspark_test.id}"]
  vm_size               = "Standard_DS1_v2"

  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "sda"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "localhost"
    admin_username = "allspark"
  }
  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      key_data = "${file("/tmp/azure-deployer.pem")}"
      path     = "/home/allspark/.ssh/authorized_keys"
    }
  }
  tags {
    environment = "Test"
  }
}
