# K3s Lab Terraform Configuration
# Copy this file to terraform.tfvars and modify as needed

# VM Configuration
vm_count = 2
vm_memory = 4096
vm_cpus = 2
vm_disk_size = 20

# Base image path (adjust to your system)
base_image_path = "/var/lib/libvirt/images/ubuntu-22.04-server-cloudimg-amd64.img"

# Network configuration
network_name = "default"

# K3s version
k3s_version = "v1.28.5+k3s1"

# Offline mode settings
offline_registry = true
registry_port = 5000

# Monitoring and backup
enable_monitoring = true
enable_backup = false

