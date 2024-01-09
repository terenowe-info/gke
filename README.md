## Setup

### Infrastructure

```bash
CURRENT_IP="$(curl https://api.ipify.org -s)"

terraform apply -var "remote_access_cidr=${CURRENT_IP}/32"
```

### Openvpn AS

#### Configuration

- Configuration
    - TLS Settings
        - TLS options for VPN Server: `1.3`
        - TLS options for Web Server: `1.3`
    - Network Settings
        - VPN Server
            - Hostname or IP Address: `External IP`
            - Protocol: `1194/UDP`
        - Admin Web Server:
            - Port number: `443/TCP`

#### Connection

```bash
sudo openvpn \
  --config /home/user/client.ovpn \
  --auth-user-pass /home/user/pass.txt
```
