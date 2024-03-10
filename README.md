# AzureLB
This terraform project will create the Azure internal load balancer with availabily set as lb backend pool.
Dynamic Password has been assigned to the vm at the time of cration. Use the command (terraform output -raw linux_vm_admin_password) to get the auto generated password once the terrafrom script run successfully. here linux_vm_admin_password is the output variable defined in the main-ouput.tf file.
