output "k3s_cluster_info" {
  description = "K3s cluster information"
  value = {
    server_ip = libvirt_domain.k3s_vm[0].network_interface[0].addresses[0]
    worker_ips = [for i in range(1, var.vm_count) : libvirt_domain.k3s_vm[i].network_interface[0].addresses[0]]
    total_nodes = var.vm_count
    k3s_version = var.k3s_version
  }
}

output "vm_details" {
  description = "Detailed information about all VMs"
  value = {
    for i, vm in libvirt_domain.k3s_vm : vm.name => {
      ip_address = vm.network_interface[0].addresses[0]
      memory_mb = vm.memory
      vcpus = vm.vcpu
      role = i == 0 ? "server" : "worker-${i}"
    }
  }
}

output "connection_info" {
  description = "SSH connection information"
  value = {
    server_ssh = "ssh ubuntu@${libvirt_domain.k3s_vm[0].network_interface[0].addresses[0]}"
    worker_ssh = [for i in range(1, var.vm_count) : "ssh ubuntu@${libvirt_domain.k3s_vm[i].network_interface[0].addresses[0]}"]
  }
}

output "k3s_access_info" {
  description = "K3s access information"
  value = {
    server_url = "https://${libvirt_domain.k3s_vm[0].network_interface[0].addresses[0]}:6443"
    kubeconfig_path = "/etc/rancher/k3s/k3s.yaml"
    token_path = "/var/lib/rancher/k3s/server/node-token"
  }
}

output "registry_info" {
  description = "Local registry information"
  value = var.offline_registry ? {
    registry_url = "registry.local:${var.registry_port}"
    registry_ip = "192.168.122.100:${var.registry_port}"
    insecure_registry = true
  } : null
}

output "next_steps" {
  description = "Next steps after infrastructure deployment"
  value = [
    "1. Wait for VMs to finish cloud-init (check with: virsh list --all)",
    "2. Verify SSH access to all VMs",
    "3. Run Ansible playbooks to configure K3s",
    "4. Deploy core services (PostgreSQL, Keycloak, Gitea)",
    "5. Set up local registry and pre-pull images",
    "6. Deploy your Rust application"
  ]
}


