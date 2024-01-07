```bash
CURRENT_IP="$(curl https://api.ipify.org -s)"

terraform apply -var "remote_access_cidr=${CURRENT_IP}/32"
```
