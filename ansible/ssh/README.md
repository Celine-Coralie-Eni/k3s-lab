# SSH Key Setup for K3s Lab

This directory contains SSH keys for secure access to the K3s cluster VMs.

## Setup Instructions

### 1. Generate SSH Key Pair

If you don't have an SSH key pair, generate one:

```bash
ssh-keygen -t rsa -b 4096 -f id_rsa -N ""
```

### 2. Copy Public Key

Copy your public key to this directory:

```bash
cp ~/.ssh/id_rsa.pub ansible/ssh/
```

### 3. Set Permissions

Ensure proper permissions:

```bash
chmod 600 ansible/ssh/id_rsa
chmod 644 ansible/ssh/id_rsa.pub
```

### 4. Test Connection

After VMs are created, test SSH access:

```bash
ssh -i ansible/ssh/id_rsa ubuntu@<VM_IP>
```

## Security Notes

- Keep your private key secure
- Never commit private keys to version control
- Use different keys for different environments
- Consider using SSH agents for key management

## Troubleshooting

If SSH connection fails:

1. Check VM IP addresses in Terraform output
2. Verify SSH key permissions
3. Check VM cloud-init completion
4. Verify network connectivity


