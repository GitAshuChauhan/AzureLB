output "linux_vm_admin_password" {
  description = "Administrator password for the Virtual Machine"
  value       = random_password.linux-vm-password.result
  sensitive   = true
}
