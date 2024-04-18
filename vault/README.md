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

# Get SA token. Only needed if token_reviewer_jwt is set for auth/kubernetes/config
#token=$(k -n external-secrets get secret external-secrets-sa-token -o json | jq .data.token -r | base64 -d)

# Get CA cert
KB_ENDPOINT="kubernetes.klopfi.net"
k config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.certificate-authority-data}' | base64 -d > ca.crt

vault write auth/kubernetes/config \
    kubernetes_host=https://$KB_ENDPOINT:6443 \
    kubernetes_ca_cert=@ca.crt \
    disable_local_ca_jwt=true
rm ca.crt

vault write auth/kubernetes/role/ghactions \
    bound_service_account_names=sa-github-actions \
    bound_service_account_namespaces=github-actions \
    policies=$POLICY_NAME \
    ttl=1h

vault write auth/kubernetes/role/externalsecrets \
    bound_service_account_names=external-secrets \
    bound_service_account_namespaces=external-secrets \
    policies=$POLICY_NAME \
    ttl=1h
```

### Login test
```bash
token=$(k -n external-secrets get secret external-secrets-sa-token -o json | jq .data.token -r | base64 -d)
curl \
    --request POST \
    --data '{"jwt": "'$token'", "role": "externalsecrets"}' \
    https://vault.apps.klopfi.net/v1/auth/kubernetes/login
```

## Token
```bash
POLICY_NAME=proxmox
token=$(vault token create -policy="$POLICY_NAME" -period=24h -format=json | jq -r ".auth.client_token")

# Create secret of token for external-secrets
kubectl -n external-secrets create secret generic vault-token --from-literal=token="$token" --dry-run=client -o yaml > secret.yaml
kubeseal --controller-name sealed-secrets <secret.yaml -o yaml >sealedsecret_vault-token.yaml
```
