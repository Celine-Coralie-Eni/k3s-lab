variable "vm_count" {
  description = "Number of VMs to create (minimum 2: 1 server + 1 worker)"
  type        = number
  default     = 2
  validation {
    condition     = var.vm_count >= 2
    error_message = "VM count must be at least 2 (1 server + 1 worker)."
  }
}

variable "vm_memory" {
  description = "Memory for each VM in MB"
  type        = number
  default     = 4096
  validation {
    condition     = var.vm_memory >= 2048
    error_message = "VM memory must be at least 2048 MB."
  }
}

variable "vm_cpus" {
  description = "Number of CPUs for each VM"
  type        = number
  default     = 2
  validation {
    condition     = var.vm_cpus >= 1
    error_message = "VM CPUs must be at least 1."
  }
}

variable "vm_disk_size" {
  description = "Disk size in GB"
  type        = number
  default     = 20
  validation {
    condition     = var.vm_disk_size >= 10
    error_message = "VM disk size must be at least 10 GB."
  }
}

variable "base_image_path" {
  description = "Path to base Ubuntu cloud image"
  type        = string
  default     = "/var/lib/libvirt/images/ubuntu-22.04-server-cloudimg-amd64.img"
}

variable "network_name" {
  description = "Name of the libvirt network to use"
  type        = string
  default     = "default"
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key for VM access"
  type        = string
  default     = "../ansible/ssh/id_rsa.pub"
}

variable "k3s_version" {
  description = "K3s version to install"
  type        = string
  default     = "v1.28.5+k3s1"
}

variable "k3s_token" {
  description = "K3s cluster token (auto-generated if empty)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "offline_registry" {
  description = "Enable offline registry setup"
  type        = bool
  default     = true
}

variable "registry_port" {
  description = "Port for local registry"
  type        = number
  default     = 5000
}

variable "enable_monitoring" {
  description = "Enable monitoring stack"
  type        = bool
  default     = true
}

variable "enable_backup" {
  description = "Enable backup solutions"
  type        = bool
  default     = false
}


