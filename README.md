# Terraform GCP GKE via Modules

```bash
CURRENT_IP="`curl https://api.ipify.org -s`"

terraform apply \
  -var "remote_access_cidr=${CURRENT_IP}/32" \
  -var "project_id=core-337701" \
  -var "project_name=core-337701"
```
