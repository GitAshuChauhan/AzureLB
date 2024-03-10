variable "resource_group_location" {
  type        = string
  default     = "eastus"
  description = "Location of the resource group."
}

variable "resource_group_name" {
  type        = string
  default     = "non-prod-ecspro-qa-eastus2-vnet-rg"
  description = "Name of the resource group."
}

variable "username" {
  type        = string
  default     = "microsoft"
  description = "The username for the local account that will be created on the new VM."
}

variable "password" {
  type        = string
  default     = "Microsoft@123"
  description = "The passoword for the local account that will be created on the new VM."
}

variable "virtual_network_name" {
  type        = string
  default     = "test-vnet"
  description = "Name of the Virtual Network."
}

variable "subnet_name" {
  type        = string
  default     = "test-subnet"
  description = "Name of the subnet."
}

# variable "public_ip_name" {
#   type        = string
#   default     = "test-public-ip"
#   description = "Name of the Public IP for the NAT Gateway."
# }

# variable "nat_gateway" {
#   type        = string
#   default     = "test-nat"
#   description = "Name of the NAT gateway."
# }

# variable "bastion_name" {
#   type        = string
#   default     = "test-bastion"
#   description = "Name of the Bastion."
# }

variable "network_security_group_name" {
  type        = string
  default     = "qa-ecs-eastus2-nsg"
  description = "Name of the Network Security Group."
}

variable "network_interface_name" {
  type        = string
  default     = "qaecseastus2vmnic"
  description = "Name of the Network Interface."
}

variable "virtual_machine_name" {
  type        = string
  default     = "qa-ecs-eastus2-nginx-vm"
  description = "Name of the Virtual Machine."
}

variable "virtual_machine_size" {
  type        = string
  default     = "Standard_B2s"
  description = "Size or SKU of the Virtual Machine."
}

variable "disk_name" {
  type        = string
  default     = "test-disk"
  description = "Name of the OS disk of the Virtual Machine."
}

variable "redundancy_type" {
  type        = string
  default     = "Standard_LRS"
  description = "Storage redundancy type of the OS disk."
}

variable "load_balancer_name" {
  type        = string
  default     = "qa-ecs-eastus2-nginx-internal-lb"
  description = "Name of the Load Balancer."
}

variable "qa_ecs_estus2_load_balancer_rule_name" {
  type        = string
  default     = "qa-ecs-eastus2-ssh-inbound-rule"
  description = "load balancer rule name"
}

variable "ecs_qa_lb_probe" {
  default     = "qa-ecs-eastus2-ssh-inbound-probe"
  description = "internal load balancer inbbound probe."
}

variable "ecs_qa_lb_addresspool_name" {
  default     = "qa-ecs-eastus2-backend-pool"
  description = "internal load balancer backend pool name."
}

variable "load_balancer_fip_config_name" {
  type        = string
  default     = "ecsproqaeastus2ilbfip"
  description = "Name of the load balancer front ip configuration."
}

variable "environment" {
  type        = string
  default     = "qa-ecs-eastus2"
  description = "Name of enviornment"
}

variable "qa-ecs-eastus2vmavset" {
  type    = string
  default = "qa-ecs-eastus2-vnavset"
}
