#cloud-config
hostname: ${hostname}
manage_etc_hosts: true

users:
  - name: ubuntu
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - ${ssh_key}
    groups: [adm, dialout, cdrom, floppy, sudo, audio, dip, video, plugdev, netdev, lxd]

# Update system packages
package_update: true
package_upgrade: true

# Install essential packages
packages:
  - curl
  - wget
  - git
  - vim
  - htop
  - net-tools
  - dnsutils
  - nfs-common
  - apt-transport-https
  - ca-certificates
  - gnupg
  - lsb-release
  - software-properties-common
  - unzip
  - jq

# Configure timezone
timezone: UTC

# Configure SSH
ssh_pwauth: false
disable_root: true

# Write files
write_files:
  - path: /etc/hosts
    content: |
      127.0.0.1 localhost
      127.0.1.1 ${hostname}
      
      # K3s cluster nodes
      192.168.122.10 k3s-server
      192.168.122.11 k3s-worker-1
      
      # Local registry
      192.168.122.100 registry.local
      
      # Offline services
      192.168.122.101 keycloak.local
      192.168.122.102 gitea.local
      192.168.122.103 postgres.local

# Run commands after cloud-init
runcmd:
  # Update package lists
  - apt-get update
  
  # Install Docker
  - curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  - echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
  - apt-get update
  - apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
  
  # Add ubuntu user to docker group
  - usermod -aG docker ubuntu
  
  # Enable and start Docker
  - systemctl enable docker
  - systemctl start docker
  
  # Configure Docker daemon for offline registry
  - mkdir -p /etc/docker
  - echo '{"insecure-registries": ["registry.local:5000", "192.168.122.100:5000"]}' > /etc/docker/daemon.json
  - systemctl restart docker
  
  # Install containerd (required for K3s)
  - apt-get install -y containerd
  - mkdir -p /etc/containerd
  - containerd config default | tee /etc/containerd/config.toml
  - sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
  - systemctl enable containerd
  - systemctl restart containerd
  
  # Configure system limits for K3s
  - echo 'vm.max_map_count=262144' >> /etc/sysctl.conf
  - echo 'fs.inotify.max_user_watches=524288' >> /etc/sysctl.conf
  - echo 'fs.inotify.max_user_instances=512' >> /etc/sysctl.conf
  
  # Create directories for K3s
  - mkdir -p /var/lib/rancher/k3s
  - mkdir -p /etc/rancher/k3s
  
  # Set proper permissions
  - chown -R ubuntu:ubuntu /var/lib/rancher
  - chown -R ubuntu:ubuntu /etc/rancher
  
  # Final system update
  - apt-get update && apt-get upgrade -y
  
  # Reboot to apply all changes
  - reboot

final_message: "K3s VM ${hostname} setup completed. Rebooting in 10 seconds..."


