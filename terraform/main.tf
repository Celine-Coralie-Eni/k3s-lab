terraform {
  required_version = ">= 1.0"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.7"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

# Variables
variable "vm_count" {
  description = "Number of VMs to create"
  type        = number
  default     = 2
}

variable "vm_memory" {
  description = "Memory for each VM in MB"
  type        = number
  default     = 4096
}

variable "vm_cpus" {
  description = "Number of CPUs for each VM"
  type        = number
  default     = 2
}

variable "vm_disk_size" {
  description = "Disk size in GB"
  type        = number
  default     = 20
}

variable "base_image_path" {
  description = "Path to base Ubuntu cloud image"
  type        = string
  default     = "/var/lib/libvirt/images/ubuntu-22.04-server-cloudimg-amd64.img"
}

# Base volume for VMs
resource "libvirt_volume" "base_volume" {
  name   = "ubuntu-22.04-base"
  source = var.base_image_path
  format = "qcow2"
}

# Cloud-init configuration for each VM
resource "libvirt_cloudinit_disk" "cloudinit" {
  count = var.vm_count
  
  name = "cloudinit-${count.index + 1}.iso"
  
  user_data = templatefile("${path.module}/cloud-init.tpl", {
    hostname = "k3s-${count.index == 0 ? "server" : "worker-${count.index}"}"
    ssh_key  = file("${path.module}/../ansible/ssh/id_rsa.pub")
    index    = count.index
  })
}

# VM instances
resource "libvirt_domain" "k3s_vm" {
  count  = var.vm_count
  name   = "k3s-${count.index == 0 ? "server" : "worker-${count.index}"}"
  memory = var.vm_memory
  vcpu   = var.vm_cpus

  cloudinit = libvirt_cloudinit_disk.cloudinit[count.index].id

  network_interface {
    network_name = "default"
    wait_for_lease = true
  }

  disk {
    volume_id = libvirt_volume.base_volume.id
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}

# Output the IP addresses
output "vm_ips" {
  description = "IP addresses of created VMs"
  value = {
    for i, vm in libvirt_domain.k3s_vm : vm.name => vm.network_interface[0].addresses[0]
  }
}

output "k3s_server_ip" {
  description = "IP address of K3s server"
  value = libvirt_domain.k3s_vm[0].network_interface[0].addresses[0]
}

output "k3s_worker_ips" {
  description = "IP addresses of K3s workers"
  value = [for i in range(1, var.vm_count) : libvirt_domain.k3s_vm[i].network_interface[0].addresses[0]]
}


