# Vault

## Policy
```bash
POLICY_FILE=pol.hcl

# -----------
POLICY_NAME=proxmox
cat <<EOF >$POLICY_FILE
path "secret/proxmox/*" {
  capabilities = [ "create", "read", "update" ]
}
EOF

vault policy write $POLICY_NAME $POLICY_FILE
# -----------
POLICY_NAME=kubernetes
cat <<EOF >>$POLICY_FILE
path "secret/*" {
  capabilities = [ "create", "read", "update" ]
}
EOF

vault policy write $POLICY_NAME $POLICY_FILE
# -----------

rm $POLICY_FILE
```

## Auth
```bash
POLICY_NAME=kubernetes
vault auth enable kubernetes

# Get SA token
token=$(k -n external-secrets get secret external-secrets-sa-token -o json | jq .data.token -r | base64 -d)

# Get CA cert
KB_ENDPOINT="kubernetes.klopfi.net"
openssl s_client -showcerts -connect $KB_ENDPOINT:6443 </dev/null 2>/dev/null | openssl x509 -outform PEM > ca.crt

vault write auth/kubernetes/config \
    token_reviewer_jwt="$token" \
    kubernetes_host=https://$KB_ENDPOINT \
    kubernetes_ca_cert=@ca.crt
rm ca.crt

vault write auth/kubernetes/role/externalsecrets \
    bound_service_account_names=external-secrets \
    bound_service_account_namespaces=external-secrets \
    policies=$POLICY_NAME \
    ttl=1h
```

## Token
```bash
POLICY_NAME=proxmox
token=$(vault token create -policy="$POLICY_NAME" -period=24h -format=json | jq -r ".auth.client_token")

# Create secret of token for external-secrets
kubectl -n external-secrets create secret generic vault-token --from-literal=token="$token" --dry-run=client -o yaml > secret.yaml
kubeseal --controller-name sealed-secrets <secret.yaml -o yaml >sealedsecret_vault-token.yaml
```
