To update cloud-credentials:
```bash
# 1. Update "cred"
# 2. Create secret
kubectl -n velero create secret generic cloud-credentials --from-file=./cloud --dry-run=client -o yaml > secret.yaml

# 3. SealSecretize the secret
kubeseal --controller-name sealed-secrets <secret.yaml -o yaml >sealedsecret_cloud-credentials.yaml
```