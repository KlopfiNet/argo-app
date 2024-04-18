# Vault

## Policy
```bash
POLICY_NAME=proxmox
POLICY_FILE=pol.hcl

cat <<EOF >$POLICY_FILE
path "secret/proxmox/*" {
  capabilities = [ "create", "read", "update" ]
}
EOF

vault policy write $POLICY_NAME $POLICY_FILE
rm $POLICY_FILE
```

## Token
```bash
POLICY_NAME=proxmox
token=$(vault token create -policy="$POLICY_NAME" -period=24h -format=json | jq -r ".auth.client_token")

# Create secret of token for external-secrets
kubectl -n external-secrets create secret generic vault-token --from-literal=token="$token" --dry-run=client -o yaml > secret.yaml
kubeseal --controller-name sealed-secrets <secret.yaml -o yaml >sealedsecret_vault-token.yaml
```
