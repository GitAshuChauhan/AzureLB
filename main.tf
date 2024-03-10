# Generate random password
resource "random_password" "linux-vm-password" {
  length           = 16
  min_upper        = 2
  min_lower        = 2
  min_special      = 2
  numeric          = true
  special          = true
  override_special = "!@#$%&"
}

# Generate a random vm name
resource "random_string" "linux-vm-name" {
  length  = 8
  upper   = false
  numeric = false
  lower   = true
  special = false
}

resource "random_string" "my_resource_group" {
  length  = 8
  upper   = false
  special = false
}

# Template for bootstrapping
data "template_file" "linux-vm-cloud-init" {
  template = file("install-nginx.sh")
}

# Create Resource Group
resource "azurerm_resource_group" "qa-ecs-eastus2-rg" {
  name     = "${var.resource_group_name}-${random_string.my_resource_group.result}"
  location = var.resource_group_location
}

# Create Virtual Network
resource "azurerm_virtual_network" "my_virtual_network" {
  name                = var.virtual_network_name
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.qa-ecs-eastus2-rg.location
  resource_group_name = azurerm_resource_group.qa-ecs-eastus2-rg.name
}

# Create a subnet in the Virtual Network
resource "azurerm_subnet" "qa-ecs-eastus2-nginx-subnet" {
  name                 = var.subnet_name
  resource_group_name  = azurerm_resource_group.qa-ecs-eastus2-rg.name
  virtual_network_name = azurerm_virtual_network.my_virtual_network.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create Network Security Group and rules
resource "azurerm_network_security_group" "qa-ecs-eastus2-nsg" {
  name                = var.network_security_group_name
  location            = azurerm_resource_group.qa-ecs-eastus2-rg.location
  resource_group_name = azurerm_resource_group.qa-ecs-eastus2-rg.name

  security_rule {
    name                       = "ssh"
    priority                   = 1022
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "http"
    priority                   = 1080
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*" #"10.0.1.0/24"
  }

  security_rule {
    name                       = "https"
    priority                   = 1043
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*" #"10.0.1.0/24"
  }
}

# Associate the Network Security Group to the subnet
resource "azurerm_subnet_network_security_group_association" "qa-ecs-eastus2-nsg-assoc" {
  subnet_id                 = azurerm_subnet.qa-ecs-eastus2-nginx-subnet.id
  network_security_group_id = azurerm_network_security_group.qa-ecs-eastus2-nsg.id
}

# Create Network Interfaces
resource "azurerm_network_interface" "qaecseastus2vmnic" {
  count               = 2
  name                = "${var.network_interface_name}-${count.index}"
  location            = azurerm_resource_group.qa-ecs-eastus2-rg.location
  resource_group_name = azurerm_resource_group.qa-ecs-eastus2-rg.name

  ip_configuration {
    name                          = "qaecseastus2ipconfig-${count.index}"
    subnet_id                     = azurerm_subnet.qa-ecs-eastus2-nginx-subnet.id
    private_ip_address_allocation = "Dynamic"
    primary                       = true
  }
}

# Associate Network Interface to the Backend Pool of the Load Balancer
resource "azurerm_network_interface_backend_address_pool_association" "qa-ecs-eastus2-business-tier-pool" {
  count                   = 2
  network_interface_id    = azurerm_network_interface.qaecseastus2vmnic[count.index].id
  ip_configuration_name   = "qaecseastus2ipconfig-${count.index}"
  backend_address_pool_id = azurerm_lb_backend_address_pool.qa-ecs-eastus2-business-backend-pool.id
  depends_on              = [azurerm_linux_virtual_machine.qa-ecs-eastus2-nginx-linux-vm, azurerm_virtual_machine_extension.qa-ecs-eastus2-nginx-linux-vm_extension, azurerm_availability_set.qa-ecs-eastus2-vmavset]
}

#Availability Set - Fault Domains [Rack Resilience]
resource "azurerm_availability_set" "qa-ecs-eastus2-vmavset" {
  name                         = var.qa-ecs-eastus2vmavset
  location                     = azurerm_resource_group.qa-ecs-eastus2-rg.location
  resource_group_name          = azurerm_resource_group.qa-ecs-eastus2-rg.name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
  tags = {
    environment = var.environment
  }
}

# Create Virtual Machine
resource "azurerm_linux_virtual_machine" "qa-ecs-eastus2-nginx-linux-vm" {
  count                 = 2
  name                  = "${var.virtual_machine_name}-${count.index}"
  location              = azurerm_resource_group.qa-ecs-eastus2-rg.location
  resource_group_name   = azurerm_resource_group.qa-ecs-eastus2-rg.name
  network_interface_ids = [azurerm_network_interface.qaecseastus2vmnic[count.index].id]
  size                  = var.virtual_machine_size
  availability_set_id   = azurerm_availability_set.qa-ecs-eastus2-vmavset.id

  os_disk {
    name                 = "${var.disk_name}-${count.index}"
    caching              = "ReadWrite"
    storage_account_type = var.redundancy_type
  }

  source_image_reference {
    offer     = var.linux_vm_image_offer
    publisher = var.linux_vm_image_publisher
    sku       = var.rhel_8_5_sku
    version   = "latest"
  }

  admin_username                  = var.username
  admin_password                  = random_password.linux-vm-password.result
  disable_password_authentication = false

  #Deploy Custom Data on Hosts
  #custom_data = base64encode(data.template_file.linux-vm-cloud-init.rendered)
  #custom_data = filebase64("install-nginx.sh")
  #custom_data = data.template_cloudinit_config.webserverconfig.rendered

  tags = {
    environment = var.environment
  }

}

# Enable virtual machine extension and install Nginx
resource "azurerm_virtual_machine_extension" "qa-ecs-eastus2-nginx-linux-vm_extension" {
  count                = 2
  name                 = "Nginx"
  virtual_machine_id   = azurerm_linux_virtual_machine.qa-ecs-eastus2-nginx-linux-vm[count.index].id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings   = <<SETTINGS
 {
  "commandToExecute": "sudo yum update -y && sudo yum install nginx -y && sudo systemctl enable nginx && sudo systemctl start nginx && sudo firewall-cmd --permanent --add-port={80/tcp,443/tcp} && sudo setsebool -P httpd_can_network_connect 1 && sudo firewall-cmd --reload"
 }
SETTINGS
  depends_on = [azurerm_managed_disk.qa_ecs_easus2_disk, azurerm_virtual_machine_data_disk_attachment.qa_ecs_easus2_diskattachment]
}

#Create managed disk
resource "azurerm_managed_disk" "qa_ecs_easus2_disk" {
  count                = 2
  name                 = "qa_eastus2_datadisk_existing_${count.index}"
  location             = azurerm_resource_group.qa-ecs-eastus2-rg.location
  resource_group_name  = azurerm_resource_group.qa-ecs-eastus2-rg.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "1024"
}

#Attach managed disk to vm
resource "azurerm_virtual_machine_data_disk_attachment" "qa_ecs_easus2_diskattachment" {
  count              = 2
  managed_disk_id    = azurerm_managed_disk.qa_ecs_easus2_disk[count.index].id
  virtual_machine_id = azurerm_linux_virtual_machine.qa-ecs-eastus2-nginx-linux-vm[count.index].id
  lun                = "10"
  caching            = "ReadWrite"
}

# Create an Internal Load Balancer
resource "azurerm_lb" "qa-ecs-eastus2-nginx-internal-lb" {
  name                = var.load_balancer_name
  location            = azurerm_resource_group.qa-ecs-eastus2-rg.location
  resource_group_name = azurerm_resource_group.qa-ecs-eastus2-rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = var.load_balancer_fip_config_name
    subnet_id                     = azurerm_subnet.qa-ecs-eastus2-nginx-subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

#create load balancer backend address pool
resource "azurerm_lb_backend_address_pool" "qa-ecs-eastus2-business-backend-pool" {
  loadbalancer_id = azurerm_lb.qa-ecs-eastus2-nginx-internal-lb.id
  name            = var.ecs_qa_lb_addresspool_name
}

#create load balancer health probe
resource "azurerm_lb_probe" "qa-ecs-eastus2-ssh-inbound-probe" {
  loadbalancer_id = azurerm_lb.qa-ecs-eastus2-nginx-internal-lb.id
  name            = var.ecs_qa_lb_probe
  port            = 80
}

#create load baalncer rules.
resource "azurerm_lb_rule" "qa-ecs-eastus2-inbound-rules" {
  loadbalancer_id                = azurerm_lb.qa-ecs-eastus2-nginx-internal-lb.id
  name                           = var.qa_ecs_estus2_load_balancer_rule_name
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  disable_outbound_snat          = false
  frontend_ip_configuration_name = var.load_balancer_fip_config_name
  probe_id                       = azurerm_lb_probe.qa-ecs-eastus2-ssh-inbound-probe.id
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.qa-ecs-eastus2-business-backend-pool.id]
}
